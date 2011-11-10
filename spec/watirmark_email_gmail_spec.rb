require 'spec_helper'

context 'WatirmarkEmail::Gmail' do

  before :all do
    STDOUT.sync = true
    @username = CREDENTIALS['gmail']['username']
    @password = CREDENTIALS['gmail']['password']
    @test_message = ['SUBJECT', 'UNIT TEST MESSAGE', 'BODY', "unit_test_message_id"]
    @does_not_exist_test_message = ['SUBJECT', "MISSING"]
  end

  specify 'initialize email connection to gmail.com' do
    e = WatirmarkEmail::Gmail.new(@username, @password)
    e.should_not be_nil
  end

  specify 'should timeout when the email does not exist' do
    e = WatirmarkEmail::Gmail.new(@username, @password, Logger::DEBUG)
    lambda {
      txt = e.get_email_text(@does_not_exist_test_message, 15, false)
    }.should raise_error Timeout::Error
  end

  specify 'should send an email to gmail' do
    e = WatirmarkEmail::Gmail.new(@username, @password, Logger::DEBUG)
    e.send_email(@username, :subject => 'UNIT TEST MESSAGE', :body => "unit_test_message_id").should be_true
  end

  specify 'copy the test email to the UnitTest folder' do
    e = WatirmarkEmail::Gmail.new(@username, @password, Logger::DEBUG)
    e.copy(@test_message, 'UnitTest')
  end

  specify 'verify test email exists in the UnitTest folder' do
    e = WatirmarkEmail::Gmail.new(@username, @password, Logger::DEBUG)
    e.inbox = 'UnitTest'
    txt = e.get_email_text(@test_message, 60, false)
    txt.should be_a(String)
  end

  specify 'copy the test email from the UnitTest folder to the inbox' do
    e = WatirmarkEmail::Gmail.new(@username, @password, Logger::DEBUG)
    e.inbox = 'UnitTest'
    e.copy(@test_message, WatirmarkEmail::Gmail::MAILBOX_INBOX)
  end

  specify 'should return body text from an email in the inbox' do
    e = WatirmarkEmail::Gmail.new(@username, @password, Logger::DEBUG)
    txt = e.get_email_text(@test_message, 60, false)
    txt.should be_a(String)
  end

  specify 'delete flag should remove the email from the inbox' do
    e = WatirmarkEmail::Gmail.new(@username, @password, Logger::DEBUG)
    txt = e.get_email_text(@test_message, 60, true)
    txt.should be_a(String)
  end

  specify 'should not see the email now that it is deleted' do
    e = WatirmarkEmail::Gmail.new(@username, @password, Logger::DEBUG)
    lambda {
      txt = e.get_email_text(@test_message, 15, false)
    }.should raise_error Timeout::Error
  end
end