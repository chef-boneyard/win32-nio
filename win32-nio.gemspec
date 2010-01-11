require 'rubygems'

spec = Gem::Specification.new do |gem|
   gem.name     = 'win32-nio'
   gem.version  = '0.0.2'
   gem.author   = 'Daniel J. Berger'
   gem.license  = 'Artistic 2.0'
   gem.email    = 'djberg96@gmail.com'
   gem.homepage = 'http://www.rubyforge.org/projects/win32utils'
   gem.platform = Gem::Platform::RUBY
   gem.summary  = 'Native IO for MS Windows'
   gem.has_rdoc = true
   gem.files    = Dir['**/*'].reject{ |f| f.include?('CVS') }

   gem.rubyforge_project = 'Win32Utils'
   gem.extra_rdoc_files  = ['README', 'CHANGES', 'MANIFEST']

   gem.description = <<-EOF
      The win32-nio library implements certain IO methods using native
      Windows function calls rather than using the POSIX compatibility
      layer that MRI typically uses. In addition, some methods provide
      additional event handling capability.
   EOF

   gem.add_dependency('windows-pr', '>= 0.9.5')
   gem.add_dependency('win32-event', '>= 0.5.0')
   gem.add_development_dependency('test-unit', '>= 2.0.3')
end

Gem::Builder.new(spec).build
