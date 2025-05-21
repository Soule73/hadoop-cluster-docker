#!/usr/bin/env python3
import sys

for line in sys.stdin:
    line = line.strip()
    if "PHP Warning:" in line:
        print("PHP Warning\t1")
    elif "PHP Fatal error:" in line:
        print("PHP Fatal error\t1")
    else:
        print("Other\t1")
