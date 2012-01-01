module Windows
  module Macros
    def HasOverlappedIoCompleted(overlapped)
      overlapped[:Internal].read_long != 259 # STATUS_PENDING
    end
  end
end
