require 'sinatra/base'
require 'openssl'

def hash_hmac(digest, key, data)
  d = OpenSSL::Digest.new(digest)
  OpenSSL::HMAC.hexdigest(d, key, data)
end

def SENT_MESSAGE_STORE_PATH(data)
  OpenSSL::Digest::SHA256.new(data)
end
