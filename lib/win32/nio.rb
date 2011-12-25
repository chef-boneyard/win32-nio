require 'windows/file'
require 'windows/handle'
require 'windows/error'
require 'windows/memory'
require 'windows/nio'
require 'windows/synchronize'
require 'windows/system_info'
require 'windows/thread'
require 'windows/msvcrt/io'
require 'windows/msvcrt/buffer'
require 'win32/event'

# The Win32 module serves as a namespace only.
module Win32

  # The NIO class encapsulates the native IO methods for MS Windows.
  class NIO
    include Windows::File
    include Windows::Handle
    include Windows::Error
    include Windows::Synchronize
    include Windows::MSVCRT::IO
    include Windows::MSVCRT::Buffer
    include Windows::SystemInfo
    include Windows::Memory
    include Windows::NIO
    include Windows::Thread

    extend Windows::File
    extend Windows::Handle
    extend Windows::Error
    extend Windows::Synchronize
    extend Windows::MSVCRT::IO
    extend Windows::MSVCRT::Buffer
    extend Windows::SystemInfo
    extend Windows::Memory
    extend Windows::NIO
    extend Windows::Thread

    # The version of the win32-nio library
    VERSION = '0.0.3'

    # Error typically raised if any of the native functions fail.
    class Error < StandardError; end

    # This method is similar to Ruby's IO.read method except that, in
    # addition to using native function calls, it accepts an optional +event+
    # argument for the fourth argument, which must be an instance of
    # Win32::Event (if provided). The event is automatically set to a
    # signaled state when the read operation completes.
    #
    # If a block is provided, then it is treated as a callback that fires
    # when the read operation is complete.
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
    # # Read 25 bytes, starting at offset 5, and print "Done!" when finished.
    # Win32::NIO.read(file, 25, 5){ puts "Done!" }
    #
    # # Attach an event that fires when finished.
    # require 'win32/event'
    # event = Win32::Event.new{ puts "Finished!" }
    # Win32::NIO.read(file, nil, nil, event)
    #
    def self.read(port_name, length=nil, offset=0, event=nil, &block)
      if length
        raise TypeError unless length.is_a?(Fixnum)
        raise ArgumentError if length < 0
      end

      if offset
        raise TypeError unless offset.is_a?(Fixnum)
        raise ArgumentError if offset < 0
      end

      if event
        raise TypeError unless event.is_a?(Win32::Event)
      end

      flags = FILE_FLAG_SEQUENTIAL_SCAN

      overlapped = 0.chr * 20  # sizeof(OVERLAPPED)
      overlapped[8,4] = [offset].pack('L') # OVERLAPPED.Offset

      if offset > 0 || event
        flags |= FILE_FLAG_OVERLAPPED
        overlapped[16,4] = [event.handle].pack('L') if event
      end

      handle = CreateFile(
        port_name,
        FILE_READ_DATA,
        FILE_SHARE_READ,
        0,
        OPEN_EXISTING,
        flags,
        0
      )

      if handle == INVALID_HANDLE_VALUE
        raise Error, get_last_error
      end

      # Ruby's File.size is broken, so we implement it here. Also, if an
      # offset is provided, we can reduce the size to only what we need.
      if length.nil?
        size = [0].pack('Q')
        GetFileSizeEx(handle, size)
        length = size.unpack('Q').first
        length -= offset if offset
      end

      buf = 0.chr * length

      begin
        if block_given?
          callback = Win32::API::Callback.new('LLP', 'V'){ block.call }
          bool = ReadFileEx(handle, buf, length, overlapped, callback)
        else
          bytes = [0].pack('L')
          bool = ReadFile(handle, buf, length, bytes, overlapped)
        end

        errno = GetLastError()

        SleepEx(1, true) # Must be in alertable wait state

        unless bool
          if errno = ERROR_IO_PENDING
            unless GetOverlappedResult(handle, overlapped, bytes, true)
              raise Error, get_last_error
            end
          else
            raise Error, errno
          end
        end

        event.wait if event
      ensure
        CloseHandle(handle)
      end

      buf[0, length]
    end

    # Reads the entire file specified by portname as individual lines, and
    # returns those lines in an array. Lines are separated by +sep+.
    #--
    # The semantics are the same as the MRI version but the implementation
    # is drastically different. We use a scattered IO read.
    #
    def self.readlines(file, sep = "\r\n")
      handle = CreateFile(
        file,
        GENERIC_READ,
        FILE_SHARE_READ,
        nil,
        OPEN_EXISTING,
        FILE_FLAG_OVERLAPPED | FILE_FLAG_NO_BUFFERING,
        nil
      )

      if handle == INVALID_HANDLE_VALUE
        raise Error, get_last_error
      end

      sysbuf = 0.chr * 40
      GetSystemInfo(sysbuf)

      file_size = [0].pack('Q')
      GetFileSizeEx(handle, file_size)
      file_size = file_size.unpack('Q')[0]

      page_size = sysbuf[4,4].unpack('L')[0] # dwPageSize
      page_num  = (file_size.to_f / page_size).ceil

      begin
        base_address = VirtualAlloc(
          nil,
          page_size * page_num,
          MEM_COMMIT,
          PAGE_READWRITE
        )

        buf_list = []

        for i in 0...page_num
          buf_list.push(base_address + page_size * i)
        end

        seg_array  = buf_list.pack('Q*') + 0.chr * 8
        overlapped = 0.chr * 20

        bool = ReadFileScatter(
          handle,
          seg_array,
          page_size * page_num,
          nil,
          overlapped
        )

        unless bool
          error = GetLastError()
          if error != ERROR_IO_PENDING
            raise Error, get_last_error(error)
          end
        end

        SleepEx(1, true) unless HasOverlappedIoCompleted(overlapped)

        buffer = 0.chr * file_size
        memcpy(buffer, buf_list[0], file_size)
      ensure
        CloseHandle(handle)
        VirtualFree(base_address, 0, MEM_RELEASE)
      end

      if sep == ""
        buffer = buffer.split(/(\r\n){2,}/)
        buffer.delete("\r\n")
      else
        buffer = buffer.split(sep)
      end

      buffer
    end
  end
end
