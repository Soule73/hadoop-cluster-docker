#!/usr/bin/env python3
import sys

for line in sys.stdin:
    line = line.strip().lower()
    if "warn" in line:
        print("WARN\t1")
    elif "error" in line:
        print("ERROR\t1")
    elif "notice" in line:
        print("NOTICE\t1")
    else:
        print("OTHER\t1")
