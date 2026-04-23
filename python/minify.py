#!/usr/bin/env python3
# removes extra tabs and spaces from input
import sys
import re

def minify_code(input_text):
    return re.sub(r'\s+', ' ', input_text).strip()

def main():
    if not sys.stdin.isatty():    # if input redirected with "|" or "<"
        raw_data = sys.stdin.read()
        if raw_data:
            print(minify_code(raw_data))
        else:
            print("Error: No input detected via stdin.", file=sys.stderr)
    else:
        print("Usage: cat file.txt | python script.py")

if __name__ == "__main__":
    main()
