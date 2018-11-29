#!/bin/bash
set -eo pipefail

function cleanup_before_exit {
  bundle exec ruby daemons/transmitter_control.rb stop
  bundle exec ruby test/fifo2files_control.rb stop
  'kill `jobs -p`'
}

trap cleanup_before_exit SIGTERM

mkdir -p /data/ionosphere
mkdir -p /data/ionosphere/messages
bundle exec rake db:create
bundle exec rake db:schema:load

echo "starting transmitter_control"
bundle exec ruby daemons/transmitter_control.rb start

if [[ $RACK_ENV = "development" ]]; then
        echo "starting fifo2files"
        bundle exec ruby test/fifo2files_control.rb start
fi

bundle exec rackup --host 0.0.0.0


# shutdown the entire process when any of the background jobs exits (even if successfully)
wait -n
kill -TERM $$
