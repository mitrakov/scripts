#!/usr/bin/env python3

import sys
import time
from datetime import datetime, timezone

def main():
    if len(sys.argv) < 2:
        print("Usage: ts.py 1782991773357\n       ts.py now")
        sys.exit(1)

    ts_input = sys.argv[1]

    if ts_input == "now":
        print(int(time.time() * 1000))
        sys.exit(0)

    ts = float(ts_input)
    if len(ts_input) >= 13:      # check if it's seconds or milliseconds
        ts = ts / 1000

    print(f"Local: {datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"UTC:   {datetime.fromtimestamp(ts, timezone.utc).strftime('%Y-%m-%d %H:%M:%S')}")

if __name__ == "__main__":
    main()
