#!/bin/bash

##############################################################################
# Module 06 Destroy Script
# Deletes RDS read replica, RDS primary database, and secret.
##############################################################################

echo "Beginning Module 6 destroy script..."

echo "Finding RDS read replicas..."
REPLICAS=$(aws rds describe-db-instances \
  --query 'DBInstances[?ReadReplicaSourceDBInstanceIdentifier!=`null`].DBInstanceIdentifier' \
  --output text)

if [ "$REPLICAS" != "" ]
then
  for DB in $REPLICAS
  do
    echo "Deleting read replica: $DB"
    aws rds delete-db-instance \
      --db-instance-identifier $DB \
      --skip-final-snapshot \
      --delete-automated-backups \
      --no-cli-pager

    echo "Waiting for read replica $DB to delete..."
    aws rds wait db-instance-deleted \
      --db-instance-identifier $DB \
      --no-cli-pager
  done
else
  echo "No read replicas found."
fi

echo "Finding primary RDS instances..."
PRIMARYDBS=$(aws rds describe-db-instances \
  --query 'DBInstances[?ReadReplicaSourceDBInstanceIdentifier==`null`].DBInstanceIdentifier' \
  --output text)

if [ "$PRIMARYDBS" != "" ]
then
  for DB in $PRIMARYDBS
  do
    echo "Deleting primary RDS instance: $DB"
    aws rds delete-db-instance \
      --db-instance-identifier $DB \
      --skip-final-snapshot \
      --delete-automated-backups \
      --no-cli-pager

    echo "Waiting for primary RDS instance $DB to delete..."
    aws rds wait db-instance-deleted \
      --db-instance-identifier $DB \
      --no-cli-pager
  done
else
  echo "No primary RDS instances found."
fi

echo "Finding Module 6 secret..."
SECRET_NAME=$(aws secretsmanager list-secrets \
  --query 'SecretList[?Name==`rr-secret6`].Name | [0]' \
  --output text)

if [ "$SECRET_NAME" != "None" ] && [ "$SECRET_NAME" != "" ]
then
  echo "Deleting secret: $SECRET_NAME"
  aws secretsmanager delete-secret \
    --secret-id $SECRET_NAME \
    --force-delete-without-recovery
else
  echo "No Module 6 secret found."
fi

echo "Module 6 deletion finished."