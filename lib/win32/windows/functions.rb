require 'ffi'

module Windows
  module Functions
    extend FFI::Library

    ffi_lib 'kernel32'
    ffi_convention :stdcall

    attach_function(:CloseHandle, [:long], :int)
    attach_function(:CreateFileA, [:string, :ulong, :ulong, :pointer, :ulong, :ulong, :ulong], :ulong)
    attach_function(:FormatMessageA, [:ulong, :pointer, :ulong, :ulong, :pointer, :ulong, :pointer], :ulong)
    attach_function(:GetLastError, [], :ulong)
    attach_function(:GetSystemInfo, [:pointer], :void)
    attach_function(:ReadFile, [:ulong, :pointer, :ulong, :pointer, :pointer], :int)
    attach_function(:ReadFileScatter, [:ulong, :pointer, :ulong, :pointer, :pointer], :int)
    attach_function(:SleepEx, [:ulong, :int], :ulong)
    attach_function(:VirtualAlloc, [:pointer, :size_t, :ulong, :ulong], :ulong)
    attach_function(:VirtualFree, [:ulong, :size_t, :ulong], :int)

    ffi_lib 'msvcrt'
    attach_function(:memcpy, [:pointer, :pointer, :size_t], :pointer)

    FORMAT_MESSAGE_FROM_SYSTEM    = 0x00001000
    FORMAT_MESSAGE_ARGUMENT_ARRAY = 0x00002000

    # Convenience method that wraps FormatMessage with some sane defaults and
    # returns a human readable string.
    #
    def get_last_error(err_num = GetLastError())
      buf   = FFI::MemoryPointer.new(:char, 260)
      flags = FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ARGUMENT_ARRAY
      FormatMessageA(flags, nil, err_num, 0, buf, buf.size, nil)
      buf.read_string.strip
    end
  end
end
