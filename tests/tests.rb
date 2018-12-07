ENV['RACK_ENV'] = 'test'
ENV['CALLBACK_URI_ROOT'] = 'http://localhost:9292'

DEFAULT_BID = 700000
TEST_FILE = "test.png"

require 'minitest/autorun'
require 'rack/test'
require 'json'
require_relative '../main'

class MainAppTest < Minitest::Test
  include Rack::Test::Methods 

  unless File.exists?(TEST_FILE)
    `curl -o #{TEST_FILE} https://raw.githubusercontent.com/scijs/baboon-image/master/baboon.png`
  end
 
  def app
    Sinatra::Application
  end
 
  def setup
    post '/order', params={"bid" => DEFAULT_BID, "file" => Rack::Test::UploadedFile.new(TEST_FILE, "image/png")}
    @order = JSON.parse(last_response.body)
    @order_uuid = @order['lightning_invoice']['metadata']['uuid']
  end  
  
  def write_response
    File.open('response.html', 'w') { |file| file.write(last_response.body) }    
  end

  def test_get_orders
    get '/orders'
    write_response
    assert last_response.ok?
  end

  def test_order_creation
    post '/order', params={"bid" => DEFAULT_BID, "file" => Rack::Test::UploadedFile.new(TEST_FILE, "image/png")}
    assert last_response.ok?
    r = JSON.parse(last_response.body)
    refute_nil r['auth_token']
    refute_nil r['uuid']
    refute_nil r['lightning_invoice']
  end
  
  def test_bid_too_low
    post '/order', params={"bid" => 1, "file" => Rack::Test::UploadedFile.new(TEST_FILE, "image/png")}
    refute last_response.ok?
    r = JSON.parse(last_response.body)
    assert_equal r['message'], 'Bid too low'
    refute_nil r['errors']
  end
  
  def test_no_file_uploaded
    post '/order', params={"bid" => DEFAULT_BID}
    refute last_response.ok?
  end

  def test_uploaded_file_too_large
    skip "test later"
  end
  
  def test_bump
    header 'X-Auth-Token', @order['auth_token']
    post "/order/#{@order_uuid}/bump", params={"bid" => DEFAULT_BID + 1}
    assert last_response.ok?
    r = JSON.parse(last_response.body)
    refute_nil r['auth_token']
    refute_nil r['uuid']
    refute_nil r['lightning_invoice']    
  end

  def test_that_bumping_down_fails
    header 'X-Auth-Token', @order['auth_token']
    post "/order/#{@order_uuid}/bump", params={"bid" => DEFAULT_BID - 1}
    refute last_response.ok?
  end

  def test_order_deletion
    header 'X-Auth-Token', @order['auth_token']
    delete "/order/#{@order_uuid}"
    assert last_response.ok?    
    delete "/order/#{@order_uuid}"
    refute last_response.ok?
  end

end
