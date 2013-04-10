require 'ffi'

module Windows
  module Functions
    extend FFI::Library
    typedef :ulong, :dword
    typedef :uintptr_t, :handle
    typedef :pointer, :ptr

    ffi_lib :kernel32
    ffi_convention :stdcall

    attach_function :CloseHandle, [:handle], :bool
    attach_function :CreateFileA, [:string, :dword, :dword, :ptr, :dword, :dword, :handle], :handle
    attach_function :CreateFileW, [:buffer_in, :dword, :dword, :ptr, :dword, :dword, :handle], :handle
    attach_function :GetOverlappedResult, [:handle, :ptr, :ptr, :bool], :bool
    attach_function :GetSystemInfo, [:ptr], :void
    attach_function :ReadFile, [:handle, :buffer_out, :dword, :ptr, :ptr], :bool
    attach_function :ReadFileScatter, [:handle, :ptr, :dword, :ptr, :ptr], :bool
    attach_function :SleepEx, [:dword, :bool], :dword
    attach_function :VirtualAlloc, [:ptr, :size_t, :dword, :dword], :dword
    attach_function :VirtualFree, [:dword, :size_t, :dword], :bool

    callback :completion_function, [:dword, :dword, :ptr], :void
    attach_function :ReadFileEx, [:handle, :buffer_out, :dword, :ptr, :completion_function], :bool
  end
end
