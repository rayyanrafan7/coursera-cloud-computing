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

  BASECONVERT=$(base64 -w 0 < ${6})

  cat > config.json << EOF
{
  "ImageId": "${1}",
  "InstanceType": "${2}",
  "KeyName": "${3}",
  "SecurityGroupIds": ["${4}"],
  "UserData": "$BASECONVERT",
  "BlockDeviceMappings": [
    {
      "DeviceName": "/dev/sdc",
      "Ebs": {
        "VolumeSize": ${18},
        "VolumeType": "gp3",
        "DeleteOnTermination": true
      }
    }
  ],
  "TagSpecifications": [
    {
      "ResourceType": "instance",
      "Tags": [
        {
          "Key": "Name",
          "Value": "${7}"
        }
      ]
    },
    {
      "ResourceType": "volume",
      "Tags": [
        {
          "Key": "Name",
          "Value": "${7}"
        }
      ]
    }
  ]
}
EOF

  echo "config.json created successfully..."
  cat config.json
fi