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
      gather_email_data(search_array, timeout) { "return email_text" }
    end

    def get_email_replyto(search_array, timeout=600, delete=true)
      gather_email_data(search_array, timeout) { "return bad_things_reply_to" }
    end

    #returns the name of the email attachment
    #returns nil if there is no attachment
    def get_email_attachment(search_array, timeout=600)
      gather_email_data(search_array, timeout) { "return attachment_name" }
    end

    def get_email_attachment_file(search_array, timeout=600)
      gather_email_data(search_array, timeout) { "return attachment_file" }
    end

    private
    def gather_email_data(search_array, timeout)
      #define all of the variables we'd like to potentially return
      attachment_file = nil
      attachment_name = nil
      reply_to = nil
      email_text = nil

      finished = false
      ::Timeout.timeout(timeout) do
        @log.debug("start Timeout block for #{timeout} seconds")
        loop do
          begin
            imap = connect
            msgs = imap.search(search_array)
            if (msgs && msgs.length > 0)
              msgs.each do |msgID|
                msg = imap.fetch(msgID, ["ENVELOPE", "UID", "BODY"])[0]
                envelope = msg.attr['ENVELOPE']
                body = msg.attr["BODY"]

                if body.respond_to?('parts')
                  attachment_name = body.parts[1].param['NAME']
                  attachment_file = Base64.decode64(imap.fetch(msgID, "BODY[#{2}]")[0].attr["BODY[#{2}]"])
                end

                reply_to = "#{envelope.reply_to[0].name} <#{envelope.reply_to[0].mailbox}@#{envelope.reply_to[0].host}>"

                email_text = body

                finished = true
              end
            end
          rescue => e
            @log.info("Error connecting to IMAP: #{e.message}")
          ensure
            disconnect(imap) unless imap.nil? # because sometimes the timeout happens before imap is defined
          end
          break if finished
          @log.debug("Couldn't find email yet ... trying again")
          sleep 10
        end
      end
      eval yield
    end

  end
end