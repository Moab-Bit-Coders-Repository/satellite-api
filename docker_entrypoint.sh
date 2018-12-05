#!/bin/bash
set -eo pipefail

function cleanup_before_exit {
  bundle exec ruby test/fifo2files_control.rb stop
  'kill `jobs -p`'
}

trap cleanup_before_exit SIGTERM

mkdir -p /data/ionosphere
mkdir -p /data/ionosphere/messages
bundle exec rake db:create
bundle exec rake db:schema:load

if [[ $RACK_ENV = "development" ]]; then
        echo "starting fifo2files"
        bundle exec ruby test/fifo2files_control.rb start
fi

bundle exec ruby app.rb


# shutdown the entire process when any of the background jobs exits (even if successfully)
wait -n
kill -TERM $$
