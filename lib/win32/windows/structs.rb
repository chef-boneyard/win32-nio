require 'ffi'

module Windows
  module Structs
    extend FFI::Library

    # I'm assuming the anonymous struct for the internal union here.
    class Overlapped < FFI::Struct
      layout(
        :Internal, :pointer,
        :InternalHigh, :pointer,
        :Offset, :ulong,
        :OffsetHigh, :ulong,
        :hEvent, :ulong
      )
    end

    # dwOemId is deprecated. Just assume the nested struct.
    class SystemInfo < FFI::Struct
      layout(
        :wProcessorArchitecture, :ushort,
        :wReserved, :ushort,
        :dwPageSize, :ulong,
        :lpMinimumApplicationAddress, :pointer,
        :lpMaximumApplicationAddress, :pointer,
        :dwActiveProcessorMask, :pointer,
        :dwNumberOfProcessors, :ulong,
        :dwProcessorType, :ulong,
        :dwAllocationGranularity, :ulong,
        :wProcessorLevel, :ushort,
        :wProcessorRevision, :ushort
      )
    end

    class FileSegmentElement < FFI::Union
      layout(:Buffer, :pointer, :Alignment, :double)
    end
  end
end
