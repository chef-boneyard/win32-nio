#include <ruby.h>
#include <ruby/encoding.h>
#include <windows.h>
#include <math.h>

// Callback used when a block is provided to read method. It simply calls the block.
void CALLBACK read_complete(DWORD dwErrorCode, DWORD dwBytes, LPOVERLAPPED olap){
  VALUE p = rb_block_proc();
  rb_funcall(p, rb_intern("call"), 0);
}

// Helper function to raise system errors the way I would like
void rb_raise_syserr(const char* msg, int errnum){
  VALUE v_sys = rb_funcall(rb_eSystemCallError, rb_intern("new"), 2, rb_str_new2(msg), INT2FIX(errnum));
  rb_funcall(rb_mKernel, rb_intern("raise"), 1, v_sys);
}

/*
* This method is similar to Ruby's IO.read method except that it uses
* native function calls.
*
* Examples:
*
* # Read everything
* Win32::NIO.read(file)
*
* # Read the first 100 bytes
* Win32::NIO.read(file, 100)
*
* # Read 50 bytes starting at offset 10
* Win32::NIO.read(file, 50, 10)
*
* Note that the + options + that may be passed to this method are limited
* to :encoding, : mode and : event because we're no longer using the open
* function internally.In the case of:mode the only thing that is checked
* for is the presence of the 'b' (binary)mode.
*
* The :event option, if present, must be a Win32::Event object.
*/
static VALUE rb_nio_read(int argc, VALUE* argv, VALUE self){
  OVERLAPPED olap;
  HANDLE h;
  DWORD bytes_read;
  LARGE_INTEGER lsize;
  BOOL b;
  VALUE v_file, v_length, v_offset, v_options;
  VALUE v_event, v_mode, v_encoding, v_result;
  size_t length;
  int flags, error, size;
  wchar_t* file = NULL;
  char* buffer = NULL;

  memset(&olap, 0, sizeof(olap));

  // Paranoid initialization
  v_length = Qnil;
  v_offset = Qnil;
  v_options = Qnil;

  rb_scan_args(argc, argv, "13", &v_file, &v_length, &v_offset, &v_options);

  if (rb_respond_to(v_file, rb_intern("to_path")))
    v_file = rb_funcall(v_file, rb_intern("to_path"), 0, NULL);

  SafeStringValue(v_file);

  if (!NIL_P(v_length)){
    length = NUM2SIZET(v_length);
    if ((int)length < 0)
      rb_raise(rb_eArgError, "negative length %i given", length);
  }

  if (!NIL_P(v_offset))
    olap.Offset = NUM2ULONG(v_offset);

  size = MultiByteToWideChar(CP_UTF8, 0, RSTRING_PTR(v_file), -1, NULL, 0);
  file = (wchar_t*)ruby_xmalloc(MAX_PATH * sizeof(wchar_t));

  if (!MultiByteToWideChar(CP_UTF8, 0, RSTRING_PTR(v_file), -1, file, size)){
    ruby_xfree(file);
    rb_raise(rb_eSystemCallError, "MultibyteToWideChar", GetLastError());
  }

  flags = FILE_FLAG_SEQUENTIAL_SCAN;

  // Possible options are :event, :mode and :encoding
  if (!NIL_P(v_options)){
    Check_Type(v_options, T_HASH);

    v_event = rb_hash_aref(v_options, ID2SYM(rb_intern("event")));
    v_encoding = rb_hash_aref(v_options, ID2SYM(rb_intern("encoding")));
    v_mode = rb_hash_aref(v_options, ID2SYM(rb_intern("mode")));

    if (!NIL_P(v_event)){
      flags |= FILE_FLAG_OVERLAPPED;
      olap.hEvent = (HANDLE)NUM2OFFT(rb_funcall(v_event, rb_intern("handle"), 0, 0));
    }
  }
  else{
    v_event = Qnil;
    v_encoding = Qnil;
    v_mode = Qnil;
  }

  h = CreateFileW(
    file,
    GENERIC_READ,
    FILE_SHARE_READ,
    NULL,
    OPEN_EXISTING,
    flags,
    NULL
  );

  if (h == INVALID_HANDLE_VALUE)
    rb_raise_syserr("CreateFile", GetLastError());

  // Get the file size. We may use this later to limit read length.
  if (!GetFileSizeEx(h, &lsize)){
    error = GetLastError();
    CloseHandle(h);
    rb_raise_syserr("GetFileSizeEx", error);
  }

  // If no length is specified, read the entire file
  if (NIL_P(v_length))
    length = (size_t)lsize.QuadPart;

  // Don't read past the end of the file
  if (olap.Offset + length > (size_t)lsize.QuadPart)
    length = (size_t)lsize.QuadPart - olap.Offset;

  buffer = (char*)ruby_xmalloc(length * sizeof(char));

  // If a block is given then treat it as a callback
  if (rb_block_given_p()){
    flags |= FILE_FLAG_OVERLAPPED;
    b = ReadFileEx(h, buffer, length, &olap, read_complete);
  }
  else{
    b = ReadFile(h, buffer, length, &bytes_read, &olap);
  }

  error = GetLastError();

  // Put in alertable wait state if overlapped IO
  if (flags & FILE_FLAG_OVERLAPPED)
    SleepEx(1, TRUE);

  if (!b){
    if(error == ERROR_IO_PENDING){
      DWORD bytes;
      if (!GetOverlappedResult(h, &olap, &bytes, TRUE)){
        ruby_xfree(buffer);
        CloseHandle(h);
        rb_raise_syserr("GetOverlappedResult", error);
      }
    }
    else{
      ruby_xfree(buffer);
      CloseHandle(h);
      rb_raise_syserr("ReadFile", error);
    }
  }

  CloseHandle(h);

  v_result = rb_str_new(buffer, length);
  ruby_xfree(buffer);

  // Convert CRLF to LF if text mode
  if (!NIL_P(v_mode) && strstr(RSTRING_PTR(v_mode), "t"))
    rb_funcall(v_result, rb_intern("gsub!"), 2, rb_str_new2("\r\n"), rb_gv_get("$/"));

  if (!NIL_P(v_encoding))
    rb_funcall(v_result, rb_intern("encode!"), 1, v_encoding);

  return v_result;
}

