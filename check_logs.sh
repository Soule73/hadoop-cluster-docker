#!/bin/bash

LOGS_DIR="/logs_local"
LOG_FILES=("php_errors.log" "error.log" "access.log" "mysqld.log")

echo "Vérification des fichiers logs montés depuis Docker..."

for log in "${LOG_FILES[@]}"; do
    if [ -f "$LOGS_DIR/$log" ]; then
        echo "Fichier trouvé : $log"
    else
        echo "Fichier manquant : $log"
    fi
done
