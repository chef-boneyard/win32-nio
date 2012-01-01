require 'ffi'

module Windows
  module Structs
    extend FFI::Library

    class Overlapped < FFI::Struct
      layout(
        :Internal, :pointer,
        :InternalHigh, :pointer,
        :Offset, :ulong,
        :OffsetHigh, :ulong,
        :Vpointer, :pointer,
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
  end
end
