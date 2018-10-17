require 'sinatra/base'
require 'OpenSSL'

def hash_hmac(digest, key, data)
  d = OpenSSL::Digest.new(digest)
  OpenSSL::HMAC.hexdigest(d, key, data)
end

def sha256_digest(data)
  OpenSSL::Digest::SHA256.new(data)
end
