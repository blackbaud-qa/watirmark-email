module WatirmarkEmail
  class QAMail < BaseController
    URL           = "qasendmail.corp.convio.com"
    PORT          = 143
    MAILBOX_INBOX = "Inbox"

    # Constructor for this class.
    # This will initialize all variables according to the type email service this is using.
    def initialize(account, password=nil, logLevel = ::Logger::INFO)
      @email     = account
      @password  = password || account
      @log       = ::Logger.new STDOUT
      @log.level = logLevel
      @url       = URL
      @port      = PORT
      @inbox     = MAILBOX_INBOX
      @ssl       = false # port 143
    end

    def delete(email_uid, imap)
      imap.uid_store(email_uid, "+FLAGS", [:Deleted])
      imap.expunge
    end

    # used for testing
    def delete_emails(search_terms, timeout = 60)
      uid_list = find_email_uids(search_terms, timeout)
      imap     = connect
      uid_list.each do |uid|
        imap.uid_store(uid, "+FLAGS", [:Deleted])
      end
      imap.expunge
      disconnect imap
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
    def get_email_text(search_array, timeout=600, delete=true)
      @log.debug("Searching for email with query: #{search_array}")

      super search_array, timeout, delete
    end

    def send_email(to, opts={})
      opts[:server]     ||= 'qasendmail.corp.convio.com'
      opts[:from]       ||= 'qa@convio.com'
      opts[:from_alias] ||= 'Watirmark Email'
      opts[:subject]    ||= "test"
      opts[:body]       ||= "Watirmark Email test message"

      msg = <<END_OF_MESSAGE
From: #{opts[:from_alias]} <#{opts[:from]}>
To: <#{to}>
Subject: #{opts[:subject]}

      #{opts[:body]}
END_OF_MESSAGE

      response = Net::SMTP.start(opts[:server]) do |smtp|
        smtp.send_message msg, opts[:from], to
      end

      if response && response.status == "250"
        return true
      else
        return false
      end
    end

    def find_emails(search_terms, timeout = 60)
      uids   = find_email_uids(search_terms, timeout)
      emails = WatirmarkEmail::EmailCollection.new

      ::Timeout.timeout(timeout) do
        @log.debug("start Timeout block for #{timeout} seconds")
        loop do
          begin
            imap      = connect
            fetchdata = imap.uid_fetch(uids, ["ENVELOPE", "BODY[TEXT]", "BODY[]", "UID"])
            emails.add_emails(fetchdata)
          rescue => e
            @log.info("#{e.class}: #{e.message}")
          ensure
            disconnect(imap) unless imap.nil? # because sometimes the timeout happens before imap is defined
          end
          break unless emails.empty?
          @log.debug("Couldn't find email yet ... trying again")
          sleep 10
        end
      end
      emails
    end

    def find_email_uids(search_terms, timeout = 60)
      email_uids = []

      ::Timeout.timeout(timeout) do
        @log.debug("start Timeout block for #{timeout} seconds")
        loop do
          begin
            imap = connect
            msgs = imap.search(search_terms)
            @log.debug("found message numbers: #{msgs}")
            if (msgs && msgs.length > 0)
              email_uids = msgs.inject([]) { |email_uids, email_id| email_uids << imap.fetch(email_id, 'UID').last.attr['UID'] }
            end
          rescue => e
            @log.info("Error connecting to IMAP: #{e.message}")
          ensure
            disconnect(imap) unless imap.nil? # because sometimes the timeout happens before imap is defined
          end
          break unless email_uids.empty?
          @log.debug("Couldn't find email yet ... trying again")
          sleep 10
        end
      end
      @log.debug("found UIDS: #{email_uids}}")
      email_uids
    end
  end
end
