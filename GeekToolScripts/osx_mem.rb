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

# Transforms the float number to something with max. 2 digits after the colon
def two_digits(number)
  (number * 100.0).to_i.to_f / 100.0
end

# Transform amount of bytes in human-readable format
def transform_byte(byte) 
  byte = byte.to_f
  return two_digits(byte / 1073741824).to_s << " GB" if byte > 1073741824
  return two_digits(byte / 1048576).to_s << " MB" if byte > 1048576
  return two_digits(byte / 1024).to_s << " KB" if byte > 1024
  return two_digits(byte).to_s << " B"
end


memstat = `vm_stat`

values = {}
size = 0

memstat.split("\n").each do |line|
  # Page size:
  res = /page size of ([0-9]+) bytes/.match line
  if not res.nil?
    size = res[1].to_i
    next
  end
  
  # Values:
  tmp = line.split(':')
  values[tmp[0]] = tmp[1].to_i * size
end

mem_reserved = values["Pages wired down"]
mem_used = values["Pages active"]
mem_free = values["Pages free"] + values["Pages inactive"]
mem_complete = mem_used + mem_free + mem_reserved + values["Pages speculative"]

puts "Memory: #{(mem_free.to_f / (mem_complete).to_f * 100).to_i.to_s.rjust(3, ' ')}% Frei       (#{transform_byte(mem_free)} / #{transform_byte(mem_complete)})"
puts "        #{(mem_reserved.to_f / mem_complete.to_f * 100).to_i.to_s.rjust(3, ' ')}% Reserviert (#{transform_byte(mem_reserved)} / #{transform_byte(mem_complete)})"
puts "        #{(mem_used.to_f / (mem_complete).to_f * 100).to_i.to_s.rjust(3, ' ')}% Belegt     (#{transform_byte(mem_used)} / #{transform_byte(mem_complete)})"
