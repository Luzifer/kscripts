#!/usr/bin/ruby

####
# Written by Knut Ahlers in 2009 (knut@ahlers.me)
#
# Simply take it and have fun with it. This is not really a license
# but I take no responsibilities for anything which happens while
# using this script. You don't have to thank me for it but it would
# be cool if you do.
####

# The configuration - You really should edit this!
config = {
  :sender_jid => "someone@jabber.org", # The JID of your XMPP-Logger
  :sender_pwd => "ididnotchangethefile", # The password for the JID above
  :receiver => "someother@jabber.org", # You
  :fifo => "/tmp/myfifo", # An available not existing FIFO
  :subject => "Test", # A subject for the messages (The servername or something)
  :type => :normal, # The type of the message
  :removefifo => false # Delete the fifo at the end
}

### Please keep your fingers off the code below or you will be blamed for mistakes! ###

# Load the libs
begin
  require 'rubygems'
  require 'xmpp4r/client'
rescue LoadError
  puts "This script requires the xmpp4r ruby gem. Please install it"
  exit
end

include Jabber

# Connect to the jabber server
cl = Client::new(JID::new(config[:sender_jid]))
cl.connect
cl.auth(config[:sender_pwd])

# If there is no fifo with this name create it
`mkfifo #{config[:fifo]}` if !File.exists? config[:fifo]

# Go and read something
File.open(config[:fifo], 'r') do |fifo|
  # While its there we have a job
  while File.exists? config[:fifo]
    begin
      # Spam the line to the receiver
      message = fifo.readline
      cl.send Message::new(config[:receiver], message).set_type(config[:type]).set_id(DateTime.now.strftime('%s')).set_subject(config[:subject])
    rescue EOFError
      # If there is no message wait a second and try again
      sleep 1
    end
  end
end

# Throw away the garbage if wanted
File.delete(config[:fifo]) if config[:removefifo]

# Shut down connection
cl.close

# And bye :D
