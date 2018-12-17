ENV['RACK_ENV'] = 'test'
ENV['CALLBACK_URI_ROOT'] = 'http://localhost:9292'

require 'minitest/autorun'
require 'rack/test'
require 'json'
require_relative '../main'

TEST_FILE = "test.png"
TINY_TEST_FILE = "tiny_test.txt"

unless File.exists?(TEST_FILE) and File.exists?(TINY_TEST_FILE)
  `curl -o #{TEST_FILE} https://raw.githubusercontent.com/scijs/baboon-image/master/baboon.png`
  `echo "abcdefghijklmnopqrstuvwxyz" > #{TINY_TEST_FILE}`
end

DEFAULT_BID = File.stat(TEST_FILE).size * MIN_PER_BYTE_BID + 1

class MainAppTest < Minitest::Test
  include Rack::Test::Methods 

  def app
    Sinatra::Application
  end
 
  def place_order
    post '/order', params={"bid" => DEFAULT_BID, "file" => Rack::Test::UploadedFile.new(TEST_FILE, "image/png")}
    r = JSON.parse(last_response.body)
    @order = Order.find_by_uuid(r['uuid'])
  end
 
  def setup
    place_order
  end
  
  def pay_invoice(invoice)
    post "/callback/#{invoice.lid}/#{invoice.charged_auth_token}"
    assert last_response.ok?
  end
  
  def write_response
    File.open('response.html', 'w') { |file| file.write(last_response.body) }
  end
  
  def order_is_queued(uuid)
    get '/orders/queued'
    assert last_response.ok?
    r = JSON.parse(last_response.body)
    uuids = r.map {|o| o['uuid']}
    uuids.include?(uuid)
  end

  def test_get_orders_queued
    get "/orders/queued?limit=#{MAX_QUEUED_ORDERS_REQUEST}"
    assert last_response.ok?
    r = JSON.parse(last_response.body)
    queued_before = r.count
    place_order
    pay_invoice(@order.invoices.last)
    assert order_is_queued(@order.uuid)
    get "/orders/queued?limit=#{MAX_QUEUED_ORDERS_REQUEST}"
    assert last_response.ok?
    r = JSON.parse(last_response.body)
    queued_after = r.count
    assert_equal queued_after, queued_before + 1
  end

  def test_get_orders_sent
    get '/orders/sent'
    assert last_response.ok?
  end

  def test_get_order
    place_order
    assert last_response.ok?
    r = JSON.parse(last_response.body)
    header 'X-Auth-Token', r['auth_token']
    get %Q(/order/#{r['uuid']})
    assert last_response.ok?
  end
  
  def test_order_creation
    place_order
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

  def test_uploaded_file_too_small
    post '/order', params={"bid" => DEFAULT_BID, "file" => Rack::Test::UploadedFile.new(TINY_TEST_FILE, "text/plain")}
    refute last_response.ok?
    r = JSON.parse(last_response.body)
    assert_match "too small", r["errors"][0]
  end
  
  def test_bump
    place_order
    refute order_is_queued(@order.uuid)
    pay_invoice(@order.invoices.last)
    assert order_is_queued(@order.uuid)
    header 'X-Auth-Token', @order.user_auth_token
    post "/order/#{@order.uuid}/bump", params={"bid" => DEFAULT_BID + 1}
    assert last_response.ok?
    r = JSON.parse(last_response.body)
    refute_nil r['auth_token']
    refute_nil r['uuid']
    refute_nil r['lightning_invoice']
    lid = r['lightning_invoice']['id']
    refute order_is_queued(@order.uuid)
    pay_invoice(Invoice.find_by_lid(lid))
    assert order_is_queued(@order.uuid)    
  end

  def test_that_bumping_down_fails
    header 'X-Auth-Token', @order.user_auth_token
    post "/order/#{@order.uuid}/bump", params={"bid" => DEFAULT_BID - 1}
    refute last_response.ok?
  end

  def test_order_deletion
    header 'X-Auth-Token', @order.user_auth_token
    cancelled_before = Order.where(status: :cancelled).count
    delete "/order/#{@order.uuid}"
    cancelled_after = Order.where(status: :cancelled).count
    assert last_response.ok?
    assert_equal cancelled_after, cancelled_before + 1
    delete "/order/#{@order.uuid}"
    refute last_response.ok?
  end
  
  def test_get_sent_message
    place_order
    get "/order/#{@order.uuid}/sent_message"
    refute last_response.ok?

    pay_invoice(@order.invoices.last)
    @order.reload
    @order.transmit!
    get "/order/#{@order.uuid}/sent_message"
    assert last_response.ok?
    
    @order.end_transmission!
    get "/order/#{@order.uuid}/sent_message"
    assert last_response.ok?
    
  end

end
