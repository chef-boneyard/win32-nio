require 'ffi'

module Windows
  module Functions
    extend FFI::Library
    ffi_lib :kernel32
    ffi_convention :stdcall

    attach_function :CloseHandle, [:long], :bool
    attach_function :CreateFileA, [:string, :ulong, :ulong, :pointer, :ulong, :ulong, :ulong], :ulong
    attach_function :CreateFileW, [:buffer_in, :ulong, :ulong, :pointer, :ulong, :ulong, :ulong], :ulong
    attach_function :GetOverlappedResult, [:ulong, :pointer, :pointer, :bool], :bool
    attach_function :GetSystemInfo, [:pointer], :void
    attach_function :ReadFile, [:ulong, :buffer_out, :ulong, :pointer, :pointer], :bool
    attach_function :ReadFileScatter, [:ulong, :pointer, :ulong, :pointer, :pointer], :bool
    attach_function :SleepEx, [:ulong, :bool], :ulong
    attach_function :VirtualAlloc, [:pointer, :size_t, :ulong, :ulong], :ulong
    attach_function :VirtualFree, [:ulong, :size_t, :ulong], :bool

    callback :completion_function, [:ulong, :ulong, :pointer], :void
    attach_function :ReadFileEx, [:ulong, :buffer_out, :ulong, :pointer, :completion_function], :bool
  end
end
