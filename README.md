# Cluster Hadoop Dockerisé

Ce projet propose une solution complète pour déployer et utiliser un cluster Hadoop (HDFS et YARN) dans un environnement Docker.  
L’objectif est de faciliter l’installation, la configuration et l’expérimentation avec Hadoop sur toute plateforme (Linux, macOS, Windows via Docker Desktop) grâce à une image Docker personnalisée et Docker Compose.

Le projet est divisé en plusieurs documents détaillés qui expliquent chacun un aspect du déploiement et de l’utilisation du cluster :

- **01-installation-hadoop-docker.md**  
  Contient toutes les étapes nécessaires pour installer et configurer Hadoop dans Docker, incluant le Dockerfile et le script d’entrypoint.

- **02-usual-command-hadoop-docker.md**  
  Fournit un guide sur les commandes Hadoop usuelles dans un environnement Docker, ainsi que la gestion du cluster (lancement, arrêt, consultation des logs, etc.).

- **03-hadoop-map-reduce-docker.md**  
  Décrit la mise en oeuvre d’un job MapReduce (exemple Word Count) avec Hadoop Streaming, incluant la création et le test des scripts Python (mapper et reducer), ainsi que la soumission du job et le benchmark des performances.

## Objectifs du Projet

- **Simplicité de déploiement**  
  Une image Docker unifiée permet d’éviter les problèmes d'installation sur différents environnements (dépendances, configurations système, etc.).

- **Exploitation de Hadoop Streaming**  
  L’exemple MapReduce permet d’expérimenter facilement avec des scripts Python pour réaliser des traitements distribués, sans la complexité d’un développement en Java.

- **Environnement modulable et extensible**  
  La configuration en Docker Compose permet d’étendre le cluster (multi-nœuds, intégration d’outils de monitoring, etc.) et d’adapter le projet à divers besoins.

## Pour commencer

1. **Installation et déploiement du cluster**  
   Consultez le fichier [01-installation-hadoop-docker.md](./01-installation-hadoop-docker.md) pour les instructions complètes d’installation du cluster Hadoop dans Docker.

2. **Utilisation des commandes Hadoop**  
   Pour apprendre à interagir avec le cluster via les commandes habituelles (création de répertoires, gestion des fichiers sur HDFS, etc.), référez-vous au fichier [02-usual-command-hadoop-docker.md](./02-usual-command-hadoop-docker.md).

3. **Exécuter un job MapReduce**  
   Pour lancer et tester un job MapReduce en utilisant Hadoop Streaming (exemple Word Count), consultez le fichier [03-hadoop-map-reduce-docker.md](./03-hadoop-map-reduce-docker.md).

## Documentation et Support

Chacun des fichiers séparés décrit en détail les différentes étapes de l'installation et de l'utilisation du cluster.  
Pour toute question ou suggestion, n'hésitez pas à ouvrir une issue ou à consulter la documentation officielle de Hadoop.

Bonne expérimentation !
