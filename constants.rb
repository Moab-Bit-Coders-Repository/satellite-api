DB_PATH = ENV['DB_PATH'] || '/data/ionosphere/ionosphere.db'
MESSAGE_STORE_PATH = ENV['MESSAGE_STORE_PATH'] || '/data/ionosphere/messages'

CHARGE_API_TOKEN = ENV['CHARGE_API_TOKEN'] || 'mySecretToken'
CHARGE_ROOT = ENV['CHARGE_ROOT'] || "http://api-token:#{CHARGE_API_TOKEN}@localhost:9112"
MIN_PER_BYTE_BID = 1 # minimum price per byte in msatoshis
KILO_BYTE = 2 ** 10
MEGA_BYTE = 2 ** 20
MAX_MESSAGE_SIZE = 1 * MEGA_BYTE
LN_INVOICE_EXPIRY = 60 * 10 # ten minutes
LN_INVOICE_DESCRIPTION = "BSS Test" # "Blockstream Satellite Transmission"

CALLBACK_URI_ROOT = ENV['CALLBACK_URI_ROOT'] || "http://localhost:4567"

FIFO_PIPE_PATH = "/tmp/src" # named pipe with GNU radio sitting on the other end