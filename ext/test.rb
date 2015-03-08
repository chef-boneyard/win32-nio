$:.unshift Dir.pwd
require 'nio'
include Win32
p NIO.read('temp.txt')
