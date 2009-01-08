#!/usr/bin/python 

import sys
import os
from imaplib import IMAP4_SSL
import rfc822
from datetime import datetime
import md5
from subprocess import Popen

if (sys.argv.__len__() < 5):
	print "Usage: "+sys.argv[0]+" <server> <user> <passwd> <mailbox>"
	sys.exit(1)

# Connect to IMAP4 via SSL
server = IMAP4_SSL(sys.argv[1])

# Login to Server
code, msg = server.login(sys.argv[2], sys.argv[3])

# If login failed crash script
if not code=="OK":
	print "Login failed: %s"%msg[0]
	sys.exit(1)

# Select folder "INBOX" and retrieve number of messages
ret, num_msg = server.select(sys.argv[4])

# If INBOX isnt availiable look confused and crash
if not ret=="OK":
	print "Source mailbox not found"
	sys.exit(2)

num_msg = int(num_msg[0])

msg_idx=1

dir = 'MailArchive'+sys.argv[4].split('.')[-1:][0]

os.mkdir(dir)

for msg_idx in range(1, num_msg+1):
	ret, tmp = server.fetch(str(msg_idx), '(RFC822)')

	if tmp[0] is None:
		# retrieval of msg failed - this should be looked at
		# more closely, actually
		continue
	else:
		# retrieve the content of the mail (all headers and body)
		msg=tmp[0][1]
		
		filename = md5.md5(str(msg_idx)+msg).hexdigest()

		fd = open(dir+'/'+filename+'.txt', 'w')
		fd.write(msg)
		fd.close()

# Delete the mailbox because its not longer needed
server.select('INBOX')
server.unsubscribe(sys.argv[4])
server.delete(sys.argv[4])

# Create a tar file of the directory
tar = Popen(['tar', '-czf', dir+'.tgz', dir])
tar.wait()
# Now remove the directory
Popen(['rm', '-rf', dir])

# remove mails marked as deleted
server.expunge()
server.shutdown()
