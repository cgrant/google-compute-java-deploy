#! /bin/bash

## This startup script runs ON the compute vm

BUCKET_NAME=your-unique-bucket-name
JAR_NAME=gcedeploy-0.0.1-SNAPSHOT.jar

sudo su -
echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list
echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
apt-get update
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
apt-get install oracle-java8-installer -y

mkdir /opt/gcedeploy
gsutil cp gs://${BUCKET_NAME}/${JAR_NAME} /opt/gcedeploy/${JAR_NAME}
java -jar /opt/gcedeploy/${JAR_NAME} &
exit
