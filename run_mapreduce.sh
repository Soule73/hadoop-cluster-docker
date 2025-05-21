#!/bin/bash

echo "Démarrage des jobs Hadoop Streaming avec un reducer unique..."

# Définition de la liste des fichiers logs, des mappers associés et destinations HDFS
declare -A JOBS=(
    ["access.log"]="mapper_access.py /output/access_stats"
    ["error.log"]="mapper_error.py /output/error_stats"
    ["php_errors.log"]="mapper_php.py /output/php_stats"
    ["mysqld.log"]="mapper_mysql.py /output/mysql_stats"
)

for log in "${!JOBS[@]}"; do
    read -r mapper output <<< "${JOBS[$log]}"

    echo "Traitement de $log avec $mapper..."

    # Suppression de l'ancien output si présent
    if hadoop fs -test -d "$output"; then
        echo "Suppression de l'ancien output : $output"
        hadoop fs -rm -r "$output"
    else
        echo "Aucun dossier à supprimer : $output"
    fi

    # Exécution du job Hadoop Streaming
    hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.3.1.jar \
        -files /opt/hadoop/streaming_scripts/$mapper,/opt/hadoop/streaming_scripts/generic_reducer.py \
        -mapper "python3 /opt/hadoop/streaming_scripts/$mapper" \
        -reducer "python3 /opt/hadoop/streaming_scripts/generic_reducer.py" \
        -input /logs/$log \
        -output "$output"

    echo "Job terminé pour $log"

    # Exportation depuis HDFS vers un fichier local
    localfile="/tmp/$(basename ${output}).txt"
    echo "Exportation des données de $output vers $localfile"
    hadoop fs -getmerge "$output" "$localfile"

    # Indexation dans Elasticsearch
    echo "Indexation des résultats de $log dans Elasticsearch..."
    if [ -f "$localfile" ]; then
      # Définir l'index Elasticsearch en fonction du fichier log
      case "$log" in
        "access.log")
          index_name="access_index"
          ;;
        "error.log")
          index_name="error_index"
          ;;
        "php_errors.log")
          index_name="php_index"
          ;;
        "mysqld.log")
          index_name="mysql_index"
          ;;
        *)
          echo "Fichier log non reconnu ($log) pour indexation, passage..."
          continue 2
          ;;
      esac

      while IFS= read -r line || [ -n "$line" ]; do
         # Échapper les tabulations dans la ligne
         safe_line=$(echo "$line" | sed 's/\t/\\t/g')
         
         # Envoi de la requête d'indexation et récupération du code HTTP
         curl_response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "http://elasticsearch:9200/${index_name}/_doc" \
           -H 'Content-Type: application/json' \
           -d "{\"record\": \"${safe_line}\"}")
           
         # Si le code de retour n'est ni 200 ni 201, afficher un message d'erreur et continuer
         if [ "$curl_response" -ne 200 ] && [ "$curl_response" -ne 201 ]; then 
            echo "Erreur d'indexation dans ${index_name} pour la ligne: $line, code HTTP: $curl_response"
         fi
      done < "$localfile"
    else
      echo "Fichier $localfile non trouvé, indexation ignorée."
    fi

    echo "Indexation terminée pour $log"
done

echo "Tous les traitements et indexations sont terminés avec un reducer unique !"
