# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "watirmark_email"
  gem.homepage = "http://github.com/convio/watirmark_email"
  gem.license = "MIT"
  gem.summary = %Q{watirmark_email is a gem for getting email from an IMAP server}
  gem.description = %Q{watirmark_email lets you get email from both GMAIL and generic IMAP servers}
  gem.email = "abaird@convio.com"
  gem.authors = ["Alan Baird"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "watirmark_email #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

# surely there must be a better way to build the deploy task??!!??
def gemfile_name
  version = File.exist?('VERSION') ? File.read('VERSION') : ""
  "watirmark_email-#{version}.gem"
end
gem = "ruby #{Config::CONFIG['bindir']}\\gem"

desc "deploy the gem to the gem server; must be run on on qalin"
task :deploy do
  sh "#{gem} install --local -i c:\\gem_server --no-ri pkg\\#{gemfile_name} --ignore-dependencies"
end
