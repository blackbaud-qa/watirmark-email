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
        imap      = connect
        email_id  = imap.search(search_array).last
        email_uid = imap.fetch(email_id, 'UID').last.attr['UID']
        raise "Original message not found to copy!" unless email_uid
        imap.uid_copy(email_uid, destination_folder)
      ensure
        disconnect(imap)
      end
    end

    def get_email_text(search_array, timeout=600, delete=true, since_sec=3600)
      # Trying super ugly workaraound for the gmail 'Too many simlutaneous connections' error.
      # Just trying to login to gmail and if it fails try to wait until other connections
      # are closed and try again.
      email_text    = nil
      email_subject = nil
      email_uid     = nil

      ::Timeout.timeout(timeout) do
        @log.debug("start Timeout block for #{timeout} seconds")
        loop do
          begin
            imap = connect
            msgs = imap.search(search_array)
            if (msgs && msgs.length > 0)
              email_id      = msgs.last
              email_uid     = imap.fetch(email_id, 'UID').last.attr['UID']
              email_text    = imap.uid_fetch(email_uid, 'BODY[TEXT]').last.attr['BODY[TEXT]']
              envelope      = imap.uid_fetch(email_uid, 'ENVELOPE').last.attr['ENVELOPE']
              email_subject = envelope.subject
            end
          rescue => e
            @log.info("Error connecting to IMAP: #{e.message}")
          ensure
            if (delete && email_uid)
              @log.info("Deleting the email message #{email_subject}")
              delete(email_uid, imap)
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
end





