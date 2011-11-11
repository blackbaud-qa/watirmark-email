module WatirmarkEmail
  class Gmail < BaseController
    attr_accessor :inbox
    URL           = "imap.gmail.com"
    PORT          = 993
    MAILBOX_INBOX = "INBOX"
    MAILBOX_TRASH = "[Gmail]/Trash"
    MAILBOX_ALL   = "[Gmail]/All Mail"

    # Constructor for this class.
    # This will initialize all variables according to the type email service this is using.
    def initialize(email, password, logLevel = ::Logger::INFO)
      @email     = email
      @password  = password
      @log       = ::Logger.new STDOUT
      @log.level = logLevel
      @url       = URL
      @port      = PORT
      @inbox     = MAILBOX_INBOX
      @trash     = MAILBOX_TRASH
      @ssl       = true # port 993
    end

    def delete(email_uid, imap)
      imap.uid_copy(email_uid, @trash)
      imap.uid_store(email_uid, "+FLAGS", [:Deleted])
    end


    # This keeps polling the email inbox until a message is found with the given
    # parameters (based on net::IMAP search) or the timeout is reached.  This also
    # deletes the email from the inbox if the delete flag is set to true.
    # Returns the email text.
    #
    # search_array is an array of strings that need to be formatted according to the following convention from Net::IMAP.
    # These strings will be used to send a SEARCH command to search the mailbox for messages that match the given
    # searching criteria:
    #   BEFORE <date>: messages with an internal date strictly before <date>. The date argument has a format similar
    #     to 8-Aug-2002.
    #   BODY <string>: messages that contain <string> within their body.
    #   CC <string>: messages containing <string> in their CC field.
    #   FROM <string>: messages that contain <string> in their FROM field.
    #   NEW: messages with the Recent, but not the Seen, flag set.
    #   NOT <search-key>: negate the following search key.
    #   OR <search-key> <search-key>: "or" two search keys together.
    #   ON <date>: messages with an internal date exactly equal to <date>, which has a format similar to 8-Aug-2002.
    #   SINCE <date>: messages with an internal date on or after <date>.
    #   SUBJECT <string>: messages with <string> in their subject.
    #   TO <string>: messages with <string> in their TO field.
    #
    #   For example:
    #     get_email_text(["SUBJECT", "hello", "NOT", "NEW"])
    #     => finds emails with the subject "hello" which are not "NEW" (see definition of NEW)
    #
    #   See also: http://tools.ietf.org/html/rfc3501#section-6.4.4
    #
    def get_email_text(search_array, timeout=600, delete=true, since_sec=3600)
      # Only look for emails that have come in since the last hour
      since             = Time.now - since_sec
      imap_search_terms = search_array.dup.push("SINCE", since.strftime('%d-%b-%Y'))
      @log.debug("Searching for email with query: #{imap_search_terms}")

      super imap_search_terms, timeout, delete, since_sec
    end

    def send_email(to, opts={})
      opts[:from]       ||= 'qa@convio.com'
      opts[:from_alias] ||= 'Watirmark Email'
      opts[:subject]    ||= "test"
      opts[:body]       ||= "Watirmark Email test message"

      smtp = Net::SMTP.new 'smtp.gmail.com', 587
      smtp.enable_starttls

      msg = <<END_OF_MESSAGE
From: #{opts[:from_alias]} <#{opts[:from]}>
To: <#{to}>
Subject: #{opts[:subject]}

      #{opts[:body]}
END_OF_MESSAGE

      response = smtp.start('smtp.gmail.com', @email, @password, :plain) do |smpt|
        smtp.send_message msg, opts[:from], to
      end

      if response && response.status == "250"
        return true
      else
        return false
      end
    end
  end
end