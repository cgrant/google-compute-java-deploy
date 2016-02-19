# google-compute-java-deploy
Simple scripts to deploy java file on google compute engine

## prerequisites
- Google Cloud Platform account
- gcloud commandline client
- a google project with APIs enabled for compute engine and storage
- java 8
- Maven

## Make a java app
for this example we're going to create a simple spring boot app

Download (start-spring.sh)[https://gist.githubusercontent.com/cgrant/246f00eeff2ac1c05a07/raw/4c479c84c481a367292c9ace29c55cc0d0d587c8/spring-start.sh] to your workspace directory and chmod 775.

Setup a sample project with

  $ start-spring.sh gcedeploy web,actuator
  $ cd gcedeploy
  $ mvn spring-boot:run

Great now that the template works lets be sure we can run it with just java
First add a root context so the app actually returns something

Open src/main/java/com/demo/gcedeploy/GcedeployApp.java and update it to the following

```
package com.demo.gcedeploy;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;


@SpringBootApplication
@RestController
public class GcedeployApp {

	public static void main(String[] args) {
		SpringApplication.run(GcedeployApp.class, args);
	}

	@RequestMapping("/")
  public String hello(){
  	return "hello";
  }
}

```

Package it up

  $ mvn install

And run it

  $ java -jar ./target/gcedeploy-0.0.1-SNAPSHOT.jar

  you should see your app running at http://localhost

## Deploy scripts

This next part is really the point of this demo. Here we're going to do two things. First we need a compute image with java installed so we can run our app. In a production settin gyou'll probably use a pre baked image, but here we'll just use a startup script to install everything

Create an ``install.sh`` file that we'll sed to the new vm and have it execute on startup

It should look like this.
NOTE you'll need to change the BUCKET_NAME var to something just for your use.  

```
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


```
So whats going on here? Most of this is just about downloading oracle java 8

The last 4 lines are the key points. We're copying our jar file form google storage onto this server and running it.

But wait how did the jar get to google storage anyway?

This next script has the fun google bits in it to take care of all that for you

Create a ``start.sh`` an add the following.
NOTE: Again update the first to variables to the same bucket name you used above

```
#! /bin/bash

BUCKET_NAME=your-unique-bucket-name

JAR_NAME=gcedeploy-0.0.1-SNAPSHOT.jar
VM_NAME=gcedeploy

gsutil mb gs://${BUCKET_NAME}
gsutil cp ./target/${JAR_NAME} gs://${BUCKET_NAME}/${JAR_NAME}

gcloud compute firewall-rules create ${VM_NAME}-www --allow tcp:80 --target-tags ${VM_NAME}

gcloud compute instances create ${VM_NAME} \
  --tags ${VM_NAME} \
  --zone us-central1-a  --machine-type n1-standard-1 \
  --metadata-from-file startup-script=install.sh

```

So whats happening here. There are four main things going on. After we set those variables we're workgin with ``gsutil`` part of the gcloud tools you installed previously. This first section is uploading your jar to google storage so our VM can access it. The first line ``gsutil mb gs://${BUCKET_NAME}`` simply tries to make a bucket. After the first run this will error out but the script will continue, thats fine.

The second to last command creates a custom firewall rule for this app to ensure we can access our app.

The last command is creating our instance and on the last line you can see where it passes in our ``install.sh`` script for the vm to use

That should be it lets deploy!

  $ chmod 755 start.sh
  $ ./start.sh

Wait a bit for everything to setup. You'll see the external IP listed in the command completion

After this command comes back the server is still running that script we sent so give it time to load, that java install can take a minute or two. When its done you should see it at ``http://<vm ip address>``

## Cleanup scripts

Ok now lets not forget to cleanup after ourselves go ahead and create a ``stop.sh`` script and copy in the following contents

```
#! /bin/bash
VM_NAME=gcedeploy

gcloud compute firewall-rules delete --quiet ${VM_NAME}-www
gcloud compute instances delete --quiet --zone=us-central1-a ${VM_NAME}

```

Update the permissions and tear it down

  $ chmod 755 stop.sh
  $ ./stop.sh
