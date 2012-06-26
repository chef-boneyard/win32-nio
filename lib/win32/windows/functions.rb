require 'ffi'

module Windows
  module Functions
    extend FFI::Library
    ffi_lib :kernel32

    attach_function :CloseHandle, [:long], :bool
    attach_function :CreateFileA, [:string, :ulong, :ulong, :pointer, :ulong, :ulong, :ulong], :ulong
    attach_function :CreateFileW, [:buffer_in, :ulong, :ulong, :pointer, :ulong, :ulong, :ulong], :ulong
    attach_function :GetLastError, [], :ulong
    attach_function :GetSystemInfo, [:pointer], :void
    attach_function :ReadFile, [:ulong, :buffer_out, :ulong, :pointer, :pointer], :bool
    attach_function :ReadFileScatter, [:ulong, :pointer, :ulong, :pointer, :pointer], :bool
    attach_function :SleepEx, [:ulong, :bool], :ulong
    attach_function :VirtualAlloc, [:pointer, :size_t, :ulong, :ulong], :ulong
    attach_function :VirtualFree, [:ulong, :size_t, :ulong], :bool

    ffi_lib :msvcrt

    attach_function :memcpy, [:pointer, :pointer, :size_t], :pointer
  end
end
