module WatirmarkEmail
  class Email
    attr_accessor :date, :subject, :to, :from, :message_id, :body_text, :body_raw, :uid, :envelope

    def subject
      @subject ||= envelope.subject
    end

    def date
      @date ||= envelope.date
    end

    def message_id
      @message_id ||= envelope.message_id
    end

    def from
      @from ||= "#{envelope.from.first.mailbox}@#{envelope.from.first.host}"
    end

    def to
      @to ||= envelope.to.each_with_object([]) do |recipient, to_array|
        to_array << "#{recipient.mailbox}@#{recipient.host}"
      end
    end

    def <=> (other)
      date <=> other.date
    end
  end

  class EmailCollection
    include Enumerable

    def initialize
      @emails = []
    end

    def each(&block)
      @emails.each(&block)
    end

    def empty?
      @emails.empty?
    end

    def [](x)
      @emails[x]
    end

    def length
      @emails.length
    end
    alias :size :length

    def add_emails(email_info)
      #should be an array of Net::IMAP::FetchData or a single class
      email_info = [email_info] unless email_info.is_a?(Array)
      email_info.each do |email|
        current_email = Email.new
        current_email.envelope = email.attr["ENVELOPE"]
        current_email.body_text = email.attr["BODY[TEXT]"]
        current_email.body_raw = email.attr["BODY[]"]
        current_email.uid = email.attr["UID"]
        @emails << current_email.dup
      end
    end
  end
end


