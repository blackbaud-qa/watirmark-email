require 'rspec'
require 'yaml'
require 'watirmark_email'

# this file contains credentials to gmail and IMAP servers in a simple hash expressed in YAML and looks like:
#---
#qamail:
#  username: <supply your own>
#  password: <not telling>
#  send_to: <email address on your IMAP server, needed here because we all know how to get to gmail>
#gmail:
#  username: <supply your own>
#  password: <not telling>
CREDENTIALS = YAML.load_file(File.join(File.dirname(__FILE__), "email_server_credentials.yaml"))

# alias :context :describe
