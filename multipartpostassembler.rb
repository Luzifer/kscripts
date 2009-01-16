require 'rubygems'
require 'mime/types'

module Net
  module HTTP
    #   MultiPartPostAssember Ruby Library - Library to create a post request from
    #   some field definitions to send files as multipart/form-data
    #   Copyright (C) 2009  Knut Ahlers
    #   
    #   This program is free software; you can redistribute it and/or modify it under 
    #   the terms of the GNU General Public License as published by the Free Software 
    #   Foundation; either version 3 of the License, or (at your option) any later 
    #   version.
    #   
    #   This program is distributed in the hope that it will be useful, but WITHOUT 
    #   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
    #   FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
    #   
    #   You should have received a copy of the GNU General Public License along with 
    #   this program; if not, see <http://www.gnu.org/licenses/>.
    #
    # This library extends the Net::HTTP stdlib
    #
    # Depency: mime-types gem (gem install mime-types)
    class MultiPartPostAssembler
    
      # Creates a new MultiPartPostAssembler
      # Example:
      #   assembler = Net::HTTP::MultiPartPostAssembler.new
      #   fields = [
      #     {:key => "yourname", :value => "John"}, 
      #     {:key => "description", :value => "An image"}
      #   ]
      #
      #   files = [
      #     {:key => "media", :filename => "test.png"}
      #   ]
      #   
      #   request = assembler.create_post_request('/path/to/form/handler', fields, files)
      #   
      #   http = Net::HTTP.start('server.com', 80) do |http|
      #     http.request(request)
      #   end
      #
      def initialize
        @boundary = nil
      end
      
      # Assembles the field and file definitions to the post request
      # which can be send by a Net::HTTP-object to the server
      def create_post_request(path, fields, files)
        data = encode_fields(fields, files)
        request = Net::HTTP::Post.new(path)
        request.content_type = 'multipart/form-data; boundary=' + generate_boundary
        request.content_length = data.length
        request.body = data
    
        request
      end
  
      private
  
      def encode_fields(fields, files)
        lines = []
        fields.each do |field|
          lines << "--#{generate_boundary}"
          lines << "Content-Disposition: form-data; name=\"#{field[:key]}\""
          lines << ""
          lines << "#{field[:value]}"
        end
        files.each do |file|
          lines << "--#{generate_boundary}"
          lines << "Content-Disposition: form-data; name=\"#{file[:key]}\"; filename=\"#{file[:filename]}\""
          lines << "Content-Type: #{get_content_type(file[:filename])}"
          lines << ""
          lines << "#{File.read(file[:filename])}"
        end
        lines << "--#{generate_boundary}--"
        lines << ""
        data = lines.join("\r\n")
        data
      end
  
      # Determines the mime type for the file to submit
      def get_content_type(filename)
        MIME::Types.type_for(filename)
      end
      
      # Creates a single boundary
      def generate_boundary
        @boundary = "----KARubyMultiPartEncoder" + rand(1000000000).to_s + "bye" if @boundary.nil?
        @boundary
      end
  
    end
  end
end