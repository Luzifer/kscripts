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

line = `df | grep "disk0s2" | xargs`

parts = line.split(' ')

size = parts[1].to_i * 512
used = parts[2].to_i * 512

puts "HDD:    #{((size - used).to_f / size.to_f * 100).to_i.to_s.rjust(3, ' ')}% Frei       (#{transform_byte(size - used)} / #{transform_byte(size)})"

