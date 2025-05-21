#!/bin/bash
HDFS_DIR="/logs"

LOCAL_DIR="/logs_local"

# Créer le répertoire HDFS pour les logs s'il n'existe pas déjà
echo "Démarrage de l’ingestion des logs vers HDFS..."

hadoop fs -mkdir -p $HDFS_DIR

# Ingestion des logs depuis /logs_local (les fichiers sont montés depuis Windows)
for log in php_errors.log error.log access.log mysqld.log; do
    if [ -f "$LOCAL_DIR/$log" ]; then
        echo "Ingestion de $log dans HDFS..."
        hadoop fs -put -f $LOCAL_DIR/$log $HDFS_DIR/
    else
        echo "Fichier absent : $log"
    fi
done

echo "Ingestion terminée !"
