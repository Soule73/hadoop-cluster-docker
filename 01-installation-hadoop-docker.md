# Cluster Hadoop Dockerisé

Ce projet propose un environnement complet pour démarrer un cluster Hadoop (HDFS et YARN) dans un conteneur Docker. Grâce à une image Docker personnalisée et à Docker Compose, toutes les dépendances et configurations (Java, SSH, Hadoop et ses fichiers de configuration) sont intégrées dans un environnement isolé. Vous pourrez ainsi expérimenter facilement sur des environnements non Linux (Windows, macOS) via Docker Desktop.

> **Remarque :**  
> Ce projet est conçu pour simplifier l’installation, le démarrage et l’utilisation d’Hadoop. Pour un déploiement de test, l’exécution se fait sous l’utilisateur root. En production, il est recommandé d’utiliser un compte non privilégié et d’adapter les configurations de sécurité.

---

## Table des matières

- [Prérequis](#prérequis)
- [Structure du projet](#structure-du-projet)
- [Configuration du Dockerfile](#configuration-du-dockerfile)
- [Le script d’EntryPoint](#le-script-dentrypoint)
- [Configuration de Docker Compose](#configuration-de-docker-compose)
- [Guide étape par étape](#guide-étape-par-étape)
  - [1. Cloner ou télécharger le projet](#1-cloner-ou-télécharger-le-projet)
  - [2. Construire l'image Docker](#2-construire-limage-docker)
  - [3. Démarrer le conteneur via Docker Compose](#3-démarrer-le-conteneur-via-docker-compose)
  - [4. Vérifier et utiliser le cluster Hadoop](#4-vérifier-et-utiliser-le-cluster-hadoop)
  - [5. Accéder aux interfaces web](#5-accéder-aux-interfaces-web)
  - [6. Accéder à SSH via navigateur](#6-accéder-à-ssh-via-navigateur)
  - [7. Arrêter le conteneur](#7-arrêter-le-conteneur)
- [Personnalisation et automatisation](#personnalisation-et-automatisation)
- [Notes complémentaires](#notes-complémentaires)

---

## Prérequis

Avant de commencer, assurez-vous d'avoir :

- **Docker** installé sur votre machine  
  Vérifiez avec la commande :
  ```bash
  docker --version
  ```
- **Docker Compose** installé  
  Vérifiez avec :
  ```bash
  docker-compose --version
  ```
- Un accès Internet pour télécharger les dépendances (Hadoop, scripts de configuration via GitHub).

---

## Structure du projet

Le projet comprend les fichiers suivants :

- **Dockerfile**  
  _Définit la construction de l'image Docker, installe Java, SSH, Hadoop et configure l'environnement._

- **entrypoint.sh**  
  _Script d’entrypoint qui démarre le service SSH, formate le NameNode (si nécessaire) et lance les services HDFS et YARN._

- **docker-compose.yml**  
  _Orchestre le déploiement du conteneur en mappant les ports et en incluant un volume persistant._

- **mapper.py et reducer.py**  
  _Scripts Python pour exécuter des jobs MapReduce via Hadoop Streaming. Ces fichiers sont montés dans le conteneur via Docker Compose._

- **(Optionnel)** Les fichiers de configuration Hadoop (core-site.xml, hdfs-site.xml, mapred-site.xml et yarn-site.xml)  
  _Ces fichiers sont soit téléchargeables depuis un dépôt GitHub, soit placés dans un dossier local et copiés lors de la construction de l’image._

---

## Configuration du Dockerfile

Le Dockerfile de ce projet réalise les actions suivantes :

1. Utilise Ubuntu 20.04 comme image de base en mode non interactif.
2. Installe Java (OpenJDK 11), SSH (client et serveur), wget, tar, net-tools et sed.
3. Configure SSH pour une connexion sans mot de passe (génération de clés RSA).
4. Télécharge et extrait Hadoop 3.3.1 dans le dossier `/opt`, puis crée un lien symbolique `/opt/hadoop`.
5. Définit `HADOOP_HOME` sur `/opt/hadoop` et met à jour le `PATH`.
6. Corrige automatiquement le fichier `bash-hadoop-var.sh` en remplaçant l'ancien chemin par `/opt/hadoop`.
7. Télécharge et place (ou copie) les fichiers de configuration Hadoop.
8. Crée les répertoires de stockage de données pour HDFS (par exemple, `/home/iris/namenode`).
9. Expose les ports des interfaces web d’Hadoop ainsi que celui de SSH.
10. Copie et rend exécutable le script d’entrypoint.

_Note : Nous avons ajouté la définition explicite de JAVA_HOME dans le fichier `hadoop-env.sh` pour que Hadoop trouve le JRE installé._

---

## Le script d’EntryPoint

Le fichier **entrypoint.sh** exécute les actions suivantes lors du démarrage du conteneur :

- Ajoute une entrée dans `/etc/hosts` pour que le nom d'hôte « namenode » se résolve vers `127.0.0.1`.
- Démarre le service SSH.
- Vérifie si le NameNode doit être formaté (le formatage ne s'effectue qu'en l'absence du répertoire `/home/iris/namenode/current` dans le volume persistant).
- Démarre HDFS avec le script `$HADOOP_HOME/sbin/start-dfs.sh`.
- Démarre YARN avec `$HADOOP_HOME/sbin/start-yarn.sh`.
- Lance ensuite la commande par défaut (ici, un `tail` sur `/dev/null` pour maintenir le conteneur actif).

---

## Configuration de Docker Compose

Le fichier **docker-compose.yml** définit le service Hadoop avec :

- Une construction de l'image basée sur le Dockerfile.
- Le mappage de ports :
  - `9870` pour l’interface NameNode.
  - `9864` pour l’interface DataNode.
  - `8088` pour l’interface ResourceManager.
  - `8042` pour l’interface NodeManager.
  - `22` pour SSH.
- Un volume nommé `hadoop_data` pour la persistance des données (ce qui permet notamment d'éviter de reformater le NameNode à chaque redémarrage).
- Le montage des fichiers `mapper.py` et `reducer.py` pour les jobs MapReduce.
- L’affectation du service au réseau dédié `hadoop-net`.

---

## Guide étape par étape

### 1. Cloner ou télécharger le projet

Clonez le dépôt ou téléchargez l'ensemble des fichiers (Dockerfile, entrypoint.sh, docker-compose.yml, mapper.py, reducer.py) dans un répertoire de travail.

Exemple :
```bash
git clone https://votre-depot.git
cd tp-hadoop
```

### 2. Construire l'image Docker

Dans le répertoire racine du projet, exécutez :
```bash
docker build -t hadoop-image .
```
Cette commande télécharge les paquets, installe les dépendances, configure Hadoop et prépare le conteneur.

### 3. Démarrer le conteneur via Docker Compose

Lancez le cluster Hadoop dans un conteneur en exécutant :
```bash
docker-compose up -d
```
Cela crée le conteneur `hadoop-container` et démarre automatiquement le script d’entrypoint pour lancer SSH, HDFS et YARN.

### 4. Vérifier et utiliser le cluster Hadoop

- Pour vous connecter dans le conteneur, utilisez :
  ```bash
  docker exec -it hadoop-container /bin/bash
  ```
- Une fois connecté, vérifiez l’état des services avec la commande :
  ```bash
  jps
  ```
  Vous devriez voir apparaître notamment :
  - **NameNode**
  - **DataNode**
  - **SecondaryNameNode**
  - **ResourceManager**
  - **NodeManager**

### 5. Accéder aux interfaces web

Depuis votre navigateur, vous pouvez consulter les interfaces web de Hadoop :
- **NameNode** : [http://localhost:9870](http://localhost:9870)
- **DataNode** : [http://localhost:9864](http://localhost:9864)
- **ResourceManager (YARN)** : [http://localhost:8088](http://localhost:8088)
- **NodeManager (YARN)** : [http://localhost:8042](http://localhost:8042)

Ces interfaces permettent de surveiller l’état et les tâches du cluster.

### 6. Accéder à SSH via navigateur

Les navigateurs n’utilisent pas le protocole SSH directement. Si vous tentez d’accéder (via HTTPS) à un port SSH (par exemple, en entrant « https://localhost:22 »), vous obtiendrez une erreur ERR_SSL_PROTOCOL_ERROR.

Pour accéder à un terminal SSH via le navigateur, vous devez installer un service de Web Terminal tel que **Shell In A Box**, **Wetty** ou **GateOne**. Par exemple, pour utiliser Shell In A Box :
  
1. **Installation (dans un conteneur complémentaire ou dans le même) :**
   Vous pouvez ajouter à votre Dockerfile l’installation de Shell In A Box :
   ```dockerfile
   RUN apt-get install -y shellinabox
   ```
2. **Configuration :**
   Configurez Shell In A Box pour écouter sur un port (par exemple 4200) en mode non sécurisé (HTTP) ou en générant un certificat pour HTTPS. Une configuration basique pour tester en HTTP peut suffire.  
3. **Exposition du port dans docker-compose.yml :**  
   Ajoutez une entrée de service ou un mapping de port pour Shell In A Box, par exemple :
   ```yaml
   ports:
     - "4200:4200"
   ```
4. **Accès via navigateur :**
   Vous pourrez alors accéder au terminal via l’URL :
   ```
   http://localhost:4200
   ```
  
_Note technique :_  
L’erreur ERR_SSL_PROTOCOL_ERROR survient lorsque le navigateur tente de faire une connexion HTTPS sur un service qui ne supporte pas le protocole SSL/TLS ou qui n’a pas de certificat valide. La mise en place d’un Web Terminal adéquat permet d’éviter ce problème.

### 7. Arrêter le conteneur

Pour arrêter et nettoyer le cluster, exécutez :
```bash
docker-compose down
```
Pour également supprimer les volumes (et ainsi toutes les données Hadoop sauvegardées), utilisez :
```bash
docker-compose down -v
```

---

## Personnalisation et automatisation

- **Variables d'environnement :**  
  Vous pouvez modifier des variables comme `HADOOP_HOME`, `HDFS_NAMENODE_USER`, etc., dans le Dockerfile pour adapter le déploiement.
  
- **EntryPoint personnalisé :**  
  Le script `entrypoint.sh` peut être enrichi pour ajouter des vérifications supplémentaires (par exemple, éviter un formatage intempestif du NameNode).
  
- **Déploiement multi-conteneurs :**  
  Le fichier docker-compose.yml peut être étendu pour déployer séparemment le NameNode, les DataNodes ou d’autres services. Vous pouvez également ajouter des volumes supplémentaires pour la persistance des logs ou des données.

- **Web Terminal pour SSH :**  
  Si vous souhaitez proposer un accès SSH via le navigateur, intégrez un service de Web Terminal (Shell In A Box, Wetty, etc.) dans votre configuration Docker et ajustez l’exposition des ports.

---

## Notes complémentaires

- **Sécurité en production :**  
  L’exécution en tant que root est acceptable pour un environnement de test, mais en production, veillez à utiliser des comptes non privilégiés et à renforcer la sécurité (certificats, firewall, etc.).
  
- **Mises à jour de configurations :**  
  Les fichiers de configuration Hadoop sont fournis depuis le dépôt GitHub original. Vérifiez et adaptez ces fichiers selon vos besoins spécifiques (réplication, chemins de stockage, etc.).
  
- **Extensions possibles :**  
  Ce projet peut évoluer vers un cluster multi-nœuds ou s’intégrer dans un environnement orchestré avec Kubernetes. N’hésitez pas à explorer ces possibilités.

---

Ce README vous guide pas à pas pour déployer et utiliser votre cluster Hadoop dans Docker, tout en vous indiquant comment accéder aux interfaces web et, éventuellement, comment configurer un accès SSH via navigateur. Pour toute question ou suggestion d’amélioration, merci d’ouvrir une issue dans le dépôt.

Bonne expérimentation !