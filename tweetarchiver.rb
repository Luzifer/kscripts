#!/usr/bin/ruby

# Copyright (c) 2009 Knut Ahlers <knut@ahlers.me>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# ###############################################################################
#                               HOW TO INSTALL THIS                             
# To install this you set up a database or simply keep the default setting to use
# a sqlite-file database in the current directory named 'tweetdb.dat' and copy
# everything to a directory of your choice.
# 
# Now adjust the username and password to the credentials for the account you
# want to backup. Please also change file permissions for the script to 700 so
# no one can read your twitter password from the script.
# 
# To get this working you need to install two additional gems to ruby using this
# commands as super-user (root):
# - gem install json
# - gem install sequel
# 
# Additional keep sure to install the database extension you want to use. (By 
# default the sqlite3-extension.) After you've done this everything should work
# fine by executing the script.
# 
# Have fun using and modifying the script.
# 
# KThxBye Knut ;)
# ###############################################################################

require 'rubygems'
require 'net/http'
require 'json'
require 'sequel'

TUSER = '...'                     # Please insert your screen-name here
TPASS = '...'                     # Your password goes here.
DB = 'sqlite://tweetdb.dat'       # By default use a sqlite-database.
                                  # You could also set DB to 'mysql://user:password@host/database' 
                                  # to use a mysql database - For other options
                                  # please see Sequel manual. In your database
                                  # a table called "tweets" will be created.

# Retrieve user-timeline from twitter servers and parse response JSON
def get_page(pagenum = 1, minid = 1)
  http = Net::HTTP.new 'twitter.com', 80
  req = Net::HTTP::Get.new "/statuses/user_timeline.json?count=200&since_id=#{minid}&page=#{pagenum}"
  req.basic_auth TUSER, TPASS
  JSON.parse http.request(req).body
end

# Set up database if not already done
db = Sequel.connect DB
if not db.tables.include? :tweets
  db.create_table :tweets do
    varchar :tweet
    Time :datum
    integer :tweetid
  end
end

# Set some variables
pg = 0 # Start with page 0
minid = db[:tweets].max(:tweetid) # Use maximum tweet id from database
minid = 1 if minid.nil? # Use tweet id 1 if there is no tweet in database
contloop = true # Simple state variable
com = 0 # Variable to sum up stored tweets

puts "Starting at ID ##{minid}..."

while contloop
  
  pg = pg + 1 # Increase page number (This is why we start using page 0!!!)
  json = get_page pg, minid # Retrieve the tweets
  contloop = json.count > 0 # Continue after this if the page contained more than 0 tweets
  com = com + json.count # Calculate sum
  
  puts "Seite #{pg}: #{json.count} Tweets"
  
  print "Storing: "
  json.each do |tweet| # Throw the tweets into database
    date = DateTime.parse(tweet['created_at'])
    text = tweet['text']
    db[:tweets] << { :datum => date, :tweet => text, :tweetid => tweet['id'].to_s }
    print "."
  end
  puts
  
end

puts "Gesamt: #{com}"

db.disconnect # Say bye to database...

# Say bye to users and take the next dragon to data-nirvana ;)
