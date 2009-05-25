#!/usr/bin/ruby

# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <knut@ahlers.me> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a cola in return Knut Ahlers
# ----------------------------------------------------------------------------

# USAGE: ./getTraceResponse.rb "http://127.0.0.1/argadfg.html"

require 'uri'
require 'net/http'

url = ARGV[0]

uri = URI.parse(url)

response = Net::HTTP.start(uri.host, uri.port) do |http|
  http.trace(uri.path)
end

puts response.code
