#!/bin/bash
set -eo pipefail

function cleanup_before_exit {
  bundle exec ruby daemons/transmitter_control stop
  'kill `jobs -p`'
}

trap cleanup_before_exit SIGTERM

mkdir -p /data/ionosphere
bundle exec rake migrate

bundle exec ruby daemons/transmitter_control.rb start
bundle exec rackup --host 0.0.0.0


# shutdown the entire process when any of the background jobs exits (even if successfully)
wait -n
kill -TERM $$