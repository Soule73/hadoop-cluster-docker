#!/usr/bin/env python3
import sys

current_key = None
current_count = 0

for line in sys.stdin:
    line = line.strip()
    try:
        key, count = line.split("\t", 1)
        count = int(count)
    except ValueError:
        # Ignorer les lignes mal formées
        continue  

    if current_key == key:
        current_count += count
    else:
        if current_key is not None:
            print(f"{current_key}\t{current_count}")
        current_key = key
        current_count = count

# Afficher la dernière clé après la boucle
if current_key is not None:
    print(f"{current_key}\t{current_count}")
