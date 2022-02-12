#!/usr/bin/env bash

set -euo pipefail

data_path=/home/pi/weather/weather-www/templates
update_freq=5
rtdata=$data_path/rtdata
wxdata=$data_path/wxdata
gustdata=$data_path/gust
/home/pi/weather/weather-www/calc_gust.sh $gustdata
if [[ $(($(date +%-M) % $update_freq)) == 0 ]]; then
    /home/pi/weather/weather-www/templates/weathproc.pl -x && \
    /home/pi/weather/weather-www/templates/weathproc.pl -r && \
	python3 /home/pi/weather/weather-www/wunderground.py $rtdata $wxdata $gustdata
fi
