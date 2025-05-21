#!/usr/bin/python3
import sys

# Lire l'entrée standard
for line in sys.stdin:
    line = line.strip()    # Nettoyer la ligne
    words = line.split()   # Séparer les mots
    for word in words:
        print("{}\t{}".format(word, "1"))
