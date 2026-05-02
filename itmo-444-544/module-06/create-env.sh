#!/bin/bash

##############################################################################
# Module 06 Create Script
# Creates an AWS Secrets Manager secret, RDS MySQL database, and read replica.
##############################################################################

if [ $# = 0 ]
then
  echo "You don't have enough variables in your arguments.txt."
  exit 1
fi

SECRET_ID=$(aws secretsmanager list-secrets \
  --filters Key=name,Values=${21} \
  --query 'SecretList[0].ARN' \
  --output text)

if [ "$SECRET_ID" = "None" ] || [ "$SECRET_ID" = "" ]
then
  echo "Secret ${21} does not exist."
  echo "Run: bash ./create-secrets.sh \$(< ~/arguments.txt)"
  exit 1
fi

USERVALUE=$(aws secretsmanager get-secret-value \
  --secret-id $SECRET_ID \
  --query 'SecretString' \
  --output text | jq -r '.user')

PASSVALUE=$(aws secretsmanager get-secret-value \
  --secret-id $SECRET_ID \
  --query 'SecretString' \
  --output text | jq -r '.pass')

echo "Creating RDS MySQL instance: ${22}..."
aws rds create-db-instance \
  --db-instance-identifier ${22} \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --master-username $USERVALUE \
  --master-user-password $PASSVALUE \
  --allocated-storage 20 \
  --db-name ${22} \
  --vpc-security-group-ids ${4} \
  --backup-retention-period 1 \
  --no-publicly-accessible \
  --deletion-protection false \
  --tags Key=assessment,Value=${7}

echo "Waiting for RDS instance ${22} to become available..."
aws rds wait db-instance-available --db-instance-identifier ${22}

echo "Creating RDS read replica: ${22}-read-replica..."
aws rds create-db-instance-read-replica \
  --db-instance-identifier ${22}-read-replica \
  --source-db-instance-identifier ${22} \
  --db-instance-class db.t3.micro \
  --no-publicly-accessible \
  --tags Key=assessment,Value=${7}

echo "Waiting for RDS read replica ${22}-read-replica to become available..."
aws rds wait db-instance-available --db-instance-identifier ${22}-read-replica

echo "Retrieving RDS Endpoint Address..."
RDS_Address=$(aws rds describe-db-instances \
  --db-instance-identifier ${22} \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)
echo $RDS_Address

echo "Retrieving RDS Read Replica Endpoint Address..."
RDS_RR_Address=$(aws rds describe-db-instances \
  --db-instance-identifier ${22}-read-replica \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)
echo $RDS_RR_Address

echo "Module 6 create script finished."