#!/usr/bin/ruby

require 'net/http'
require 'cgi'
require 'date'

@maxlinelength = 0
@debug = false

### Print the status line and make sure there is nothing left from the last line
def print_line(line)
  @maxlinelength = line.length if line.length > @maxlinelength
  print line.ljust(@maxlinelength) << "\r"
  $stdout.flush
end

### Fetch the size of an url
def fetch_filesize(url)
  uri = URI.parse(url)
  header = {
    'User-Agent' => "A tiny script in ruby to analyse your videos :) - But don't worry a user is also there.",
  }
  
  h = Net::HTTP.new uri.host, uri.port
  getfile = uri.path
  getfile << '?' << uri.query if not uri.query.nil?
  res = h.request_head(getfile, header)
  # If this is only a redirect follow it
  return fetch_filesize(res['location']) if res.key? 'location'
  res.content_length
end

### Doing everything to fetch the video to the HDD (Don't look at this if you are easyly confusable.)
def download_file(url, filename, start = 0) 
  # Define some default values
  uri = URI.parse(url)
  len = start
  size = start
  perc = 0
  header = {
    'User-Agent' => "A tiny script in ruby to fetch your videos :) - But don't worry a user is also there.",
  }
  header['Range'] = "bytes=#{start}-" if start > 0
  start = DateTime.now.strftime('%s').to_i
  begin
    # Open the target file
    File.open(filename, 'a') do |file|
      # Start the download
      h = Net::HTTP.new uri.host, uri.port
      getfile = uri.path
      getfile << '?' << uri.query if not uri.query.nil?
      h.request_get(getfile, header) do |r| 
        # If there is a redirect header follow it and continue downloading there
        return download_file(r['location'], filename) if r.key? 'location'
        # Read the download size
        len = len + r.content_length if not r.content_length.nil?
        r.read_body do |s| 
          # Write the downloded part to the file
          file.write s if not /2[0-9][0-9]/.match(r.code).nil?
          file.flush
          # Calculate downloaded size
          size = size + s.length
          len = size if r.content_length.nil?
          # Do some calculations for the nice status line
          perc = (size.to_f / len.to_f * 100).to_i if len > 0
          lines = (perc / 4).to_i
          timegone = DateTime.now.strftime('%s').to_i - start
          bps = size.to_f / timegone.to_f
          sleft = ((len - size).to_f / bps).to_i 
          print_line "DL: #{filename} - [#{'=' * lines}#{' ' * (25 - lines)}] #{perc}% (#{transform_byte(size)} / #{transform_byte(len)}) ETA: #{transform_secs(sleft)}"
        end 
      end
    end
  rescue Exception => ex
    if @debug
      print_line "\a\a\a" << ex.message
      sleep 2
    end
    if ex.message.include? 'Interupt'
      print_line "You interupted me. Skipping this file..."
      return
    end
    # Something went wrong? Simply try again... (Hope the user want this to...)
    print_line "Connection failture. Trying again..."
    return download_file(url, filename, size) 
  end
  # Finished but did not got everything? Should not happen. Try to get the rest
  if size < len
    return download_file(url, filename, size)
  end
  # Tell the user that we are done :)
  print_line "Completed. See your file at #{filename}"
  puts
end

# Transforms the float number to something with max. 2 digits after the colon
def two_digits(number)
  (number * 100.0).to_i.to_f / 100.0
end

# No one wants to read 123secs so tell them what this is in human readable time
def transform_secs(seconds) 
  time = ''
  
  h = (seconds.to_f / 3600.0).floor
  seconds = seconds - (h * 3600)
  time << "#{h.to_s.rjust(2, '0')}:" if h > 0
  
  m = (seconds.to_f / 60.0).floor
  seconds = seconds - (m * 60)
  time << "#{m.to_s.rjust(2, '0')}:"
  
  time << "#{seconds.to_s.rjust(2, '0')}"
  
  time
end

# Transform amount of bytes in human-readable format
def transform_byte(byte) 
  byte = byte.to_f
  return two_digits(byte / 1073741824).to_s << " GB" if byte > 1073741824
  return two_digits(byte / 1048576).to_s << " MB" if byte > 1048576
  return two_digits(byte / 1024).to_s << " KB" if byte > 1024
  return two_digits(byte).to_s << " B"
end

# Check if we have something to do...
if ARGV.length < 1
  puts "Please pass some YouTube-URLs (at least one) to my commandline. So type something like this:"
  puts "#{$0} http://www.youtube.com/watch?v=blabla http://www.youtube.com/watch?v=whatever http://www.youtube.com/watch?v=another"
  exit
end

# The user gave some url to us...
ARGV.each do |youtubeurl|
  # Don't pay attention to this!
  if youtubeurl == '-d'
    @debug = true
    next
  end

  # Comfirm it.
  print_line "Will fetch from youtube video #{youtubeurl}..."

  # Get the source of the youtube-page (Use the source Luke...)
  source = Net::HTTP.get_response(URI.parse(youtubeurl)).body
  # Get the stuff from the javascript-flash-builder
  match_video = /"fmt_url_map": "([^"]*)"/.match(source)
  # Get the title to name the file. (zlhgPnB9C8c is a silly name!)
  match_title = /<title>(.*)<\/title>/.match(source)

  # Something is nil? So there is no video or title? Stupid YouTube (or user...)
  if match_video.nil? or match_title.nil?
    print_line "Unable to fetch #{youtubeurl} - There is no video o_O"
    puts 
  end

  # Check all the sizes of the urls to get the biggest. (This really should be the HD-quality)
  videourl = ''
  videosize = 0
  CGI.unescape(match_video[1]).split('|').each do |url|
    next if not url.include? 'http://'
    target = url.split(',')[0]
    size = fetch_filesize(target)
    if size > videosize
      videourl = target
      videosize = size
    end
  end

  # Filesystems does not like special characters so build a saveable filename
  filename = match_title[1].gsub(/[< >:"\/\\|?*,.]/, '_') << '.flv'

  # If there is something downloaded we try to continue
  start = 0
  start = File.size filename if File.exists?(filename)

  # Finally go to get the stuff!
  download_file(videourl, filename, start)

end

# Nothing more code here :) You wanted to go outside to play didn't you?
