#!/usr/bin/env bash
set -e

if [ "${1:0:1}" = '-' ]; then
    set -- crate "$@"
fi

if [ "$1" = 'crate' -a "$(id -u)" = '0' ]; then
    chown -R crate:crate /data
    set -- crate "$@"
fi

exec "$@"
