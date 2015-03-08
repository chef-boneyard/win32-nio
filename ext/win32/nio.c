#include <ruby.h>
#include <windows.h>

static VALUE rb_nio_read(int argc, VALUE* argv, VALUE self){
  OVERLAPPED olap;
  HANDLE h;
  DWORD bytes_read;
  BOOL b;
  LARGE_INTEGER size;
  VALUE v_file, v_length, v_offset, v_options, v_event;
  size_t length;
  int flags;
  char* buffer = NULL;

  memset(&olap, 0, sizeof(olap));

  rb_scan_args(argc, argv, "13", &v_file, &v_length, &v_offset, &v_options);

  flags = FILE_FLAG_SEQUENTIAL_SCAN;

  if (!NIL_P(v_options)){
    Check_Type(v_options, T_HASH);
    v_event = rb_hash_aref(v_options, ID2SYM(rb_intern("event")));

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
    rb_sys_fail("CreateFile");

  // If no length is specified, read the entire file
  if (NIL_P(v_length)){
    if (!GetFileSizeEx(h, &size)){
      CloseHandle(h);
      rb_sys_fail("GetFileSizeEx");
    }

    length = (size_t)size.QuadPart;
  }
  else{
    length = NUM2INT(v_length);
  }

  buffer = (char*)ruby_xmalloc(length * sizeof(char));

  b = ReadFile(h, buffer, length, &bytes_read, &olap);

  if (!b){
    if(GetLastError() == ERROR_IO_PENDING){
      DWORD bytes;
      SleepEx(1, TRUE); // Put in alertable wait state
      if (!GetOverlappedResult(h, &olap, &bytes, TRUE)){
        ruby_xfree(buffer);
        CloseHandle(h);
        rb_sys_fail("GetOverlappedResult");
      }
    }
    else{
      ruby_xfree(buffer);
      CloseHandle(h);
      rb_sys_fail("ReadFile");
    }
  }

  CloseHandle(h);
  buffer[length] = 0;

  return rb_str_new(buffer, length);
}

void Init_nio(){
  VALUE mWin32 = rb_define_module("Win32");
  VALUE cNio = rb_define_class_under(mWin32, "NIO", rb_cObject);

  rb_define_singleton_method(cNio, "read", rb_nio_read, -1);
}
