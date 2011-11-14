require 'spec_helper'

describe "Get Emails" do
  before(:all) do
    username     = CREDENTIALS['qamail']['username']
    password     = CREDENTIALS['qamail']['password']
    send_to      = CREDENTIALS['qamail']['send_to']
    @subject     = "Multiple Email Test #{Time.now.strftime "%Y%m%d%H%M%S"}"
    @search_terms = ['SUBJECT', "Multiple Email Test"]
    @e            = WatirmarkEmail::QAMail.new(username, password, ::Logger::DEBUG)
    1.upto(5) do |x|
      @e.send_email(send_to, :subject => "#{@subject} - message #{x}", :body => "#{@subject} - message #{x}")
    end
  end

  after(:all) do
    @e.delete_emails @search_terms
  end

  it "should find 5 emails when searching by subject \"Multiple Email Test\"" do
    emails = @e.find_emails(@search_terms)
    emails.length.should == 5
  end

  it "when searching by subject \"Multiple Email Test\", each found email should have a subject and a body with an incrementing number" do
    emails = @e.find_emails(@search_terms)
    0.upto(4).each do |x|
      emails[x].subject.should == "#{@subject} - message #{x + 1}"
      emails[x].body_text.should =~ /#{@subject} - message #{x + 1}/
    end
  end

  it "when searching by subject \"Multiple Email Test\", mapping the subjects to an array returns an array of length 5" do
    expected_subject_array = ["#{@subject} - message 1",
                              "#{@subject} - message 2",
                              "#{@subject} - message 3",
                              "#{@subject} - message 4",
                              "#{@subject} - message 5"]
    @e.find_emails(@search_terms).map { |email| email.subject }.sort.should == expected_subject_array
  end
end