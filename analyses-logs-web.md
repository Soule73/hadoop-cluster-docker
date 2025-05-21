# Projet : Analyse de logs Web

**Objectif :**  
Collecter, filtrer et agréger des fichiers journaux de serveurs web (par exemple, Apache ou Nginx) afin d'extraire des métriques utiles (codes HTTP, erreurs, etc.) et obtenir une visualisation en temps réel via un dashboard Kibana.

---

## 1. Mise en Place de l'Environnement

### a. Architecture et Conteneurisation

Pour cette solution, nous utilisons Docker afin d’isoler et déployer les différents composants :

- **Conteneur Hadoop :**  
  - Basé sur une image Ubuntu 20.04.
  - Installation de Java (OpenJDK 11), SSH, wget, tar, net-tools, sed.
  - Installation d’Hadoop (extraction du tar.gz et création d’un lien symbolique pour simplifier les appels).

- **Services Cron & Nano :**  
  - Installation de cron et nano pour planifier des tâches (triggering d’indexation, export des résultats HDFS, …).

- **Stack ELK (Elasticsearch, Logstash, Kibana) :**  
  - Déployée dans un réseau Docker distinct appelé `elk-network`.
  - Notre conteneur Hadoop se connectera également automatiquement à ce réseau pour communiquer avec Elasticsearch.

### b. Dockerfile (Exemple)
[Dockerfile](./Dockerfile)
- elk-network   # Assurez-vous que ce réseau est déclaré en externe
### c. Docker Compose pour la multi-connectivité réseau
Afin de connecter automatiquement le conteneur Hadoop au réseau ELK (en plus du réseau Hadoop), utilisez un fichier `docker-compose.yml` similaire à :
[docker-compose.yaml](./docker-compose.yml)

Cela permet au conteneur Hadoop d’accéder automatiquement aux services de l’ELK stack.

---

## 2. Traitement des Logs via Hadoop Streaming

### a. Préparation des tâches de MapReduce

Nous avons défini plusieurs jobs Hadoop Streaming dans le script `run_mapreduce.sh` qui traite différents fichiers journaux. Par exemple :

- **access.log** avec `mapper_access.py`  
- **error.log** avec `mapper_error.py`  
- **php_errors.log** avec `mapper_php.py`  
- **mysqld.log** avec `mapper_mysql.py`

Chaque job génère en sortie un dossier HDFS (par exemple, `/output/access_stats`) contenant les résultats agrégés.

### b. Exemple de Script : `run_mapreduce.sh`
[run_mapreduce.sh](./run_mapreduce.sh)

Ce script s’exécute soit manuellement soit via Cron (voir la suite) :
- Il lance des jobs Hadoop Streaming.
- Exporte les résultats depuis HDFS.
- Indexe chaque ligne dans Elasticsearch en gérant les erreurs de connexion (pour éviter que des exceptions n’interrompent le pipeline).

---

## 3. Automatisation avec Cron

### a. Planification

Pour exécuter ces traitements de façon régulière, nous utilisons Cron. Dans l’entrypoint du conteneur, nous démarrons le service Cron automatiquement.

### b. Script d'Entrée (`entrypoint.sh`)
[entrypoint.sh](./entrypoint.sh)

Définissez la variable d’environnement `EDITOR` à `nano` ou `vim` pour modifier la crontab si nécessaire.

---

## 4. Visualisation dans Kibana

Une fois les données indexées dans Elasticsearch (index : `access_index`, `error_index`, etc.), vous pouvez les explorer et les visualiser.

### a. Création des Champs Scriptés dans Kibana

**Champ scripté “code”** (pour extraire le code HTTP) :

```painless
if (!doc.containsKey("record.keyword") || doc["record.keyword"].empty) {
  return "";
}
String field = doc["record.keyword"].value;
int pos = field.indexOf(String.valueOf((char)9));
if (pos != -1) {
  return field.substring(0, pos);
} else {
  return field;
}
```

**Champ scripté “count”** (pour extraire le nombre d’occurrences) :

```painless
if (!doc.containsKey("record.keyword") || doc["record.keyword"].empty) {
  return 0;
}
String field = doc["record.keyword"].value;
int pos = field.indexOf(String.valueOf((char)9));
if (pos != -1 && pos < field.length() - 1) {
  String countStr = field.substring(pos + 1).trim();
  return Integer.parseInt(countStr);
} else {
  return 0;
}
```

#### Création dans Kibana
1. Accédez à **Stack Management > Index Patterns**.
2. Sélectionnez votre index pattern (ex. `access_index`).
3. Dans l’onglet **Scripted Fields**, ajoutez chacun des champs ci-dessus.
4. Vérifiez avec le "Script Preview" que les valeurs sont correctement extraites.

### b. Création d’une Visualisation (ex. Diagramme en Barres)

Pour visualiser la somme des occurrences par code HTTP :
1. Rendez-vous dans **Visualize Library** et créez une nouvelle visualisation.
2. Choisissez un diagramme en barres verticales.
3. Sur l’axe des **X**, sélectionnez une agrégation `{Terms}` sur le champ scripté `code`.
4. Sur l’axe des **Y**, configurez une agrégation `{Sum}` sur le champ scripté `count`.
5. Appliquez les modifications et sauvegardez la visualisation (ex. nommez-la « Répartition des codes HTTP »).

Vous pourrez ensuite ajouter vos visualisations dans un dashboard afin d’avoir un aperçu global de l’activité de votre serveur web.

---

## 5. Conclusion et Perspectives

Ce projet « Analyse de logs Web » couvre les étapes suivantes :

- **Collecte et prétraitement :**  
  Utilisation de Hadoop Streaming pour traiter et agréger des logs apports depuis différents fichiers journaux (Apache, Nginx, etc.).

- **Automatisation :**  
  Intégration de Cron pour planifier l’exécution périodique du pipeline et indexation automatique dans Elasticsearch.

- **Indexation et Visualisation :**  
  Envoi des résultats agrégés vers Elasticsearch pour alimenter un dashboard Kibana. La création de champs scriptés permet d’extraire dynamiquement les métriques utiles depuis un champ brut.

**Perspectives :**  
- Vous pouvez affiner davantage les scripts MapReduce pour intégrer d’autres métriques (durées de requêtes, adresses IP, etc.).
- L’ajout de notifications (alertes par email, Slack) via Logstash ou un autre système pourrait améliorer la surveillance en temps réel.
- L’optimisation du dashboard Kibana avec des filtres interactifs et des visualisations complémentaires (graphes temporels, heatmaps, etc.) enrichira l’analyse.

Cette documentation offre une vue d'ensemble complète du projet, depuis le déploiement de l'infrastructure jusqu'à la visualisation des métriques. N'hésitez pas à adapter et approfondir chaque étape en fonction de vos besoins et de l'évolution de votre environnement.