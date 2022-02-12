"""
https://support.weather.com/s/article/PWS-Upload-Protocol?language=en_US
"""
import http.client
from pathlib import Path
import sys

SERVER = "weatherstation.wunderground.com"
URL = (
    "/weatherstation/updateweatherstation.php?"
    "ID={ID}&PASSWORD={KEY}&dateutc=now&"
    "winddir={winddir}&windspeedmph={windspeedmph}&windgustmph={windgustmph}&"
    "tempf={tempf}&rainin={rainin}&baromin={baromin}&"
    "humidity={humidity}&dailyrainin={dailyrainin}&"
    "dewptf={dewptf}&"
    "action=updateraw"
)
ID = "KWALONGV97"
KEY = "b7JFPUsp"
WXNOW = (
    "{rtWindDir:03}/{rtWindSpeed:03}g{windgustmph:03}t{normTemp:03}r{normRainRate:03}"
    "p{norm24hRain:03}P{normDayRain:03}h{normHumidity:02}b{normBaro:05}"
)


wunderground_map = dict(
    rtWindDir="winddir",
    rtWindSpeed="windspeedmph",
    rtOutsideTemp="tempf",
    rtRainRate="rainin",
    rtBaroCurr="baromin",
    rtOutsideHum="humidity",
    rtDayRain="dailyrainin",
)


def humin_to_tmbar(humin):
    return int(10 * humin * 33.8639)


def send_req(data):
    c = http.client.HTTPSConnection(SERVER)
    #c = http.client.HTTPConnection("localhost")
    url = URL.format(ID=ID, KEY=KEY, **data)
    c.request("GET", url)
    resp = c.getresponse()
    if resp.status != 200:
        raise RuntimeError("https://{}{}: ({}) {}".format(SERVER, url, resp.status, resp.read()))


def int_or_float(s):
    s = s.strip()
    try:
        return int(s)
    except ValueError:
        pass
    try:
        return float(s)
    except ValueError:
        pass
    return s


def seq_of_int_or_float(s, delim=","):
    seq = [int_or_float(i) for i in s.split(delim)]
    if len(seq) == 1:
        return seq[0]
    return seq


def read_data(data_file):
    raw_data = {}
    with open(data_file) as f:
        for line in f:
            key, m, val = line.partition("=")
            st_key = key.strip()
            st_val = int_or_float(val)
            if isinstance(st_val, str) and st_key != "DavisTime":
                st_val = seq_of_int_or_float(st_val)
            raw_data[st_key] = st_val
    return raw_data


def parse_data(data):
    wudata = {
        wunderground_map.get(k, k): v
        for k, v in data.items()
    }
    wudata["dewptf"] = data['grDewByHours'][-1]
    return wudata


def aprs_data(data):
    data = data.copy()
    hum = int(data["rtOutsideHum"])
    data["normHumidity"] = hum if hum < 100 else 0
    data["normTemp"] = int(float(data["rtOutsideTemp"]))
    data["normBaro"] = int(humin_to_tmbar(float(data["rtBaroCurr"])))
    data["normRainRate"] = int(data["rtRainRate"] * 100)
    data["normDayRain"] = int(data["rtDayRain"] * 100)
    data["norm24hRain"] = int(sum(data["grRainByHour"][-24:]) * 100)
    return data


def write_wxnow(path, data):
    Path(path).write_text(WXNOW.format(**aprs_data(data)))


def main():
    if len(sys.argv) < 3:
        print("provide RT data file as first argument and WX data file as second argument")
        sys.exit(2)
    data = read_data(sys.argv[1])
    data.update(read_data(sys.argv[2]))
    if len(sys.argv) > 3:
        raw_gust_entries = Path(sys.argv[3]).read_text().strip()
        data["windgustmph"] = max(seq_of_int_or_float(raw_gust_entries, delim="\n"))
    write_wxnow("/tmp/wxnow.txt", data)
    send_req(parse_data(data))


if __name__ == "__main__":
    main()
