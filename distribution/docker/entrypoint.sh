#!/bin/sh

set -x
if [ ! -z ${SLEEP+x} ]
then
    sleep "$SLEEP"
fi

if [ -z ${LOGGER_FILE+x} ]
then
   LOGGER_FILE="/etc/rust-packaging-example/logger.yaml"
fi

exec /rust-packaging-example --config /etc/rust-packaging-example/config/*.yaml --logger-config "$LOGGER_FILE"
