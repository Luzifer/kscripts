#!/usr/bin/ruby

####
# iUseThis_profiler v.0.5 (c) 2008 by Knut Ahlers
# WWW: http://blog.knut.me - Mail: knut@ahlers.me
#
# Thanks to Andrew Turner for his improvements to ask the user which
# applications to send to iUseThis.
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
####

#########################################################################################
### PLEASE DO NOT MAKE ANY CHANGES BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING ###
#########################################################################################

require 'find'
require 'net/http'
require 'rexml/document'

#########################################################################################

# Creates the shortname needed by the iusethis api
def make_short(program_name)
  program_name.gsub(/[^\w\@\-]/, '').downcase!
end

#########################################################################################

# Retrieves all files in path matching *extension
def search_apps(path, extension)
  apps = []

  Find.find(path) do |f|
    if !/.*#{extension}$/.match(f).nil?
      apps << make_short(f[f.rindex('/')+1..f.length].gsub(extension, ''))
    end
    Find.prune if FileTest.directory? f and f.include?(".")
  end
  
  apps
end

#########################################################################################

# Posts the data to iusethis and passes the results back (If there is a redirection it
# is followed until redirect level 10 or reaching the target)
def get_post_response(url, user, pass, level = 0)
  # If there were too many redirections break
  return nil if level == 10
  
  uri = URI.parse(url)
  
  result = Net::HTTP.start(uri.host, uri.port) do |http|
    post = Net::HTTP::Post.new(uri.path)
    post.basic_auth user, pass
    post.set_form_data({})
    http.request(post)
  end
  
  case result
  when Net::HTTPRedirection 
    return get_post_response(result['location'], user, pass, level + 1)
  else 
    return result
  end
  
end

#########################################################################################


def resolve_message(result)
  case result.code.to_i
  when 404
    return 'Application not found'
  when 409
    return 'Application is already in your profile'
  else
    return "Can't add this application"
  end
end

#########################################################################################

puts "Welcome to iUseThis_profiler v.0.5"

print "- What is your username for iUseThis_Profiler: "
user = gets.chomp
print "- And what is your password for this account: "
pass = gets.chomp

#########################################################################################

puts "- Collecting paths..."

paths = []
paths << File.expand_path('~/Applications/')
paths << File.expand_path('/Applications/')

paths << File.expand_path('~/Library/Widgets')
paths << File.expand_path('/Library/Widgets')

paths << File.expand_path('~/Library/PreferencePanes')
paths << File.expand_path('/Library/PreferencePanes')

#########################################################################################

puts "- Collecting apps and widgets (This may need a little time. Please be patient!)"

installed_apps = []
paths.each do |path| 
  # For each path execute the search and add the apps and widgets to the array
  puts "  + Searching '#{path}'..."
  
  ['.wdgt', '.app', '.prefPane'].each do |extension|
    search_apps(path, extension).each do |app|
      installed_apps << app if !app.nil?
    end
  end
end

installed_apps.sort!.uniq!

puts "  + Found #{installed_apps.length.to_s} applications."

#########################################################################################

puts "- Check which applications to send..."

puts "  + Getting already added applications..."
added_apps = []

uri = URI.parse("http://osx.iusethis.com/user_opml/#{user}")
res = Net::HTTP.get_response(uri)
opml = REXML::Document.new(res.body)

opml.elements.each('//outline') do |ol|
  url = ol.attributes['xmlUrl']
  next if url.nil?
  added_apps << url[url.rindex('/')+1..url.length]
end

opml.elements.each('//Aliases') do |al|
  url = al.text
  next if url.nil?
  added_apps << url[url.rindex('/')+1..url.length]
end

#########################################################################################

send_apps = []

# Ask the user whether he wants to upload this app to iUseThis, if not
# delete it from the list.
installed_apps.each do |app|
  count = "(#{(installed_apps.index(app) + 1).to_s.rjust(3)} / #{installed_apps.length.to_s.rjust(3)})"
  print "  + #{count} Upload application '#{app}' to iusethis? (Y/n/a) "
  
  if added_apps.include? app
    puts "n (Already added.)"
  else
    input = gets.chomp
    if input =~ /a/
      send_apps << installed_apps
      send_apps.flatten!
      break
    end
    (input =~ /n/) ? nil : send_apps.push(app)
  end
end

#########################################################################################

puts "- Sending data to iusethis.com"

send_apps.each do |app|
  # For each app or widget which has been found and is still in the list
  # send it once to the api service.
  url = "http://osx.iusethis.com/api/iusethis/" + app
  print "  + Sending '#{app}'... "
  
  result = get_post_response url, user, pass
  
  message = resolve_message result
  
  # Analyse the result passed by the api
  case result
  when Net::HTTPSuccess
    puts "done. (#{result.body} other people use this too.)"
  else
    if result.nil?
      puts 'Redirect limit exceeded.'
      next
    end
    puts "failed. Reason: #{message}"
  end
  
end

#########################################################################################

puts "We are done. All available apps should be online now if there was no error above."
puts "Have fun! (And don't forget to clean up your profile. I posted every app ;) )"