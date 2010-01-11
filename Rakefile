require 'rake'
require 'rake/testtask'
require 'rbconfig'
include Config

desc 'Install the win32-nio library (non-gem)'
task :install do
   sitelibdir = CONFIG['sitelibdir']
   installdir = File.join(sitelibdir, 'win32')
   file = 'lib\win32\nio.rb'

   Dir.mkdir(installdir) unless File.exists?(installdir)
   FileUtils.cp(file, installdir, :verbose => true)
end

desc 'Run the benchmark suite'
task :bench do
   sh "ruby -Ilib benchmarks/win32_nio_benchmarks.rb"end

Rake::TestTask.new do |t|
   t.verbose = true
   t.warning = true
end
