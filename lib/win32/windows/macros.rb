module Windows
  module Macros
    def HasOverlappedIoCompleted(overlapped)
      overlapped[:Internal] != 259 # STATUS_PENDING
    end
  end
end
