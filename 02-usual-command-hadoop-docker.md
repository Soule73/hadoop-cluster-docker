# Hadoop Commandes Usuelles via Docker

## Contexte

Dans cet environnement Docker, toutes les commandes Hadoop doivent être exécutées dans le conteneur (nommé ici `hadoop-container`). Pour ce faire, il vous suffit de préfixer vos commandes avec :

```bash
docker exec -it hadoop-container <commande-Hadoop>
```

Deux syntaxes existent pour travailler avec les systèmes de fichiers Hadoop :

- **Syntaxe `hadoop fs`** :  
  Permet d’interagir avec tout type de système de fichiers (HDFS, S3, local, …).

- **Syntaxe `hdfs dfs`** :  
  Spécifique à HDFS.

---

## Commandes de Gestion de Fichiers

### Créer un dossier dans HDFS

**Commande :**
```bash
docker exec -it hadoop-container hadoop fs -mkdir [-p] <paths>
```

**Exemples :**
```bash
docker exec -it hadoop-container hadoop fs -mkdir /monDossier
docker exec -it hadoop-container hadoop fs -mkdir -p /user/monDossier1 /user/monDossier2 /user/monDossier3
```

> **Note :**  
> L’option `-p` permet de créer les dossiers parents manquants lors de la création d’un sous-répertoire.

---

### Lister le contenu d’un dossier

**Commande :**
```bash
docker exec -it hadoop-container hadoop fs -ls <path>
```

**Exemple :**
```bash
docker exec -it hadoop-container hadoop fs -ls /user
```

---

### Exporter (télécharger) un ou plusieurs fichiers de HDFS vers le système local

**Commande :**
```bash
docker exec -it hadoop-container hadoop fs -get [-ignorecrc] [-crc] <src> <localdst>
```

**Exemple :**
```bash
docker exec -it hadoop-container hadoop fs -get /user/monDossier/monFichier.txt /home
```

---

### Charger (téléverser) un ou plusieurs fichiers du système local vers HDFS

**Commande :**
```bash
docker exec -it hadoop-container hadoop fs -put <localsrc> ... <dst>
```

**Exemple :**
```bash
docker exec -it hadoop-container hadoop fs -put /home/monFichier.txt /user/monDossier
```

---

### Alternative pour Exporter un fichier depuis HDFS (copyToLocal)

**Commande :**
```bash
docker exec -it hadoop-container hadoop fs -copyToLocal [-ignorecrc] [-crc] <src> <localdst>
```

**Exemple :**
```bash
docker exec -it hadoop-container hadoop fs -copyToLocal /user/monDossier/monFichier.txt /home
```

---

### Alternative pour Charger un fichier vers HDFS (copyFromLocal)

**Commande :**
```bash
docker exec -it hadoop-container hadoop fs -copyFromLocal <localsrc> <dst>
```

**Exemple :**
```bash
docker exec -it hadoop-container hadoop fs -copyFromLocal /home/monFichier.txt /user/monDossier
```

---

### Déplacer un ou plusieurs fichiers dans HDFS

**Commande :**
```bash
docker exec -it hadoop-container hadoop fs -mv <src URI> [<src URI> ...] <dest>
```

**Exemple :**
```bash
docker exec -it hadoop-container hadoop fs -mv /user/monDossier1/monFichier.txt /user/monDossier2
```

---

### Copier un ou plusieurs fichiers dans HDFS

**Commande :**
```bash
docker exec -it hadoop-container hadoop fs -cp [-f] <src URI> [<src URI> ...] <dest>
```

**Exemple :**
```bash
docker exec -it hadoop-container hadoop fs -cp /user/monDossier1/monFichier.txt /user/monDossier2
```

---

### Afficher le contenu d’un fichier

**Commande :**
```bash
docker exec -it hadoop-container hadoop fs -cat <src URI> [<src URI> ...]
```

**Exemple :**
```bash
docker exec -it hadoop-container hadoop fs -cat /user/monFichier.txt
```

---

### Afficher l’aide concernant une commande

Pour obtenir la description d’une commande ainsi que ses arguments :

**Commande :**
```bash
docker exec -it hadoop-container hadoop fs -help <commande>
```

**Exemple :**
```bash
docker exec -it hadoop-container hadoop fs -help stat
```

---

## Récapitulatif

Vous pouvez désormais gérer vos fichiers dans HDFS en utilisant les commandes Hadoop via Docker en exécutant :

```bash
docker exec -it hadoop-container <commande Hadoop>
```

N’hésitez pas à consulter l’aide des commandes (`-help`) pour plus de détails sur les options disponibles. Ces commandes vous permettront de manipuler vos répertoires et fichiers dans HDFS de manière simple et efficace, directement depuis votre machine hôte.