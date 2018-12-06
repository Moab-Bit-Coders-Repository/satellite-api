# Ionosphere

A lightning app (Lapp) based on c-lightning. Presents an API to submit messages for global broadcast over Blockstream Satellite and pay for them with Bitcoin Lightning payments.

A brief screencast demonstration is available [here](https://drive.google.com/file/d/1W-wjVwT0sGOS28dnfRrgG1S4DE5Xbnl_/view?usp=sharing).

# Setup

Ionosphere is dependent on [lightning-charge](https://github.com/ElementsProject/lightning-charge), which itself is dependent on [c-lightning](https://github.com/ElementsProject/lightning) and [bitcoin](https://github.com/bitcoin/bitcoin). To bring up charged, lightningd, and bitcoind, a [handy docker-compose](https://github.com/DeviaVir/blc-docker) script is available.

Ionosphere itself is comprised of a RESTful API server and a transmitter daemon. The API server speaks JSON and is used for creating and managing message transmission orders and for processing lightning-charge payment callbacks. The transmitter daemon dequeues paid orders and writes the uploaded message a named pipe, where they are subsequently processed by the Blockstream Satellite GNU Radio transmitter.

## Run ##

The included `Dockerfile` builds a Docker file with the necessary gem dependencies, directory structure, and permissions. The included `docker_entrypoint.sh` runs the API server, transmitter daemon, and (optionally in development mode) a test daemon that simulates the GNU Radio application by reading from the FIFO and writing received messages to a tmp directory.

After building a Docker image (`ionosphere` in the example below), decide where you are going to keep your persisted data (`~/docker/data` in the example below) and run it like this:

```bash
docker run -e CHARGE_ROOT=http://api-token:mySecretToken@localhost:9112 -e CALLBACK_URI_ROOT=http://my.public.ip:9292 -u `id -u` -v ~/docker/data:/data -p 9292:9292 -it ionosphere
```

To run in developer mode, set the `RACK_ENV` environment variable like this:

```bash
docker run -e CHARGE_ROOT=http://api-token:mySecretToken@localhost:9112 -e CALLBACK_URI_ROOT=http://my.public.ip:9292 -e RACK_ENV=development -u `id -u` -v ~/docker/data:/data -p 9292:9292 -it ionosphere
```

## REST API ##

Each call to an API endpoint responds with a JSON object, whether the call is successful or results in an error.

The code samples below assume that you've set `IONOSPHERE` in your shell to the public base URL of your server.

### POST /order ###

Place an order for a message transmission. The body of the POST must provide a `file` containing the message and a `bid` in millisatoshis. If the bid is below an allowed minimum millisatoshis per byte, an error is returned.

For example, to place an order to transmit the file `hello_world.png` with an initial bid of 10,000 millisatoshi, issue an HTTP POST request like this:

```bash
curl -F "bid=10000" -F "file=@/path/to/upload/file/hello_world.png" $IONOSPHERE/order
```

If successful, the response includes the JSON Lightning invoice as returned by Lightning Charge's [POST /invoice](https://github.com/ElementsProject/lightning-charge#post-invoice) and an authentication token that can be used to modify the order. Within the metadata of the Lightning invoice, metadata is included providing: the bid (in millisatoshis), the SHA256 digest of the uploaded message file, and a UUID for the order.

```bash
{"auth_token":"d784e322dad7ec2671086ce3ad94e05108f2501180d8228577fbec4115774750","uuid":"409348bc-6af0-4999-b715-4136753979df","lightning_invoice":{"id":"N0LOTYc9j0gWtQVjVW7pK","msatoshi":"514200","description":"BSS Test","rhash":"5e5c9d111bc76ce4bf9b211f12ca2d9b66b81ae9839b4e530b16cedbef653a3a","payreq":"lntb5142n1pd78922pp5tewf6ygmcakwf0umyy039j3dndntsxhfswd5u5ctzm8dhmm98gaqdqdgff4xgz5v4ehgxqzjccqp286gfgrcpvzl04sdg2f9sany7ptc5aracnd6kvr2nr0e0x5ajpmfhsjkqzw679ytqgnt6w4490jjrgcvuemz790salqyz9far68cpqtgq3q23el","expires_at":1541642146,"created_at":1541641546,"metadata":{"msatoshis_per_byte":"200","sha256_message_digest":"0e2bddf3bba1893b5eef660295ef12d6fc72870da539c328cf24e9e6dbb00f00","uuid":"409348bc-6af0-4999-b715-4136753979df"},"status":"unpaid"}}
```

### POST /order/:uuid/bump ###

Increase the bid for an order sitting in the transmission queue. The new `bid` must be provided in the body of the POST and must be greater than the current bid. An `auth_token` must also be provided. For example, to bump up the bid on the order placed above to 700,000 millisatoshis, issue a POST like this:

```bash
curl -v -F "bid=700000" -F "auth_token=d784e322dad7ec2671086ce3ad94e05108f2501180d8228577fbec4115774750" localhost:9292//order/409348bc-6af0-4999-b715-4136753979df/bump
```

As shown below for DELETE, the `auth_token` may alternatively be provided using the `X-Auth-Token` HTTP header.

### DELETE /order/:uuid ###

To cancel an order, issue an HTTP DELETE request to the API endpoint `/order/:uuid/` providing the UUID of the order. An `auth_token` must also be provided. For example, to cancel the order above, issue a request like this:

```bash
curl -v -X DELETE -F "auth_token=5248b13a722cd9b2e17ed3a2da8f7ac6bd9a8fe7130357615e074596e3d5872f" $IONOSPHERE//order/409348bc-6af0-4999-b715-4136753979df
```

The `auth_token` may be provided as a parameter in the DELETE body as above or may be provided using the `X-Auth-Token` HTTP header, like this:

```bash
curl -v -X DELETE -H "X-Auth-Token: 5248b13a722cd9b2e17ed3a2da8f7ac6bd9a8fe7130357615e074596e3d5872f" $IONOSPHERE//order/409348bc-6af0-4999-b715-4136753979df
```

### GET /orders  ###

Retrieve a list of paid, but unsent orders. In development mode, a broader set of orders can be retrieved using the query parameter `status` to provide a filter in the form of a comma-separated list of order statuses. The valid order statuses are: `pending`, `paid`, `transmitting`, `sent`, and `cancelled`.

```bash
curl $IONOSPHERE/queue
```

```bash
export RACK_ENV=development
curl $IONOSPHERE/queue?status=pending,transmitting,cancelled
```

The response is a JSON array of records (one for each queued message). The revealed fields for each record include: `bid`, `message_size`, `message_digest`, `status`, `created_at`, `upload_started_at`, and `upload_ended_at`.

## Debugging ##

### queue.html ###

In development mode (i.e. when the ```RACK_ENV``` environment variable is set to ```development```), a FIFO consumer daemon is run that simulates the GNU Radio hardware and a debugging webpage is exposed at `$IONOSPHERE/queue.html` that supports inspection of queued and sent message orders. This webpage also serves as a demonstration of how the JSON returned by `GET /queue` can be processed by jQuery for display in an HTML table.

## Future Work ##

* Configure `Rack::Attack` to block and throttle abusive requests.
* Support bids priced in fiat currencies.
* Report the top bid_per_byte, queue depth, and estimated time to transmit in the response to `POST /order`.
