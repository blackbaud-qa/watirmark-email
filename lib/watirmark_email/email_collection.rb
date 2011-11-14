module WatirmarkEmail
  class Email
    attr_accessor :date, :subject, :to, :from, :message_id, :body_text, :body_raw, :uid

    def initialize(envelope, body_text, body_raw, uid)
      @to = []
      @date = envelope.date
      @subject = envelope.subject
      envelope.to.each do |recipient|
        @to << "#{recipient.mailbox}@#{recipient.host}"
      end
      @from = "#{envelope.from.first.mailbox}@#{envelope.from.first.host}"
      @message_id = envelope.message_id
      @body_text = body_text
      @body_raw = body_raw
      @uid = uid
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
        envelope = email.attr["ENVELOPE"]
        body_text = email.attr["BODY[TEXT]"]
        body_raw = email.attr["BODY[]"]
        uid = email.attr["UID"]
        @emails << Email.new(envelope, body_text, body_raw, uid)
      end
    end
  end
end


