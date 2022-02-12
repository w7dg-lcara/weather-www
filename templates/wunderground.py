"""
https://support.weather.com/s/article/PWS-Upload-Protocol?language=en_US
"""
import http.client
import sys

SERVER = "rtupdate.wunderground.com"
URL = (
    "/weatherstation/updateweatherstation.php?"
    "ID={ID}&PASSWORD={KEY}&dateutc=now&"
    "winddir={winddir}&windspeedmph={windspeedmph}&"
    "tempf={tempf}&rainin={rainin}&baromin={baromin}&"
    "humidity={humidity}&dailyrainin={dailyrainin}&action=updateraw"
)
ID = "KWALONGV97"
KEY = "b7JFPUsp"


wunderground_map = dict(
    rtWindDir="winddir",
    rtWindSpeed="windspeedmph",
    rtOutsideTemp="tempf",
    rtRainRate="rainin",
    rtBaroCurr="baromin",
    rtOutsideHum="humidity",
    rtDayRain="dailyrainin",
    # windgustmph
    # dewptf
    # dailyrainin
)


def send_req(data):
    c = http.client.HTTPSConnection(SERVER)
    #c = http.client.HTTPConnection("localhost")
    c.request("GET", URL.format(ID=ID, KEY=KEY, **data))
    resp = c.getresponse()
    if resp.status != 200:
        raise RuntimeError(resp.read())


def parse_data(data_file):
    raw_data = {}
    with open(data_file) as f:
        for line in f:
            key, m, val = line.partition("=")
            raw_data[key.strip()] = val.strip()
    return {
        wunderground_map.get(k, k): v
        for k, v in raw_data.items()
    }


def main():
    if len(sys.argv) < 2:
        print("provide RT data file as first argument")
        sys.exit(2)
    send_req(parse_data(sys.argv[1]))


if __name__ == "__main__":
    main()
