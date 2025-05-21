#!/usr/bin/env python3
import sys
import re

# Expression régulière correctement fermée
log_pattern = re.compile(r'(\S+) (\S+) (\S+) \[([^]]+)\] "(\S+) (\S+) (\S+)" (\d{3}) (\d+)')

for line in sys.stdin:
    line = line.strip()
    match = log_pattern.match(line)
    if match:
        status = match.group(8)  # Extraction du code HTTP
        print(f"{status}\t1")
    else:
        sys.stderr.write("Aucune correspondance pour la ligne : " + line + "\n")
