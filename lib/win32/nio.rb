require 'ffi'

require File.join(File.dirname(__FILE__), 'windows/functions')
require File.join(File.dirname(__FILE__), 'windows/constants')
require File.join(File.dirname(__FILE__), 'windows/structs')
require File.join(File.dirname(__FILE__), 'windows/macros')

# The Win32 module serves as a namespace only.
module Win32

  # The NIO class encapsulates the native IO methods for MS Windows.
  class NIO
    include Windows::Constants
    include Windows::Structs
    extend  Windows::Functions
    extend  Windows::Macros

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

    def self.readlines(file, sep = "\r\n")
      begin
        handle = CreateFileA(
          file,
          GENERIC_READ,
          FILE_SHARE_READ,
          nil,
          OPEN_EXISTING,
          FILE_FLAG_OVERLAPPED | FILE_FLAG_NO_BUFFERING,
          0
        )

        if handle == INVALID_HANDLE_VALUE
          raise Error, get_last_error
        end

        sysinfo = SystemInfo.new
        GetSystemInfo(sysinfo)

        file_size = File.size(file)
        page_size = sysinfo[:dwPageSize]
        page_num  = (file_size.to_f / page_size).ceil
        
        begin
          size = page_size * page_num
          base_address = VirtualAlloc(nil, size, MEM_COMMIT, PAGE_READWRITE)

          if base_address == 0
            raise Error, get_last_error
          end

          buf_list = []

          for i in 0...page_num
            buf_list.push(base_address + page_size * i)
          end

          seg_array  = buf_list.pack('Q*') + 0.chr * 8
          overlapped = Overlapped.new

          bool = ReadFileScatter(handle, seg_array, size, nil, overlapped)

          unless bool > 0
            error = GetLastError()
            if error != ERROR_IO_PENDING
              raise Error, get_last_error(error)
            end
          end

          SleepEx(1, 1) unless HasOverlappedIoCompleted(overlapped)

          buffer = 0.chr * file_size
          memcpy(buffer, buf_list[0], file_size)
          buffer.split("\r\n")
        end
      ensure
        CloseHandle(handle) if handle && handle != INVALID_HANDLE_VALUE
        VirtualFree(base_address, 0, MEM_RELEASE)
      end
    end # NIO.readlines

  end # NIO
end # Win32

Win32::NIO.readlines('test.txt')
