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
  end
end
