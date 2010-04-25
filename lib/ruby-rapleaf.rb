require 'base64'
require 'cgi'
require 'openssl'
require 'digest/sha1'
require 'net/http'
require 'builder'
require 'ostruct'

library_files = Dir[File.join(File.dirname(__FILE__), "/rapleaf/**/*.rb")]
library_files.each do |file|
  require file.gsub(/\.rb$/, "")
end

module Rapleaf

  VERSION = '0.1.7'

  # API Constants
  API_HOST = 'api.rapleaf.com'
  API_PORT = 80
  API_VERSION = 'v3'

end

