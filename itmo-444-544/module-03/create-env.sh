#!/bin/bash
##############################################################################
# Module-03
# Launch 3 EC2 instances, register them with a target group,
# and attach the target group to an Elastic Load Balancer.
##############################################################################

if [ $# = 0 ]
then
  echo 'You do not have enough variables in your arguments.txt, perhaps you forgot to run: bash ./create-env.sh $(< ~/arguments.txt)'
  exit 1
else

echo "Finding and storing default VPCID value..."
VPCID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query "Vpcs[0].VpcId" --output text)
echo $VPCID

echo "Finding and storing the subnet IDs for Availability Zone 1 and 2..."
SUBNET2A=$(aws ec2 describe-subnets --query 'Subnets[0].SubnetId' --output text --filters "Name=availability-zone,Values=${10}" "Name=default-for-az,Values=true")
SUBNET2B=$(aws ec2 describe-subnets --query 'Subnets[0].SubnetId' --output text --filters "Name=availability-zone,Values=${11}" "Name=default-for-az,Values=true")
echo $SUBNET2A
echo $SUBNET2B

echo 'Creating the TARGET GROUP and storing the ARN in $TARGETARN...'
TARGETARN=$(aws elbv2 create-target-group \
  --name $8 \
  --protocol HTTP \
  --port 80 \
  --vpc-id $VPCID \
  --target-type instance \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)
echo $TARGETARN

echo "Creating ELBv2 Elastic Load Balancer..."
ELBARN=$(aws elbv2 create-load-balancer \
  --name $9 \
  --subnets $SUBNET2A $SUBNET2B \
  --security-groups $4 \
  --scheme internet-facing \
  --type application \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)
echo $ELBARN

echo "Waiting for load balancer to be available..."
aws elbv2 wait load-balancer-available --load-balancer-arns $ELBARN
echo "Load balancer available..."

echo "Creating listener on port 80..."
aws elbv2 create-listener \
  --load-balancer-arn $ELBARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TARGETARN

echo "Beginning to create and launch instances..."
aws ec2 run-instances \
  --image-id $1 \
  --instance-type $2 \
  --key-name $3 \
  --security-group-ids $4 \
  --count $5 \
  --user-data file://$6 \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$7}]"

echo "Collecting Instance IDs..."
INSTANCEIDS=$(aws ec2 describe-instances \
  --output text \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --filters "Name=instance-state-name,Values=running,pending" "Name=tag:Name,Values=$7")

echo "Waiting until instances are in the RUNNING state..."
echo $INSTANCEIDS

if [ "$INSTANCEIDS" != "" ]
then
  aws ec2 wait instance-running --instance-ids $INSTANCEIDS
  echo "Instances are running."

  echo "$INSTANCEIDS to be registered with the target group..."
  INSTANCEIDSARRAY=($INSTANCEIDS)

  for INSTANCEID in ${INSTANCEIDSARRAY[@]};
  do
    echo "Registering $INSTANCEID with target group..."
    aws elbv2 register-targets \
      --target-group-arn $TARGETARN \
      --targets Id=$INSTANCEID
  done
else
  echo "There are no running or pending instances in INSTANCEIDS to wait for..."
fi

echo "Retrieving ELB URL..."
URL=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns $ELBARN \
  --query 'LoadBalancers[0].DNSName' \
  --output text)
echo $URL

fi