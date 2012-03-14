$:.unshift File.expand_path("../lib", __FILE__)
require "watirmark_email/version"

Gem::Specification.new do |s|
  name = WatirmarkEmail::VERSION::NAME
  s.name = name
  version = WatirmarkEmail::VERSION::STRING
  s.version = version
  s.authors = [%q{Alan Baird}]
  s.email = %q{abaird@convio.com}
  s.description = %q{watirmark_email lets you get email from both GMAIL and generic IMAP servers}
  s.summary = WatirmarkEmail::VERSION::SUMMARY
  s.homepage = "http://github.com/convio/watirmark_email"
  s.files = Dir['lib/**/*']
  s.test_files =  Dir['spec/**/*.rb']
  s.require_paths = ["lib"]
end