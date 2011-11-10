require 'spec_helper'

describe "WatirmarkEmail::QAMail" do

  before(:all) do
    @username                 = CREDENTIALS['qamail']['username']
    @password                 = CREDENTIALS['qamail']['password']
    @send_to                  = CREDENTIALS['qamail']['send_to']
    @search_terms             = ['BODY', "Watirmark"]
    @not_present_search_terms = ['SUBJECT', "MISSING"]
  end

  it "should return an instance of itself when started" do
    e = WatirmarkEmail::QAMail.new(@username, @password)
    e.class.should == WatirmarkEmail::QAMail
  end

  it "should be able to connect to the qamail server successfullly" do
    e    = WatirmarkEmail::QAMail.new(@username, @password)
    imap = e.connect
    imap.should_not be_disconnected # cause imap has no "connected" method
    e.disconnect(imap).should be_nil
  end

  it 'should send an email to qamail' do
    e = WatirmarkEmail::QAMail.new(@username, @password)
    e.send_email(@send_to, :subject => 'UNIT TEST MESSAGE', :body => "Watirmark Email test message").should be_true
  end

  it "should get a sample email with 'Watirmark Email test message' in the body of the email" do
    e         = WatirmarkEmail::QAMail.new(@username, @password)
    email_body_text = e.get_email_text(@search_terms, 30, false)
    email_body_text.should match(/Watirmark Email test message/)
  end

  specify "should timeout when the email does not exist" do
    e = WatirmarkEmail::QAMail.new(@username, @password, Logger::DEBUG)
    lambda {
      txt = e.get_email_text(@not_present_search_terms, 15, false)
    }.should raise_error Timeout::Error
  end
end
