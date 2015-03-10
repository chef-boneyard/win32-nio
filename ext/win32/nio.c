#include <ruby.h>
#include <windows.h>

static VALUE rb_nio_read(int argc, VALUE* argv, VALUE self){
  OVERLAPPED olap;
  HANDLE h;
  DWORD bytes_read;
  BOOL b;
  LARGE_INTEGER size;
  VALUE v_file, v_length, v_offset, v_options;
  VALUE v_event, v_mode, v_encoding, v_result;
  size_t length;
  int flags, error;
  char* buffer = NULL;

  memset(&olap, 0, sizeof(olap));

  rb_scan_args(argc, argv, "13", &v_file, &v_length, &v_offset, &v_options);

  SafeStringValue(v_file);

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

  if (!NIL_P(v_offset))
    olap.Offset = NUM2INT(v_offset);

  h = CreateFileA(
    RSTRING_PTR(v_file),
    GENERIC_READ,
    FILE_SHARE_READ,
    NULL,
    OPEN_EXISTING,
    flags,
    NULL
  );

  if (h == INVALID_HANDLE_VALUE)
    rb_raise(rb_eSystemCallError, "CreateFile", GetLastError());

  // If no length is specified, read the entire file
  if (NIL_P(v_length)){
    if (!GetFileSizeEx(h, &size)){
      error = GetLastError();
      CloseHandle(h);
      rb_raise(rb_eSystemCallError, "GetFileSizeEx", error);
    }

    length = (size_t)size.QuadPart;
  }
  else{
    length = NUM2INT(v_length);
  }

  buffer = (char*)ruby_xmalloc(length * sizeof(char));

  b = ReadFile(h, buffer, length, &bytes_read, &olap);

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
        rb_raise(rb_eSystemCallError, "GetOverlappedResult", error);
      }
    }
    else{
      ruby_xfree(buffer);
      CloseHandle(h);
      rb_raise(rb_eSystemCallError, "ReadFile", error);
    }
  }

  CloseHandle(h);

  v_result = rb_str_new(buffer, length);

  // Convert CRLF to LF if text mode
  //if (!NIL_P(v_mode) && strstr(RSTRING_PTR(v_mode), "t"))
  //  rb_funcall(v_result, rb_intern("gsub!"), 2, rb_str_new2("\r\n"), rb_gv_get("$/"));

  return v_result;
}

static VALUE rb_nio_readlines(int argc, VALUE* argv, VALUE self){
  HANDLE h;
  SYSTEM_INFO info;
  LARGE_INTEGER file_size;
  size_t length, size, page_num, page_size;
  VALUE v_file, v_sep;

  rb_scan_args(argc, argv, "11", &v_file, &v_sep);

  h = CreateFileA(
    RSTRING_PTR(v_file),
    GENERIC_READ,
    FILE_SHARE_READ,
    NULL,
    OPEN_EXISTING,
    FILE_FLAG_OVERLAPPED | FILE_FLAG_NO_BUFFERING,
    NULL
  );

  if (h == INVALID_HANDLE_VALUE)
    rb_sys_fail("CreateFile");

  GetSystemInfo(&info);

  if (!GetFileSizeEx(h, &file_size)){
    CloseHandle(h);
    rb_sys_fail("GetFileSizeEx");
  }

  length = (size_t)file_size.QuadPart;

  page_size = info.dwPageSize;
  page_num = length / page_size;

  CloseHandle(h);

  return self;
}

void Init_nio(){
  VALUE mWin32 = rb_define_module("Win32");
  VALUE cNio = rb_define_class_under(mWin32, "NIO", rb_cObject);

  rb_define_singleton_method(cNio, "read", rb_nio_read, -1);
  rb_define_singleton_method(cNio, "readlines", rb_nio_readlines, -1);
}
