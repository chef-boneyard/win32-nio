#include <ruby.h>
#include <windows.h>

static VALUE rb_nio_read(int argc, VALUE* argv, VALUE self){
  OVERLAPPED olap;
  HANDLE h;
  DWORD bytes_read;
  LARGE_INTEGER size;
  VALUE v_file, v_length, v_offset;
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

  if (!GetFileSizeEx(h, &size)){
    CloseHandle(h);
    rb_sys_fail("GetFileSizeEx");
  }

  buffer = (char*)ruby_xmalloc((size_t)size.QuadPart * sizeof(char));

  if (!ReadFile(h, buffer, (size_t)size.QuadPart, &bytes_read, &olap)){
    ruby_xfree(buffer);
    CloseHandle(h);
    rb_sys_fail("ReadFile");
  }

  CloseHandle(h);

  return rb_str_new(buffer, (size_t)size.QuadPart);
}

void Init_nio(){
  VALUE mWin32 = rb_define_module("Win32");
  VALUE cNio = rb_define_class_under(mWin32, "NIO", rb_cObject);

  rb_define_singleton_method(cNio, "read", rb_nio_read, -1);
}
