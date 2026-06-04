#!/bin/bash
AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0612c2743325d86f2"
INSTANCES=(mongodb redis mysql rabbitmq user cart shipping payment frontend)
ZONE_ID="Z07326652S3C1APEMRAGS"
DOMAIN_NAME="daws-84s.bond"
echo "let's create instances"

for instance in $@
do 
  INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance, Tags=[{Key=Name, Value=$instance}]" --query "Instances[0].InstanceId" --output text)
  echo "$instance id is: $INSTANCE_ID"
  if [ $instance != "frontend" ]
  then
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
    RECORD_NAME="$instance.$DOMAIN_NAME"
  else
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
    RECORD_NAME="$DOMAIN_NAME"
  fi
  echo "$instance ip address: $IP"

  aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '{
        "Comment": "Creating or updating record",
        "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": "'$RECORD_NAME'",
            "Type": "A",
            "TTL": 60,
            "ResourceRecords": [{ "Value": "'$IP'" }]
            }
        }]
    }'
done



