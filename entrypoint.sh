#!/bin/bash
set -e

# Ajouter une entrée pour résoudre le nom "namenode"
echo "Ajout de l'entrée '127.0.0.1 namenode' dans /etc/hosts..."
echo "127.0.0.1 namenode" >> /etc/hosts

echo "Démarrage du service SSH..."
service ssh start

# Formatage du NameNode seulement si le répertoire des données n'existe pas
if [ ! -d "/home/iris/namenode/current" ]; then
    echo "Formatage du NameNode HDFS..."
    $HADOOP_HOME/bin/hdfs namenode -format -force
fi

echo "Démarrage de HDFS..."
$HADOOP_HOME/sbin/start-dfs.sh

echo "Démarrage de YARN..."
$HADOOP_HOME/sbin/start-yarn.sh

# Exécute la commande passée en argument (généralement tail pour garder le conteneur actif)
exec "$@"
