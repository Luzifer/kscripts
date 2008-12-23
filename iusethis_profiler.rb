#!/usr/bin/ruby

####
# iUseThis_profiler v.0.1 (c) 2008 by Knut Ahlers
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

user = 'your username to log you in' # Your iusethis-Username
pass = 'you should enter your own password'  # The corresponding password

#########################################################################################
### PLEASE DO NOT MAKE ANY CHANGES BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING ###
#########################################################################################

require 'find'
require 'net/http'

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
    apps << make_short(f[f.rindex('/')+1..f.length].gsub(extension, '')) if !/.*#{extension}$/.match(f).nil? 
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

puts "Welcome to iUseThis_profiler v.0.1"
puts "- Collecting paths..."

paths = []
paths << File.expand_path('~/Applications/')
paths << File.expand_path('/Applications/')
paths << File.expand_path('~/Library/Widgets')

#########################################################################################

puts "- Collecting apps and widgets (This may need a little time. Please be patient!)"

installed_apps = []
paths.each do |path| 
  # For each path execute the search and add the apps and widgets to the array
  puts "  + Searching '#{path}'..."
  
  search_apps(path, '.wdgt').each do |app|
    installed_apps << app if !app.nil?
  end
  search_apps(path, '.app').each do |app|
    installed_apps << app if !app.nil?
  end
end

#########################################################################################

puts "- Sending data to iusethis.com"

installed_apps.uniq.each do |app|
  # For each app or widget which has been found send it once to the api service.
  url = "http://osx.iusethis.com/api/iusethis/" + app
  print "  + Sending '#{app}'... "
  
  result = get_post_response url, user, pass
  
  # Analyse the result passed by the api
  case result
  when Net::HTTPSuccess
    puts "done. (#{result.body} other people use this too.)"
  else
    if result.nil?
      puts 'Redirect limit exceeded.'
      next
    end
    puts "failed. Reason: #{result.code} - #{result.message}"
  end
  
end

#########################################################################################

puts "We are done. All available apps should be online now if there was no error above."
puts "Have fun! (And don't forget to clean up your profile. I posted every app ;) )"