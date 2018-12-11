ENV['RACK_ENV'] ||= 'development'
KILO_BYTE = 2 ** 10
MEGA_BYTE = 2 ** 20

require 'yaml'
yaml_path = File.join(File.expand_path(File.dirname(__FILE__)), 'config', 'database.yml')
conf = YAML.load_file(yaml_path)
DB_ROOT = File.dirname(conf[ENV['RACK_ENV']]['database'])
MESSAGE_STORE_PATH = File.join(DB_ROOT, 'messages')
SENT_MESSAGE_STORE_PATH = File.join(MESSAGE_STORE_PATH, 'sent')

CALLBACK_URI_ROOT = ENV['CALLBACK_URI_ROOT'] || "http://localhost:4567"

CHARGE_API_TOKEN = ENV['CHARGE_API_TOKEN'] || 'mySecretToken'
CHARGE_ROOT = ENV['CHARGE_ROOT'] || "http://api-token:#{CHARGE_API_TOKEN}@localhost:9112"

MIN_PER_BYTE_BID = ENV['MIN_PER_BYTE_BID'] || 50 # minimum price per byte in millisatoshis
MAX_MESSAGE_SIZE = 1 * MEGA_BYTE

LN_INVOICE_EXPIRY = 60 * 10 # ten minutes
LN_INVOICE_DESCRIPTION = (ENV['RACK_ENV'] == 'production') ? "Blockstream Satellite Transmission" : "BSS Test"
MAX_LIGHTNING_INVOICE_SIZE = 1024

TRANSMIT_RATE_LIMIT = ENV['TRANSMIT_RATE_LIMIT'] # bytes per second
PAGE_SIZE = 20
MAX_QUEUED_ORDERS_REQUEST = 100
