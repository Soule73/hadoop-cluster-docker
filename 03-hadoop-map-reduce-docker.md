# MapReduce avec Docker sur un Cluster Hadoop

L'objectif de ce TP est d'exécuter un job MapReduce sur votre cluster Hadoop Dockerisé en utilisant Hadoop Streaming. Grâce à cette approche, vous pouvez employer des scripts Python comme mappeur et réducteur pour effectuer des traitements distribués.

> **Prérequis :**
> - Avoir déployé votre cluster Hadoop via Docker (cf. [01-installation-hadoop-docker.md](./01-installation-hadoop-docker.md)).
> - Le conteneur doit être démarré et accessible (vérifiez avec `docker-compose up -d`).
> - Les fichiers `mapper.py` et `reducer.py` se trouvent à la racine du projet et sont montés dans le conteneur (par exemple, dans `/opt/hadoop/`).

---

## 1. Hadoop Streaming

Hadoop Streaming est un utilitaire fourni avec Hadoop qui permet de lancer des jobs MapReduce en utilisant des scripts ou des exécutables pour les phases de mapping et de réduction.  
Pour plus d’informations, consultez la [documentation Hadoop Streaming](https://hadoop.apache.org/docs/stable/hadoop-streaming/HadoopStreaming.html).

---

## 2. Exemple Word Count avec Hadoop Streaming

Chaque job MapReduce comporte deux phases :
- **Mappeur**
- **Réducteur**

### a. Les Scripts MapReduce

Les scripts suivants sont déjà inclus dans le projet et montés dans le conteneur via le Docker Compose.

#### Mapper (mapper.py)

Créez (ou vérifiez) le fichier `mapper.py` avec le contenu suivant :

```python
#!/usr/bin/python3
import sys

# Lecture de l'entrée standard, nettoyage et découpage en mots
for line in sys.stdin:
    line = line.strip()
    words = line.split()
    for word in words:
        print("{}\t{}".format(word, "1"))
```

#### Reducer (reducer.py)

Créez (ou vérifiez) le fichier `reducer.py` avec le contenu suivant :

```python
#!/usr/bin/python3
import sys

current_word = None
current_count = 0

# Traitement ligne par ligne de l'entrée standard
for line in sys.stdin:
    line = line.strip()
    word, count = line.split('\t', 1)
    try:
        count = int(count)
    except ValueError:
        continue

    if current_word == word:
        current_count += count
    else:
        if current_word:
            print(current_word, current_count)
        current_word = word
        current_count = count

if current_word is not None:
    print(current_word, current_count)
```

> **Note :**  
> Les fichiers `mapper.py` et `reducer.py` sont montés dans le conteneur (dans `/opt/hadoop/` par exemple), ce qui permet de les mettre à jour directement depuis votre répertoire local.

---

## 3. Tester les Scripts en Local

Avant de soumettre le job via Hadoop, vous pouvez tester la chaîne MapReduce localement dans le conteneur.

### a. Création d'un fichier de test

Depuis votre terminal (sur l’hôte), créez un fichier de test `file.txt` :

```bash
echo "tout est tout
tout bon
tout est mauvais" > file.txt
```

### b. Copier le fichier dans le conteneur

Copiez le fichier `file.txt` dans le conteneur Hadoop (par exemple, dans `/tmp/`) :

```bash
docker cp file.txt hadoop-container:/tmp/file.txt
```

### c. Exécuter la chaîne de traitement

Dans le conteneur, testez les scripts de mapping et de réduction :

```bash
docker exec -it hadoop-container bash -c "cat /tmp/file.txt | python3 /opt/hadoop/mapper.py | sort | python3 /opt/hadoop/reducer.py"
```

La sortie attendue (pour l'exemple utilisé) pourrait être :

```
bon 1
est 2
mauvais 1
tout 4
```

---

## 4. Copier un fichier local sur HDFS

Pour soumettre un job MapReduce, il faut placer vos données dans HDFS.

### a. Créer un répertoire d'entrée sur HDFS

Exécutez dans le conteneur :

```bash
docker exec -it hadoop-container hadoop fs -mkdir -p /input-01
```

### b. Copier le fichier de test dans HDFS

Copiez le fichier `file.txt` (qui se trouve dans `/tmp/` du conteneur) dans le répertoire HDFS :

```bash
docker exec -it hadoop-container hadoop fs -put /tmp/file.txt /input-01
```

---

## 5. Exécuter le Job MapReduce avec Hadoop Streaming

Pour lancer le job sur le fichier placé dans HDFS, exécutez la commande suivante depuis votre hôte. Ici, nous utilisons les chemins absolus pour les fichiers montés :

```bash
docker exec -it hadoop-container bash -c "hadoop jar /opt/hadoop/share/hadoop/tools/lib/hadoop-streaming-3.3.1.jar \
  -files /opt/hadoop/mapper.py,/opt/hadoop/reducer.py \
  -mapper 'python3 /opt/hadoop/mapper.py' \
  -reducer 'python3 /opt/hadoop/reducer.py' \
  -input /input-01 \
  -output /output-01"
```

Après exécution, le résultat sera stocké dans le répertoire `/output-01` de HDFS.

### Vérifier le résultat

Pour consulter la sortie du job :

```bash
docker exec -it hadoop-container hadoop fs -cat /output-01/part-*
```

La sortie doit correspondre aux résultats attendus du comptage des mots.

---

## 6. Test de Performance (Hadoop Perf en Mode Distribué)

Pour mesurer l’impact de Hadoop en mode distribué sur un volume important :

### a. Préparer un fichier volumineux

1. **Télécharger un fichier de test volumineux**

   Téléchargez par exemple le texte des *Misérables* :

   ```bash
   docker exec -it hadoop-container wget https://r-stat-sc-donnees.github.io/LesMiserables1.txt -O /tmp/LesMiserables1.txt
   ```

2. **Créer un très gros fichier**

   Concaténez le fichier 100 fois pour obtenir un gros fichier :

   ```bash
   docker exec -it hadoop-container bash -c "for i in {1..100}; do cat /tmp/LesMiserables1.txt >> /tmp/BigLesMiserables1.txt; done"
   ```

### b. Tester le traitement en mode local

Mesurez le temps d’exécution localement (hors Hadoop) :

```bash
docker exec -it hadoop-container bash -c "time cat /tmp/BigLesMiserables1.txt | python3 /opt/hadoop/mapper.py | sort | python3 /opt/hadoop/reducer.py"
```

Notez le temps affiché pour comparaison.

### c. Exécuter le job MapReduce sur le fichier volumineux

1. **Créer un répertoire d'entrée sur HDFS pour ce test**

   ```bash
   docker exec -it hadoop-container hadoop fs -mkdir -p /input-02
   ```

2. **Copier le gros fichier dans HDFS**

   ```bash
   docker exec -it hadoop-container hadoop fs -put /tmp/BigLesMiserables1.txt /input-02
   ```

3. **Lancer le job MapReduce en mode distribué**

   Par exemple, en utilisant 5 mappers et 5 réducteurs :

   ```bash
   docker exec -it hadoop-container bash -c "hadoop jar /opt/hadoop/share/hadoop/tools/lib/hadoop-streaming-3.3.1.jar \
     -Dmapreduce.job.maps=5 \
     -Dmapreduce.job.reduces=5 \
     -files /opt/hadoop/mapper.py,/opt/hadoop/reducer.py \
     -mapper 'python3 /opt/hadoop/mapper.py' \
     -reducer 'python3 /opt/hadoop/reducer.py' \
     -input /input-02 \
     -output /output-02"
   ```

4. **Vérifier le résultat**

   ```bash
   docker exec -it hadoop-container hadoop fs -cat /output-02/part-*
   ```

---

## Remarques Complémentaires

- **Exécution via Docker Exec :**  
  Toutes les commandes Hadoop sont exécutées dans le conteneur en préfixant vos commandes avec `docker exec -it hadoop-container ...`.

- **Réseau Docker :**  
  Le service Hadoop opère sur un réseau dédié (défini dans `docker-compose.yml`), ce qui facilite la communication inter-conteneurs si le projet évolue vers une architecture multi-nœuds.

- **Personnalisation :**  
  Vous pouvez ajuster le nombre de mappers/réducteurs, modifier les scripts Python, ou adapter la configuration de Hadoop selon vos besoins. Pour visualiser les logs de votre cluster, utilisez :

  ```bash
  docker logs -f hadoop-container
  ```

- **Applications complémentaires :**  
  Ces instructions s'appliquent pour un job MapReduce simple (Word Count). Vous pouvez étendre ce TP pour exécuter d'autres types de traitements ou intégrer votre solution dans un cadre d'orchestration plus large (ex. Kubernetes).

---

Ce guide détaillé vous permettra de tester et valider la fonctionnalité d’un job MapReduce sur votre cluster Hadoop Dockerisé, ainsi que d’évaluer les impacts de performance en mode distribué.  
Bonne expérimentation !
