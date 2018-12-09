#!/bin/bash
set -eo pipefail

function cleanup_before_exit {
  bundle exec ruby daemons/transmitter_control.rb stop
  'kill `jobs -p`'
}

trap cleanup_before_exit SIGTERM

if [ ! -f /data/ionosphere/ionosphere_production.sqlite3 ]; then
        bundle exec rake db:create
        bundle exec rake db:schema:load
fi

echo "starting transmitter_control"
bundle exec ruby daemons/transmitter_control.rb start

bundle exec rackup --host 0.0.0.0


# shutdown the entire process when any of the background jobs exits (even if successfully)
wait -n
kill -TERM $$
