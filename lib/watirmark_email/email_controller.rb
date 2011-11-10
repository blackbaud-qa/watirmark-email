module WatirmarkEmail
  class BaseController
    # Connects using the credentials supplied on initialize, returns the IMAP object.  Most of the time, if all you want
    # is an email, you won't need to use this method as get_email_text handles connect for you.
    def connect
      imap = Net::IMAP.new(@url, @port, @ssl)
      imap.login(@email, @password)
      imap.select(@inbox)
      imap
    end

    # This is a test method to disconnect from the server.  get_email_text handles disconnect for you.
    def disconnect(imap)
      return true if imap.disconnected?
      imap.logout
      imap.disconnect
    end

    # This is a test method to copy an email to the inbox
    def copy(search_array, destination_folder=@inbox)
      begin
        @log.debug("copying to #{destination_folder}")
        imap = connect
        email_id = imap.search(search_array).last
        email_uid = imap.fetch(email_id, 'UID').last.attr['UID']
        raise "Original message not found to copy!" unless email_uid
        imap.uid_copy(email_uid, destination_folder)
      ensure
        disconnect(imap)
      end
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
      # Trying super ugly workaraound for the gmail 'Too many simlutaneous connections' error.
      # Just trying to login to gmail and if it fails try to wait until other connections
      # are closed and try again.
      email_text = nil
      email_subject = nil
      email_uid = nil

      ::Timeout.timeout(timeout) do
        @log.debug("start Timeout block for #{timeout} seconds")
        loop do
          begin
            imap = connect
            msgs = imap.search(search_array)
            if (msgs && msgs.length > 0)
              email_id = msgs.last
              email_uid = imap.fetch(email_id, 'UID').last.attr['UID']
              email_text = imap.uid_fetch(email_uid, 'BODY[TEXT]').last.attr['BODY[TEXT]']
              envelope = imap.uid_fetch(email_uid, 'ENVELOPE').last.attr['ENVELOPE']
              email_subject = envelope.subject
            end
          rescue => e
            @log.info("Error connecting to IMAP: #{e.message}")
          ensure
            if (delete && email_uid)
              @log.info("Deleting the email message #{email_subject}")
              # the next step only needs to be run if we are in gmail
              imap.uid_copy(email_uid, @trash)
              imap.uid_store(email_uid, "+FLAGS", [:Deleted])
            end
            disconnect(imap) unless imap.nil? # because sometimes the timeout happens before imap is defined
          end
          break if email_text
          @log.debug("Couldn't find email yet ... trying again")
          sleep 10
        end
      end
      email_text
    end
  end

  class Gmail < BaseController
    attr_accessor :inbox
    URL = "imap.gmail.com"
    PORT = 993
    MAILBOX_INBOX = "INBOX"
    MAILBOX_TRASH = "[Gmail]/Trash"
    MAILBOX_ALL = "[Gmail]/All Mail"

    # Constructor for this class.
    # This will initialize all variables according to the type email service this is using.
    def initialize(email, password, logLevel = ::Logger::INFO)
      @email = email
      @password = password
      @log = ::Logger.new STDOUT
      @log.level = logLevel
      @url = URL
      @port = PORT
      @inbox = MAILBOX_INBOX
      @trash = MAILBOX_TRASH
      @ssl = true # port 993
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
      since = Time.now - since_sec
      imap_search_terms = search_array.dup.push("SINCE", since.strftime('%d-%b-%Y'))
      @log.debug("Searching for email with query: #{imap_search_terms}")

      super imap_search_terms, timeout, delete, since_sec
    end

    def send_email(to, opts={})
      opts[:from] ||= 'qa@convio.com'
      opts[:from_alias] ||= 'Watirmark Email'
      opts[:subject] ||= "test"
      opts[:body] ||= "Watirmark Email test message"

      smtp = Net::SMTP.new 'smtp.gmail.com', 587
      smtp.enable_starttls

      msg = <<END_OF_MESSAGE
From: #{opts[:from_alias]} <#{opts[:from]}>
To: <#{to}>
Subject: #{opts[:subject]}

#{opts[:body]}
END_OF_MESSAGE

      response = smtp.start('smtp.gmail.com',@email,@password, :plain ) do |smpt|
        smtp.send_message msg, opts[:from], to
      end

      if response && response.status == "250"
        return true
      else
        return false
      end
    end

  end

  class QAMail < BaseController
    URL = "qasendmail.corp.convio.com"
    PORT = 143
    MAILBOX_INBOX = "Inbox"

    # Constructor for this class.
    # This will initialize all variables according to the type email service this is using.
    def initialize(account, password=nil, logLevel = ::Logger::INFO)
      @email = account
      @password ||= account
      @log = ::Logger.new STDOUT
      @log.level = logLevel
      @url = URL
      @port = PORT
      @inbox = MAILBOX_INBOX
      @ssl = false # port 143
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
      opts[:server] ||= 'qasendmail.corp.convio.com'
      opts[:from] ||= 'qa@convio.com'
      opts[:from_alias] ||= 'Watirmark Email'
      opts[:subject] ||= "test"
      opts[:body] ||= "Watirmark Email test message"

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
  end
end

