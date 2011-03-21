require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'

# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
#
# License::   MIT - Free, OpenSource
#
# Details::   Gem::Specification for Active Record Loader gem.
#
#             Specifically enabled for uploading Spree products but easily
#             extended to any AR model.
#
#             Currently support direct access to Excel Spreedsheets via JRuby
#
#             TODO - Switch for non JRuby Rubies, enable load via CSV file instead of Excel.
#
require "lib/ar_loader"

ArLoader::require_tasks

spec = Gem::Specification.new do |s|
  s.name = ArLoader.gem_name
  s.version = ArLoader.gem_version
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.markdown', 'LICENSE']
  s.summary = 'File based loader for Active Record models'
  s.description = 'A file based loader for Active Record models. Seed database directly from Excel/CSV'
  s.author = 'thomas statter'
  s.email = 'gems@autotelik.co.uk'
  s.date = DateTime.now.strftime("%Y-%m-%d")
  s.homepage = %q{http://www.autotelik.co.uk}

  # s.executables = ['your_executable_here']
  s.files = %w(LICENSE README.markdown Rakefile) + Dir.glob("{lib,spec,tasks}/**/*")
  s.require_path = "lib"
  s.bindir = "bin"
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

Rake::RDocTask.new do |rdoc|
  files =['README.markdown', 'LICENSE', 'lib/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README.markdown" # page to start on
  rdoc.title = "ARLoader Docs"
  rdoc.rdoc_dir = 'doc/rdoc' # rdoc output folder
  rdoc.options << '--line-numbers'
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*.rb']
end

# Add in our own Tasks

# Long parameter lists so ensure rake -T produces nice wide output
ENV['RAKE_COLUMNS'] = '180'

desc 'Build gem and install in one step'
task :pik_install, :needs => [:gem]  do |t, args|

  puts "Installing version #{ArLoader.gem_version}"

  gem = "#{ArLoader.gem_name}-#{ArLoader.gem_version}.gem"
  cmd = "pik gem install --no-ri --no-rdoc pkg\\#{gem}"
  system(cmd)
end
