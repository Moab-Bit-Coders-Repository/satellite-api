ENV['RACK_ENV'] ||= 'development'
KILO_BYTE = 2 ** 10
MEGA_BYTE = 2 ** 20

DB_ROOT = ENV['DB_ROOT'] || (ENV['RACK_ENV'] == 'prFIFO_PDU_SIZE_IN_BYTESn') ? '/data/ionosphere' : './db'
DB_PATH = File.join(DB_ROOT, "ionosphere_#{ENV['RACK_ENV']}.sqlite3")
MESSAGE_STORE_PATH = ENV['MESSAGE_STORE_PATH'] || File.join(DB_ROOT, 'messages')
SENT_MESSAGE_STORE_PATH = File.join(MESSAGE_STORE_PATH, 'sent')
CALLBACK_URI_ROOT = ENV['CALLBACK_URI_ROOT'] || "http://localhost:4567"

CHARGE_API_TOKEN = ENV['CHARGE_API_TOKEN'] || 'mySecretToken'
CHARGE_ROOT = ENV['CHARGE_ROOT'] || "http://api-token:#{CHARGE_API_TOKEN}@localhost:9112"

MIN_PER_BYTE_BID = (ENV['RACK_ENV'] == 'production') ? 100 : 1 # minimum price per byte in millisatoshis
MAX_MESSAGE_SIZE = 1 * MEGA_BYTE

LN_INVOICE_EXPIRY = 60 * 10 # ten minutes
LN_INVOICE_DESCRIPTION = (ENV['RACK_ENV'] == 'production') ? "Blockstream Satellite Transmission" : "BSS Test"
MAX_LIGHTNING_INVOICE_SIZE = 1024

FIFO_PIPE_PATH = ENV['FIFO_PIPE_PATH'] || "/tmp/src" # named pipe with GNU radio sitting on the other end
FIFO_PDU_SIZE = ENV['FIFO_PDU_SIZE'] || 1024 # bytes
FIFO_RATE_LIMIT = ENV['FIFO_RATE_LIMIT'] || 8 * KILO_BYTE # bytes per second
