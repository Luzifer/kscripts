#!/usr/bin/ruby

####
# iUseThis_Cleaner v.0.1 (c) 2008 by Knut Ahlers
# WWW: http://blog.knut.me - Mail: knut@ahlers.me
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

require 'net/http'
require 'rexml/document'

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

puts "Welcome to iUseThis_cleaner v.0.1"

print "- What is your username for iUseThis_Profiler: "
user = gets.chomp
print "- And what is your password for this account: "
pass = gets.chomp

#########################################################################################

puts "- Getting your used apps"

uri = URI.parse("http://osx.iusethis.com/user_opml/#{user}")
res = Net::HTTP.get_response(uri)
opml = REXML::Document.new(res.body)
send_apps = []

opml.elements.each('//outline') do |ol|
  url = ol.attributes['xmlUrl']
  next if url.nil?
  send_apps << url[url.rindex('/')+1..url.length]
end

#########################################################################################

puts "- Sending data to iusethis.com"

send_apps.each do |app|
  # For each app or widget which has been found and is still in the list
  # send it once to the api service.
  url = "http://osx.iusethis.com/api/stopusing/" + app
  print "  + Removing '#{app}'... "
  
  result = get_post_response url, user, pass
  
  # Analyse the result passed by the api
  case result
  when Net::HTTPSuccess
    puts "done."
  else
    if result.nil?
      puts 'Redirect limit exceeded.'
      next
    end
    puts "failed. Reason: #{result.message}"
  end
  
end

#########################################################################################

puts "We are done. All apps should be cleaned now if there was no error above."