/*
 * Reads the entire file specified by portname as individual lines, and
 * returns those lines in an array. Lines are separated by +sep+.
 *
 * Examples:
 *
 *   # Standard call
 *   Win32::NIO.readlines('file.txt') # => ['line 1', 'line 2', 'line 3', 'line 4']
 *
 *   # Paragraph mode
 *   Win32::NIO.readlines('file.txt', '') # => ['line 1\r\nline 2', 'line 3\r\nline 4']
 *
 * Superficially this method acts the same as the Ruby IO.readlines call, except that
 * it does not transform line endings. However, internally this method is using a
 * scattered read to accomplish its goal. In practice this is only relevant in
 * specific situations. Using it outside of those situations is unlikely to provide
 * any practical benefit, and may even result in slower performance.
 *
 * See information on vectored IO for more details.
 */
static VALUE rb_nio_readlines(int argc, VALUE* argv, VALUE self){
  HANDLE h;
  SYSTEM_INFO info;
  LARGE_INTEGER file_size;
  size_t length, page_size;
  double size;
  void* base_address;
  int error, page_num;
  wchar_t* file;
  VALUE v_file, v_sep, v_result;

  rb_scan_args(argc, argv, "11", &v_file, &v_sep);

  SafeStringValue(v_file);

  if (NIL_P(v_sep))
    v_sep = rb_str_new2("\r\n");
  else
    SafeStringValue(v_sep);

  length = MultiByteToWideChar(CP_UTF8, 0, RSTRING_PTR(v_file), -1, NULL, 0);
  file = (wchar_t*)ruby_xmalloc(MAX_PATH * sizeof(wchar_t));

  if (!MultiByteToWideChar(CP_UTF8, 0, RSTRING_PTR(v_file), -1, file, length)){
    ruby_xfree(file);
    rb_raise(rb_eSystemCallError, "MultibyteToWideChar", GetLastError());
  }

  h = CreateFileW(
    file,
    GENERIC_READ,
    FILE_SHARE_READ,
    NULL,
    OPEN_EXISTING,
    FILE_FLAG_OVERLAPPED | FILE_FLAG_NO_BUFFERING,
    NULL
  );

  if (h == INVALID_HANDLE_VALUE)
    rb_raise(rb_eSystemCallError, "CreateFile", GetLastError());

  if (!GetFileSizeEx(h, &file_size)){
    error = GetLastError();
    CloseHandle(h);
    rb_raise_syserr("GetFileSizeEx", error);
  }

  length = (size_t)file_size.QuadPart;

  GetSystemInfo(&info);
  page_size = info.dwPageSize;

  page_num = (int)ceil((double)length / page_size);

  size = page_num * page_size;

  base_address = VirtualAlloc(NULL, (size_t)size, MEM_COMMIT, PAGE_READWRITE);

  if (!base_address){
    error = GetLastError();
    CloseHandle(h);
    rb_raise_syserr("VirtualAlloc", error);
  }
  else{
    int i;
    OVERLAPPED olap;
    BOOL rv;
    FILE_SEGMENT_ELEMENT* fse;

    olap.Offset = 0;
    olap.OffsetHigh = 0;
    olap.hEvent = NULL;

    fse = (FILE_SEGMENT_ELEMENT*)malloc(sizeof(FILE_SEGMENT_ELEMENT) * (page_num + 1));
    memset(fse, 0, sizeof(FILE_SEGMENT_ELEMENT) * (page_num + 1));
    v_result = Qnil;

    for (i = 0; i < page_num; i++)
      fse[i].Alignment = (ULONGLONG)base_address + (page_size * i);

    rv = ReadFileScatter(h, fse, (DWORD)size, NULL, &olap);

    if (!rv){
      error = GetLastError();

      if (error == ERROR_IO_PENDING){
        while (!HasOverlappedIoCompleted(&olap))
          SleepEx(1, TRUE);
      }
      else{
        VirtualFree(base_address, 0, MEM_RELEASE);
        CloseHandle(h);
        rb_raise_syserr("ReadFileScatter", error);
      }
    }

    // Explicitly handle paragraph mode
    if (rb_equal(v_sep, rb_str_new2(""))){
      VALUE v_args[1];
      v_args[0] = rb_str_new2("(\r\n){2,}");
      v_sep = rb_class_new_instance(1, v_args, rb_cRegexp);
      v_result = rb_funcall(rb_str_new2(fse[0].Buffer), rb_intern("split"), 1, v_sep);
      rb_funcall(v_result, rb_intern("delete"), 1, rb_str_new2("\r\n"));
    }
    else{
      v_result = rb_funcall(rb_str_new2(fse[0].Buffer), rb_intern("split"), 1, v_sep);
    }

    VirtualFree(base_address, 0, MEM_RELEASE);
  }

  CloseHandle(h);

  return v_result;
}

void Init_nio(){
  VALUE mWin32 = rb_define_module("Win32");
  VALUE cNio = rb_define_class_under(mWin32, "NIO", rb_cObject);

  rb_define_singleton_method(cNio, "read", rb_nio_read, -1);
  rb_define_singleton_method(cNio, "readlines", rb_nio_readlines, -1);

  rb_define_const(cNio, "VERSION", rb_str_new2("0.2.0"));
}
