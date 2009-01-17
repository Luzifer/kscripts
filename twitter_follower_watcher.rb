#!/usr/bin/ruby

####
#
# TwitterFollowerWatcher v.0.1 (c) 2009 by Knut Ahlers
# WWW: http://blog.knut.me - Mail: knut@ahlers.me
#
####
#
# This script is intended to be used to watch followers and friends
# in a Twitter account come and go. I use it as a cronjob in a nightly
# hour to generate a daily report about the users in my account.
#
# You will require the 'sequel' gem and if you want to use a sqlite
# database you have to install 'sqlite-ruby' too.
#
####
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
####


require 'net/http'
require 'net/smtp'
require 'rexml/document'
require 'date'
require 'rubygems'
require 'sequel'

###################################################################################

database = "sqlite://twitstate.db"        # Connectionstring to the database to use
twitteruser = 'someuser'                  # Twitter username
twitterpass = 'somepass'                  # Twitter password
MAILSRV = "example.com"                   # SMTP-Server to use
MAILUSER = "anotheruser"                  # Username for SMTP-login
MAILPASS = "anotherpass"                  # Password for SMTP-login
MAILFROM = "me@theworld.com"              # Sender of the mail
MAILTO = MAILFROM                         # Receiver of the mail
MAILSUBJECT = "Twitter Follower Overview" # Subject of the mail

###################################################################################
# PLEASE DO NOT EDIT ANYTHING BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING! #
###################################################################################

DB = Sequel.connect database

###################################################################################

# Migration to create the tables into the database if missing

class DBCreator < Sequel::Migration
  def up
    create_table :friends do
      integer :uid
      varchar :screenname
      integer :following
    end
    create_table :followers do
      integer :uid
      varchar :screenname
      integer :following
    end
  end
  
  def down
    drop_table :friends
    drop_table :followers
  end
end

if !DB.table_exists? :followers
  DBCreator.apply DB, :up
end

###################################################################################

# Will request the required information from the twitter account
def get_document(url, user, pass)
  uri = URI.parse(url)
  xml = Net::HTTP.start(uri.host) do |http|
    target = uri.path
    target << "?" << uri.query if !uri.query.nil?
    req = Net::HTTP::Get.new(target)
    req.basic_auth user, pass
    http.request(req).body
  end
  REXML::Document.new(xml)
end

###################################################################################

# Sleep until there are enough api requests again
doc = get_document "http://twitter.com/account/rate_limit_status.xml", 
      twitteruser, twitterpass
if doc.elements['hash/remaining-hits'].text.to_i < 1
  sleep ((DateTime.parse(doc.elements['hash/reset-time'].text) - DateTime.now).to_f * 86400).to_i + 10
end

###################################################################################

# Get the number of followers and friends for the calculation of required
# pages which has to be retrieved from twitter
doc = get_document "http://twitter.com/users/show/#{twitteruser}.xml", 
      twitteruser, twitterpass
followercount = doc.elements['user/followers_count'].text.to_i
friendscount = doc.elements['user/friends_count'].text.to_i

# Set all currently known followers and friends to inactive
DB[:friends].update(:following => 0)
DB[:followers].update(:following => 0)

###################################################################################

# Prepare the mailtext
mailtext = []
mailtext << "TwitterFollower-Auswerung vom #{DateTime.now.strftime('%Y-%m-%d %H:%M')}"
mailtext << ""

###################################################################################

# Request the pages with followers to set them as active or add them to the database
mailtext << "Followers:"
page = 1
while followercount > 0
  doc = get_document "http://twitter.com/statuses/followers/#{twitteruser}.xml?page=#{page}", twitteruser, twitterpass
  doc.elements.each('users/user') do |elem|
    if DB[:followers].filter(:uid => elem.elements['id'].text.to_i).count > 0
      # Update
      DB[:followers].filter(:uid => elem.elements['id'].text.to_i).update(:following => 1)
    else
      DB[:followers] << {:uid => elem.elements['id'].text.to_i, :screenname => elem.elements['screen_name'].text, :following => 1}
      mailtext << "+ New follower: #{elem.elements['screen_name'].text} (#{elem.elements['name'].text})"
    end
    followercount -= 1
  end
  page += 1
end

# Put a line to the mailtext for each follower which has been lost
DB[:followers].filter(:following => 0).each do |row|
  mailtext << "- Lost follower: #{row[:screenname]}"
end

# Delete the followers who are not longer following the account
DB[:followers].filter(:following => 0).delete

###################################################################################

# Request the pages with friends to set them as active or add them to the database
mailtext << ""
mailtext << "Friends:"
page = 1
while friendscount > 0
  doc = get_document "http://twitter.com/statuses/friends/#{twitteruser}.xml?page=#{page}", twitteruser, twitterpass
  doc.elements.each('users/user') do |elem|
    if DB[:friends].filter(:uid => elem.elements['id'].text.to_i).count > 0
      # Update
      DB[:friends].filter(:uid => elem.elements['id'].text.to_i).update(:following => 1)
    else
      DB[:friends] << {:uid => elem.elements['id'].text.to_i, :screenname => elem.elements['screen_name'].text, :following => 1}
      mailtext << "+ New friend: #{elem.elements['screen_name'].text} (#{elem.elements['name'].text})"
    end
    friendscount -= 1
  end
  page += 1
end

# Put a line to the mailtext for each friend which has been unfollowed
DB[:friends].filter(:following => 0).each do |row|
  mailtext << "- Lost friend: #{row[:screenname]}"
end

# Delete the friends which were removed by the account
DB[:friends].filter(:following => 0).delete

###################################################################################

# Assemble the mailbody to sent via SMTP
mailbody = <<DATA
From: #{MAILFROM}
To: #{MAILTO}
Subject: #{MAILSUBJECT}

#{mailtext.join("\n")}
DATA

# Open a SMTP connection with authentication to send the message
begin 
  Net::SMTP.start(MAILSRV, 25, MAILSRV, MAILUSER, MAILPASS, :plain) do |smtp|
     smtp.sendmail(mailbody, MAILFROM,
                          [MAILTO])
  end
rescue Exception => e  
  print "Exception occured: " + e  
end

###################################################################################

