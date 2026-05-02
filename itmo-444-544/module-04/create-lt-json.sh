#!/bin/bash

ltconfigfile="./config.json"

if [ -a $ltconfigfile ]
then
  echo "You have already created the launch-template-data file ./config.json..."
  exit 1
elif [ $# = 0 ]
then
  echo "You don't have enough variables in your arguments.txt, perhaps you forgot to run: bash ./create-lt-json.sh $(< ~/arguments.txt)"
  exit 1
else
  echo 'Creating launch template data file ./config.json...'

  echo "Finding and storing the subnet IDs for defined in arguments.txt Availability Zone 1 and 2..."
  SUBNET2A=$(aws ec2 describe-subnets --output text --query 'Subnets[0].SubnetId' --filters "Name=availability-zone,Values=${10}" "Name=default-for-az,Values=true")
  SUBNET2B=$(aws ec2 describe-subnets --output text --query 'Subnets[0].SubnetId' --filters "Name=availability-zone,Values=${11}" "Name=default-for-az,Values=true")
  echo $SUBNET2A
  echo $SUBNET2B

  cat > config.json << EOF
{
  "ImageId": "$1",
  "InstanceType": "$2",
  "KeyName": "$3",
  "SecurityGroupIds": ["$4"],
  "UserData": "$(base64 -w 0 $6)",
  "TagSpecifications": [
    {
      "ResourceType": "instance",
      "Tags": [
        {
          "Key": "Name",
          "Value": "$7"
        }
      ]
    }
  ]
}
EOF

  echo "config.json created successfully..."
  cat config.json
fi