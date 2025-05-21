# Utilisation d'une image de base Ubuntu
FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# Définition de JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Installation de Java, SSH, wget, tar, net-tools et sed
RUN apt-get update && apt-get install -y \
    openjdk-11-jre-headless \
    openssh-server \
    openssh-client \
    wget \
    tar \
    net-tools \
    sed && \
    mkdir /var/run/sshd

# Configuration de SSH pour autoriser l'accès sans mot de passe
RUN ssh-keygen -t rsa -P '' -f /root/.ssh/id_rsa && \
    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys && \
    chmod 0600 /root/.ssh/authorized_keys

# Téléchargement et extraction d'Hadoop, puis création d'un lien symbolique
RUN wget https://archive.apache.org/dist/hadoop/common/hadoop-3.3.1/hadoop-3.3.1.tar.gz -P /opt && \
    cd /opt && tar -xzvf hadoop-3.3.1.tar.gz && \
    ln -s hadoop-3.3.1 hadoop

# Définition de HADOOP_HOME et mise à jour du PATH
ENV HADOOP_HOME=/opt/hadoop
ENV PATH=${PATH}:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin

# Autoriser l'exécution des services HDFS et YARN en tant que root
ENV HDFS_NAMENODE_USER=root \
    HDFS_DATANODE_USER=root \
    HDFS_SECONDARYNAMENODE_USER=root \
    YARN_RESOURCEMANAGER_USER=root \
    YARN_NODEMANAGER_USER=root

# Téléchargement du script de configuration et correction de HADOOP_HOME dans ce script
RUN wget https://raw.githubusercontent.com/elomedah/iris-big-data/master/TP-hadoop/bash-hadoop-var.sh -O /root/bash-hadoop-var.sh && \
    sed -i 's|\$HOME/hadoop-3.3.1|/opt/hadoop|g' /root/bash-hadoop-var.sh && \
    cat /root/bash-hadoop-var.sh >> /root/.bashrc

# Ajout des fichiers de configuration Hadoop
COPY hadoop/hadoop-env-var.properties ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
COPY hadoop/core-site-local.xml ${HADOOP_HOME}/etc/hadoop/core-site.xml
COPY hadoop/hdfs-site-local.xml ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml
COPY hadoop/mapred-site-local.xml ${HADOOP_HOME}/etc/hadoop/mapred-site.xml
COPY hadoop/yarn-site-local.xml ${HADOOP_HOME}/etc/hadoop/yarn-site.xml

# Ajout explicite de JAVA_HOME dans hadoop-env.sh
RUN echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh

# Création des dossiers nécessaires pour HDFS
RUN mkdir -p /home/iris/tmpdata && \
    mkdir -p /home/iris/namenode && \
    mkdir -p /home/iris/datanode

# Exposition des ports pour les interfaces web et SSH
EXPOSE 9870 9864 8088 8042 22

# Copie du script d'entrypoint qui lancera SSH, HDFS et YARN
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Lancement de l'entrypoint par défaut
ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
