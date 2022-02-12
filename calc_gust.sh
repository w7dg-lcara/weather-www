#!/usr/bin/env bash

set -euo pipefail

backlog=9
dev=/dev/ttyUSB0
key="rtWindSpeed"
if [[ -z "${1:-}" ]]; then
    echo "Supply gust data file as first argument"
    exit 2
fi
datafile=$1
tmp=$(mktemp)

touch $datafile
(tail -n $backlog $datafile && \
    /home/pi/weather/vproweather -x $dev | grep $key | cut -d' ' -f3) > $tmp && \
mv $tmp $datafile
