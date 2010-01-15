#!/usr/bin/ruby

# Copyright (c) 2010 Knut Ahlers
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

require 'rubygems'
require 'net/http'
require 'json'

# Please don't change anything here. Everything is changeable
# trough commandline parameters! Use them and keep this.
settings = {
  :user => '',
  :pass => '',
  :includesent => false,
  :deleteall => false,
  :usernames => []
}

# Print the help-message for the script
def help
  puts "Usage: ./#{$0} -u username -p password [-sent] [-killall] [username, ...]"
  puts "  -u username         Specify your twitter username"
  puts "  -p password         Specify your twitter password"
  puts "  -sent               Include the sent DMs (optional)"
  puts "  -killall            Deletes ALL DMs (there is no undo!) (optional)"
  puts "  username            Delete all DMs from this username (optional)"
end

# Validate the settings to check whether this could work
def checkvalidsettings(settings)
  return false if settings[:user] == '' or settings[:pass] == ''
  return false if settings[:deleteall] == false and settings[:usernames].count == 0
  true
end

# Query the DMs from Twitter
def get_dms(settings, page, sent = false)
  site = "/direct_messages.json?count=200&page=#{page}"
  site = "/direct_messages/sent.json?count=200&page=#{page}" if sent
  
  res = Net::HTTP.start('twitter.com') {|http|
    req = Net::HTTP::Get.new(site)
    req.basic_auth settings[:user], settings[:pass]
    response = http.request(req)
    response.body
  }
  JSON.parse(res)
end

# Tell twitter to destroy the message
def delete_dm(settings, dmid)
  Net::HTTP.start('twitter.com') {|http|
    req = Net::HTTP::Post.new("/direct_messages/destroy/#{dmid}.json")
    req.basic_auth settings[:user], settings[:pass]
    response = http.request(req)
    response.body
  }
end

# Parse the commandline args
while ARGV.count > 0 do
  arg = ARGV.shift
  
  case arg
  when '-u' then
    settings[:user] = ARGV.shift
    next
  when '-p' then
    settings[:pass] = ARGV.shift
    next
  when '-sent' then
    settings[:includesent] = true
    next
  when '-killall' then
    settings[:deleteall] = true
    next
  else
    settings[:usernames] << arg
  end
  
end

# If the settings are not usable print help and quit
if not checkvalidsettings settings
  help
  exit
end

# Fetch the received dms and parse them
page = 1
while true
  puts "Fetching page #{page} of your DMs..."
  begin
    dms = get_dms(settings, page)
  rescue
    puts "Twitter is not responding in expected format. (Failwhale?)"
    exit
  end
  break if dms.count == 0
  puts "Received #{dms.count} Messages..."
  
  # If there is a error-message: Tell it and quit
  if dms.include? 'error'
    puts "Got an error from twitter:"
    puts "  #{dms['error']}"
    puts "Will quit now."
    exit
  end
  
  dms.each do |dm|
    if settings[:usernames].include?(dm['sender_screen_name']) or settings[:deleteall]
      puts "Deleting DM #{dm['id']} from #{dm['sender_screen_name']}..."
      delete_dm(settings, dm['id']) 
    end
  end
  
  page = page + 1
end

# Do the same for the sent dms if enabled in settings
if settings[:includesent]
  page = 1
  while true
    puts "Fetching page #{page} of your sent DMs..."
    begin
      dms = get_dms(settings, page, true)
    rescue
      puts "Twitter is not responding in expected format. (Failwhale?)"
      exit
    end
    break if dms.count == 0
    puts "Received #{dms.count} Messages..."
  
    if dms.include? 'error'
      puts "Got an error from twitter:"
      puts "  #{dms['error']}"
      puts "Will quit now."
      exit
    end
  
    dms.each do |dm|
      if settings[:usernames].include?(dm['recipient_screen_name']) or settings[:deleteall]
        puts "Deleting DM #{dm['id']} to #{dm['recipient_screen_name']}..."
        delete_dm(settings, dm['id']) 
      end
    end
  
    page = page + 1
  end
end

# Get out here.
puts "No more DMs to fetch. Quit."