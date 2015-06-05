require 'spec_helper'

describe 'test BaseController helper methods' do

  it "Should convert a hash to an IMAP friendly array" do
    base_controller = WatirmarkEmail::BaseController.new
    search_hash = {:subject => 'Test Subject', :reply_to => 'test@devnull.com'}
    search_array = base_controller.search_hash_to_array(search_hash)
    search_hash.each_with_index do |key_and_value, index|
      key = key_and_value.first
      key_index = index * 2
      value_index = key_index + 1
      expect(key.to_s.upcase).to eq(search_array[key_index])
      expect(search_hash[key]).to eq(search_array[value_index])
    end
  end

  it "Should raise an error for improper parameter input" do
    expect { WatirmarkEmail::BaseController.new.search_hash_to_array("Test") }.to raise_error
  end

end