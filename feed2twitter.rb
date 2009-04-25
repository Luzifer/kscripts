#!/usr/bin/ruby

# Use this to configure the application
config = {
  :feed => "http://url/to/my/feed/",              # URL of the feed
  :statefile => "/tmp/feed2twitter.state",        # Persistent file storage
  :feedtitle => "Something to prepend the title", # Any text (look for the length!)
  :twitter_user => "someaccount",                 # Your Twitter account
  :twitter_pass => "andthepassword"               # The password for the account
}

### Keep your fingers off the code below if you don't know about ruby ###

require 'rexml/document'
require 'net/http'
require 'date'

# Post the state to twitter
def tweetpost(tweet, config)
  Net::HTTP.start('twitter.com') do |http|
    req = Net::HTTP::Post.new('/statuses/update.xml')
    req.basic_auth config[:twitter_user], config[:twitter_pass]
    req.set_form_data({'status' => tweet})
    res = http.request(req).body
  end
end

# Shorten the url of the post because twitter needs short content
def shortenurl(url)
  Net::HTTP.get_response(URI.parse("http://kuerz.es/api.rb?action=create&url=#{url}")).body.strip
end

# Read the contents of the feed and generate a document of it
body = Net::HTTP.get_response(URI.parse(config[:feed])).body
doc = REXML::Document.new body

# Look up the last twittered post or assume there was no one
if !File.exists? config[:statefile]
  lastdate = DateTime.parse('1900-01-01 00:00')
else
  lastdate = DateTime.parse(File.read(config[:statefile]))
end

entries = []

# For each item in channel in rss parse it
doc.elements.each('rss/channel/item') do |item|
  # We want the post title
  title = item.elements['title'].text
  # The post date
  date = DateTime.parse(item.elements['pubDate'].text)
  # The link
  link = item.elements['link'].text
  # And add it to the entries array for sorting
  entries << {:date => date, :title => title, :link => link}
end

# Sort the array by date
entries.sort! { |a,b| a[:date] <=> b[:date] }

entries.each do |entry|
  # If the post was created later than the last post
  if entry[:date] > lastdate
    # Shorten the url
    surl = shortenurl(entry[:link])
    # Assemble the tweet and send it to twitter
    tweetpost("#{config[:feedtitle]} - #{entry[:date].strftime('%d.%m.%Y %H:%M')} #{entry[:title]} - #{surl}", config)
    # And remember the date.
    lastdate = entry[:date]
  end
end

# Remove the old state file if there was one
File.delete config[:statefile] if File.exists? config[:statefile]

# Write the new state to the file
File.open(config[:statefile], 'w') do |file|
  file.write lastdate.to_s
end

# And quit :D
