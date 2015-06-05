module WatirmarkEmail
  class Email
    attr_accessor :date, :subject, :in_reply_to, :message_id, :body_text, :body_raw, :uid, :envelope,
                  :tos, :reply_tos, :froms, :senders, :ccs, :bccs

    def subject
      @subject ||= envelope.subject
    end

    def date
      @date ||= envelope.date
    end

    def message_id
      @message_id ||= envelope.message_id
    end

    def froms
      @froms  ||= construct_array_for(envelope.from)
    end

    def tos
      @tos ||= construct_array_for(envelope.to)
    end

    def reply_tos
        @reply_tos ||= construct_array_for(envelope.reply_to)
    end

    def senders
      @senders ||= construct_array_for(envelope.sender)
    end

    def bccs
      @bccs ||= construct_array_for(envelope.bcc)
    end

    def ccs
      @ccs ||= construct_array_for(envelope.cc)
    end

    def in_reply_to
      @in_reply_to ||= envelope.in_reply_to
    end

    def <=> (other)
      date <=> other.date
    end

    def has_envelope?
      not envelope.nil?
    end

    private

    def construct_array_for field_values
      result_array = Array.new
      field_values.each do |user|
        result_array <<  "#{user.name} <#{user.mailbox}@#{user.host}>"
      end
      result_array
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


