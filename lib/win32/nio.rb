require 'ffi'

require File.join(File.dirname(__FILE__), 'windows/functions')
require File.join(File.dirname(__FILE__), 'windows/constants')
require File.join(File.dirname(__FILE__), 'windows/structs')

# The Win32 module serves as a namespace only.
module Win32

  # The NIO class encapsulates the native IO methods for MS Windows.
  class NIO
    include Windows::Constants
    include Windows::Structs
    extend  Windows::Functions

    # The version of the win32-nio library
    VERSION = '0.1.0'

    # Error typically raised if any of the native functions fail.
    class Error < StandardError; end

    # This method is similar to Ruby's IO.read method except that it uses
    # native function calls.
    #
    # Examples:
    #
    # # Read everything
    # Win32::NIO.read(file)
    #
    # # Read the first 100 bytes
    # Win32::NIO.read(file, 100)
    #
    # # Read 50 bytes starting at offset 10
    # Win32::NIO.read(file, 50, 10)
    #
    def self.read(name, length=nil, offset=0)
      begin
        handle = CreateFileA(
          name,
          GENERIC_READ,
          FILE_SHARE_READ,
          nil,
          OPEN_EXISTING,
          FILE_FLAG_SEQUENTIAL_SCAN,
          0
        )

        if handle == INVALID_HANDLE_VALUE
          raise "CreateFile failed: " + get_last_error
        end

        length ||= File.size(name)

        olap  = Overlapped.new
        ptr   = FFI::MemoryPointer.new(:char, length)
        bytes = FFI::MemoryPointer.new(:ulong)

        olap[:Offset] = offset

        bool = ReadFile(handle, ptr, length, bytes, olap)

        unless bool
          raise "ReadFile failed: " + get_last_error 
        end

        ptr.read_string(length)[/^[^\0]*/]
      ensure
        CloseHandle(handle) if handle && handle != INVALID_HANDLE_VALUE
      end
    end # NIO.read

  end # NIO
end # Win32
