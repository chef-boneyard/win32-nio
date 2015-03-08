#include <ruby.h>
#include <windows.h>

static VALUE rb_nio_read(int argc, VALUE* argv, VALUE self){
  OVERLAPPED olap;
  HANDLE h;
  DWORD bytes_read;
  LARGE_INTEGER size;
  VALUE v_file, v_length, v_offset;
  size_t length;
  char* buffer = NULL;

  memset(&olap, 0, sizeof(olap));

  rb_scan_args(argc, argv, "12", &v_file, &v_length, &v_offset);

  h = CreateFileA(
    RSTRING_PTR(v_file),
    GENERIC_READ,
    FILE_SHARE_READ,
    NULL,
    OPEN_EXISTING,
    FILE_FLAG_SEQUENTIAL_SCAN,
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

  if (!NIL_P(v_offset))
    olap.Offset = NUM2INT(v_offset);

  buffer = (char*)ruby_xmalloc(length * sizeof(char));

  if (!ReadFile(h, buffer, length, &bytes_read, &olap)){
    ruby_xfree(buffer);
    CloseHandle(h);
    rb_sys_fail("ReadFile");
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
