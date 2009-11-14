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

require 'rubygems'
require 'net/http'
require 'icalendar'

# Patchin some stuff into DateTime for manipulating month value
class DateTime
  def add_months(months)
    old = self
    year = old.strftime('%Y').to_i
    month = old.strftime('%m').to_i
    day = old.strftime('%d').to_i

    olddiff = DateTime.parse("#{year}-#{month}-#{day}")
    newdiff = nil

    month = month + months

    while newdiff.nil?
      begin
        while month > 12
          year = year + 1
          month = month - 12
        end

        newdiff = DateTime.parse("#{year}-#{month}-#{day}")
      rescue ArgumentError
        day = 1
        month = month + 1
      end
    end
    old + (newdiff - olddiff).to_i
  end
end

# URL of your calendar (Might source this out into config or command line...)
calurl = 'http://www.google.com/calendar/ical/[...here goes some weird characters...]/basic.ics'

# Get the contents of this calendar and parse this.
cal = Icalendar.parse(Net::HTTP.get_response(URI.parse(calurl)).body)

# Magical stuff ;)
geburtstage = []

cal.first.events.each do |event|
  # Transform the damn start date into a date of this year (We don't have 1950!)
  nextdate = DateTime.parse("#{DateTime.now.strftime('%Y')}-#{event.dtstart.strftime('%m-%d')}")
  # If the birthday has happened this year already, move it to next year
  nextdate = nextdate.add_months(12) if nextdate < DateTime.now
  # Store it
  geburtstage << { :date => nextdate, :titel => event.summary }
end

# Get it into order
geburtstage.sort!{ |a,b| a[:date] <=> b[:date] }

# Print out the birthdays
geburtstage[0..5].each do |event|
  puts "#{event[:date].strftime('%d.%m.%Y')}: #{event[:titel]}"
end

# And that's just everything this script ever was intended to do.
# If you need more than this: Write it!
