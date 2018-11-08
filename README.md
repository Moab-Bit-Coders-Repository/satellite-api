# Ionosphere

c-lightning based Lapp that presents an API to submit messages for global broadcast over Blockstream Satellite and pay for them with Bitcoin Lightning payments.

# Setup

Ionosphere is dependent on [lightning-charge](https://github.com/ElementsProject/lightning-charge), which itself is dependent on [c-lightning](https://github.com/ElementsProject/lightning) and [bitcoin](https://github.com/bitcoin/bitcoin). To bring up charged, lightningd, and bitcoind, a [handy docker-compose](https://github.com/DeviaVir/blc-docker) script is available.

Ionosphere itself is comprised of a RESTful API server and a transmitter daemon. The API server speaks JSON and is used for creating and managing message transmission orders and for processing lightning-charge payment callbacks. The transmitter daemon dequeues paid orders and writes the uploaded message a named pipe, where they are subsequently processed by the Blockstream Satellite GNU Radio transmitter.

## Run ##

The included `Dockerfile` builds a Docker file with the necessary gem dependencies, directory structure, and permissions. The included `docker_entrypoint.sh` runs the API server, transmitter daemon, and (optionally in development mode) a test daemon that simulates the GNU Radio application by reading from the FIFO and writing received messages to a tmp directory.

After building a Docker image (`ionsosphere` in the example below), decide where you are going to keep your persisted data (`~/docker/data` in the example below) and run it like this:

```bash
docker run -e CHARGE_ROOT=http://api-token:token:mySecretToken@localhost:9112 -e CALLBACK_URI_ROOT=http://my.public.ip:9292 -u `id -u` -v ~/docker/data:/data -p 9292:9292 -it ionosphere
```

To run in developer mode, set the `RACK_ENV` environment variable like this:

```bash
docker run -e CHARGE_ROOT=http://api-token:token:mySecretToken@localhost:9112 -e CALLBACK_URI_ROOT=http://my.public.ip:9292 -e RACK_ENV=development -u `id -u` -v ~/docker/data:/data -p 9292:9292 -it ionosphere
```

## REST API ##

All endpoints accept and return data in JSON format.

The code samples below assume that you've set `IONOSPHERE` to the public base URL of your server.

### POST /order ###

To place an order to transmit the file `hello_world.png` with an initial bid of 100 msatoshis per byte, issue an HTTP POST request like this:

```bash
curl -F "bid=100" -F "file=@/path/to/upload/file/hello_world.png" $IONOSPHERE/order
```

If successful, the response includes the JSON Lightning invoice as returned by Lightning Charge's [POST /invoice](https://github.com/ElementsProject/lightning-charge#post-invoice) and an authentication token that can be used to modify the order. Within the metadata of the Lightning invoice, metadata is included providing: the bid (in msatoshis per byte), the SHA256 digest of the uploaded message file, and a UUID for the order.

```bash
{"auth_token":"d784e322dad7ec2671086ce3ad94e05108f2501180d8228577fbec4115774750","lightning_invoice":{"id":"N0LOTYc9j0gWtQVjVW7pK","msatoshi":"514200","description":"BSS Test","rhash":"5e5c9d111bc76ce4bf9b211f12ca2d9b66b81ae9839b4e530b16cedbef653a3a","payreq":"lntb5142n1pd78922pp5tewf6ygmcakwf0umyy039j3dndntsxhfswd5u5ctzm8dhmm98gaqdqdgff4xgz5v4ehgxqzjccqp286gfgrcpvzl04sdg2f9sany7ptc5aracnd6kvr2nr0e0x5ajpmfhsjkqzw679ytqgnt6w4490jjrgcvuemz790salqyz9far68cpqtgq3q23el","expires_at":1541642146,"created_at":1541641546,"metadata":{"msatoshis_per_byte":"200","sha256_message_digest":"0e2bddf3bba1893b5eef660295ef12d6fc72870da539c328cf24e9e6dbb00f00","uuid":"409348bc-6af0-4999-b715-4136753979df"},"status":"unpaid"}}
```

### DELETE /cancel ###

To cancel an order, issue an HTTP DELETE request to the API endpoint `/cancel/:uuid/:auth_token`. For example, to cancel the order above, issue a request like this:

```bash
curl -X DELETE $IONOSPHERE/cancel/409348bc-6af0-4999-b715-4136753979df/d784e322dad7ec2671086ce3ad94e05108f2501180d8228577fbec4115774750
```

### GET /queue  ###

To retrieve a snapshot of the message queue, issue an HTTP GET to the API endpoint `/queue` like this:

```bash
curl $IONOSPHERE/queue
```

The response is a JSON array of records (one for each queued message). The revealed fields for each record include: `bid`, `message_size`, `message_digest`, `status`, `created_at`, `upload_started_at`, and `upload_ended_at`.

## Debugging ##

### queue.html ###

In development mode (i.e. when the ```RACK_ENV``` environment variable is set to ```development```), a FIFO consumer daemon is run that simulates the GNU Radio hardware and a debugging webpage is exposed at `$IONOSPHERE/queue.html` that supports inspection of queued and sent message orders. This webpage also serves as a demonstration of how the JSON returned by `GET /queue` can be processed by JQuery for display in an HTML table.

## Future Work ##

An additional call (`POST /increase_bid`) will be added to the API to allow the bid to be increased for a message stuck in the queue.
