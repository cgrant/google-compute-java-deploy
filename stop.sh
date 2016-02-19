#! /bin/bash
VM_NAME=gcedeploy

gcloud compute firewall-rules delete --quiet ${VM_NAME}-www
gcloud compute instances delete --quiet --zone=us-central1-a ${VM_NAME}
