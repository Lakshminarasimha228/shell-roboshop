#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-08bc24a4224bdfca5"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID=("Z04271653U7W4X8SKWK80")
DOMAIN_NAME=("lakshmi.cyou")

for instance in ${INSTANCE[@]}
do 
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t2.
    micro --security-group-ids sg-08bc24a4224bdfca5 --tag-specifications
    "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" --query "Instances[0].InstanceId"
    --output text)
    if [ $instance =! "frontend" ]
    then
        IP=$(aws ec2 describe-instances --instances -instance-ids $INSTANCE_ID --query "Resrevation[0].
        Instances[0].PrivateIpAddress" --output text)
    else
         IP=$(aws ec2 describe-instances --instances -instance-ids $INSTANCE_ID --query "Resrevation[0].
        Instances[0].PublicIpAddress" --output text)
    fi
    echo "$instance IP address: $IP"    
done