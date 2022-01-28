#!/usr/bin/env bash

data_file=/home/pi/weather/data/realtime.dat
/home/pi/weather/vproweather --get-realtime /dev/ttyUSB0 > $data_file && \
	python3 /home/pi/weather/weather-www/wunderground.py $data_file
