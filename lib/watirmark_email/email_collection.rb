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
      @froms  ||= envelope.from.each_with_object([]) do |from_user, froms_array|
        froms_array << "#{from_user.mailbox}@#{from_user.host}"
      end
    end

    def tos
      @tos ||= envelope.to.each_with_object([]) do |to_user, tos_array|
        tos_array << "#{to_user.mailbox}@#{to_user.host}"
      end
    end

    def reply_tos
        @reply_tos ||= envelope.reply_to.each_with_object([]) do |reply_to_user, reply_tos_array|
          reply_tos_array <<  "#{reply_to_user.name} <#{reply_to_user.mailbox}@#{reply_to_user.host}>"
        end
    end

    def senders
      @senders ||=  envelope.sender.each_with_object([]) do |sender_user, senders_array|
        senders_array <<  "#{sender_user.name} <#{sender_user.mailbox}@#{sender_user.host}>"
      end
    end

    def bccs
      @bccs ||=  envelope.bcc.each_with_object([]) do |bcc_user, bccs_array|
        bccs_array <<  "#{bcc_user.name} <#{bcc_user.mailbox}@#{bcc_user.host}>"
      end
    end

    def ccs
      @ccs ||=  envelope.cc.each_with_object([]) do |cc_user, ccs_array|
        ccs_array <<  "#{cc_user.name} <#{cc_user.mailbox}@#{cc_user.host}>"
      end
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


