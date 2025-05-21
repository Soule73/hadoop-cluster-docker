#!/bin/bash
set -e

# Ajouter une entrée pour résoudre le nom "namenode"
echo "Ajout de l'entrée '127.0.0.1 namenode' dans /etc/hosts..."
echo "127.0.0.1 namenode" >> /etc/hosts

echo "Démarrage du service SSH..."
service ssh start

# Vérifier si le service cron est démarré
if ! pgrep -x "cron" > /dev/null; then
    echo "Le service cron n'est pas démarré. Tentative de démarrage..."
    service cron start
else
    echo "Le service cron est déjà en cours d'exécution."
fi

# Nettoyer le répertoire DataNode afin d'éviter l'incompatibilité de clusterID
echo "Nettoyage du répertoire DataNode..."
rm -rf /home/iris/dfsdata/datanode/*
mkdir -p /home/iris/dfsdata/datanode

# Formatage du NameNode HDFS uniquement si le répertoire des données n'existe pas
if [ ! -d "/home/iris/namenode/current" ]; then
    echo "Vérification des fichiers PID stales..."
    rm -f /tmp/hadoop-root-namenode.pid || true
    echo "Formatage du NameNode HDFS..."
    $HADOOP_HOME/bin/hdfs namenode -format -force
fi

echo "Démarrage de HDFS..."
$HADOOP_HOME/sbin/start-dfs.sh

echo "Démarrage de YARN..."
$HADOOP_HOME/sbin/start-yarn.sh

# Vérifier si la tâche cron est déjà ajoutée
if ! crontab -l | grep -q '/bin/bash /opt/scripts/check_logs.sh && /bin/bash /opt/scripts/ingest_logs.sh && /bin/bash /opt/scripts/run_mapreduce.sh'; then
    echo "Ajout de la tâche cron pour exécuter les scripts toutes les heures..."
    (crontab -l 2>/dev/null; echo "0 * * * * /bin/bash /opt/scripts/check_logs.sh && /bin/bash /opt/scripts/ingest_logs.sh && /bin/bash /opt/scripts/run_mapreduce.sh") | crontab -
fi

# Exécute la commande passée en argument (généralement pour garder le container actif)
exec "$@"
