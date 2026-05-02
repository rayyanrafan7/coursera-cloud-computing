#!/bin/bash

if [ $# = 0 ]
then
  echo "You don't have enough variables in your arguments.txt."
  exit 1
fi

echo "Creating AWS secret: ${21}..."

aws secretsmanager create-secret \
  --name ${21} \
  --secret-string file://maria.json

echo "Secret created or already exists."

SECRET_ID=$(aws secretsmanager list-secrets \
  --filters Key=name,Values=${21} \
  --query 'SecretList[0].ARN' \
  --output text)

USERVALUE=$(aws secretsmanager get-secret-value \
  --secret-id $SECRET_ID \
  --query 'SecretString' \
  --output text | jq -r '.user')

PASSVALUE=$(aws secretsmanager get-secret-value \
  --secret-id $SECRET_ID \
  --query 'SecretString' \
  --output text | jq -r '.pass')

echo "Secret username: $USERVALUE"
echo "Secret password retrieved."