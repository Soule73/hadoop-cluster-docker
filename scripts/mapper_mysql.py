#!/usr/bin/env python3
import sys

for line in sys.stdin:
    line = line.strip()
    if "[Warning]" in line:
        print("Warning\t1")
    elif "[Note]" in line:
        print("Note\t1")
    else:
        print("Other\t1")
