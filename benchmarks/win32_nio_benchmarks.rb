########################################################################
# win32_nio_benchmarks.rb
#
# Run this via the 'rake bench' task to compare win32-nio with Ruby's
# own IO methods. This benchmark will take a bit of time, since it
# generates some test files on the fly.
########################################################################
require 'benchmark'
require 'win32/nio'
include Win32

MAX = (ARGV[0] || '10').chomp.to_i # Default to 10 iterations
PHRASE = "The quick brown fox jumped over the lazy dog's back"

SMALL_FILE  = "small_nio_test.txt"  # 588k
MEDIUM_FILE = "medium_nio_test.txt" # 6mb
LARGE_FILE  = "large_nio_test.txt"  # 60mb
HUGE_FILE   = "huge_nio_test.txt"   # 618mb

unless File.exists?(SMALL_FILE)
   File.open(SMALL_FILE, 'w'){ |fh|
      10000.times{ |n| fh.puts PHRASE + ": #{n}" }
   }

   puts "Small file created"
end

unless File.exists?(MEDIUM_FILE)
   File.open(MEDIUM_FILE, 'w'){ |fh|
      110000.times{ |n| fh.puts PHRASE + ": #{n}" }
   }

   puts "Medium file created"
end

unless File.exists?(LARGE_FILE)
   File.open(LARGE_FILE, 'w'){ |fh|
      1000000.times{ |n| fh.puts PHRASE + ": #{n}" }
   }

   puts "Large file created"
end

unless File.exists?(HUGE_FILE)
   #File.open(HUGE_FILE, 'w'){ |fh|
   #   10000000.times{ |n| fh.puts PHRASE + ": #{n}" }
   #}

   #puts "Huge file created"
end

Benchmark.bm(20) do |x|
   x.report('IO.read(small)'){
      MAX.times{ IO.read(SMALL_FILE) }
   }

   x.report('NIO.read(small)'){
      MAX.times{ NIO.read(SMALL_FILE) }
   }

   x.report('IO.read(medium)'){
      MAX.times{ IO.read(MEDIUM_FILE) }
   }

   x.report('NIO.read(medium)'){
      MAX.times{ NIO.read(MEDIUM_FILE) }
   }

   x.report('IO.read(large)'){
      MAX.times{ IO.read(LARGE_FILE) }
   }

   x.report('NIO.read(large)'){
      MAX.times{ NIO.read(LARGE_FILE) }
   }

   #x.report('IO.read(huge)'){
   #   MAX.times{ IO.read(HUGE_FILE) }
   #}

   #x.report('NIO.read(huge)'){
   #   MAX.times{ NIO.read(HUGE_FILE) }
   #}

   x.report('IO.readlines(small)'){
      MAX.times{ IO.readlines(SMALL_FILE) }
   }

   x.report('NIO.readlines(small)'){
      MAX.times{ NIO.readlines(SMALL_FILE) }
   }
   
   x.report('IO.readlines(medium)'){
      MAX.times{ IO.readlines(MEDIUM_FILE) }
   }

   x.report('NIO.readlines(medium)'){
      MAX.times{ NIO.readlines(MEDIUM_FILE) }
   }
   
   x.report('IO.readlines(large)'){
      MAX.times{ IO.readlines(LARGE_FILE) }
   }

   x.report('NIO.readlines(large)'){
      MAX.times{ NIO.readlines(LARGE_FILE) }
   }
end

File.delete(SMALL_FILE) if File.exists?(SMALL_FILE)
File.delete(MEDIUM_FILE) if File.exists?(MEDIUM_FILE)
File.delete(LARGE_FILE) if File.exists?(LARGE_FILE)
File.delete(HUGE_FILE) if File.exists?(HUGE_FILE)
