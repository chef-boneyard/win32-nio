require 'rake'
require 'rake/testtask'
require 'rbconfig'
include Config

namespace 'gem' do
  desc 'Remove any .gem files from the project.'
  task :clean do
    Dir['*.gem'].each{ |f| File.delete(f) }
  end

  desc 'Create the win32-nio gem'
  task :create => [:clean] do
    spec = eval(IO.read('win32-nio.gemspec'))
    Gem::Builder.new(spec).build
  end

  desc 'Install the win32-nio gem'
  task :install => [:create] do
    file = Dir['*.gem'].first
    sh "gem install #{file}"
  end
end

desc 'Run the benchmark suite'
task :bench do
  sh "ruby -Ilib benchmarks/win32_nio_benchmarks.rb"
end

Rake::TestTask.new do |t|
  t.verbose = true
  t.warning = true
end

task :default => :test
