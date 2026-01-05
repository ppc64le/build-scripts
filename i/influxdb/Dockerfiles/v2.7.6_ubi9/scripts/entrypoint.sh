#!/bin/bash
set -e

if [ "${1:0:1}" = '-' ]; then
    set -- influxd "$@"
fi

if [ "$1" = 'influxd' ]; then
    export PATH="$PATH:/influxdb/cmd:/influxdb/docker:/influxdb/bin/linux"  # Update with correct paths
    /init-influxdb.sh "${@:2}"
fi

exec "$@"