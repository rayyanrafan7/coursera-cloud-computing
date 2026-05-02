#!/bin/bash
##############################################################################
# Module-03 Destroy Script
# This script deletes/terminates resources created for Module 3:
# EC2 instances, target group, and load balancer.
##############################################################################

echo "Beginning destroy script for module-03..."

TAGNAME="module3-tag"
TARGETGROUPNAME="rr-tg"
ELBNAME="rr-elb"

echo "Finding running/pending EC2 instances with tag $TAGNAME..."
INSTANCEIDS=$(aws ec2 describe-instances \
  --output text \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --filters "Name=instance-state-name,Values=running,pending" "Name=tag:Name,Values=$TAGNAME")

echo $INSTANCEIDS

echo "Finding target group ARN..."
TARGETARN=$(aws elbv2 describe-target-groups \
  --names $TARGETGROUPNAME \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text 2>/dev/null)

echo $TARGETARN

if [ "$TARGETARN" != "" ] && [ "$TARGETARN" != "None" ]
then
  echo "Deregistering targets from target group..."
  INSTANCEIDSARRAY=($INSTANCEIDS)

  for INSTANCEID in ${INSTANCEIDSARRAY[@]};
  do
    echo "Deregistering $INSTANCEID..."
    aws elbv2 deregister-targets \
      --target-group-arn $TARGETARN \
      --targets Id=$INSTANCEID
  done
else
  echo "No target group found to deregister targets from."
fi

if [ "$INSTANCEIDS" != "" ]
then
  echo "Terminating EC2 instances..."
  aws ec2 terminate-instances --instance-ids $INSTANCEIDS

  echo "Waiting for instances to terminate..."
  aws ec2 wait instance-terminated --instance-ids $INSTANCEIDS
else
  echo "There are no running or pending instances to terminate..."
fi

echo "Finding load balancer ARN..."
ELBARN=$(aws elbv2 describe-load-balancers \
  --names $ELBNAME \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text 2>/dev/null)

echo $ELBARN

if [ "$ELBARN" != "" ] && [ "$ELBARN" != "None" ]
then
  echo "Deleting load balancer..."
  aws elbv2 delete-load-balancer --load-balancer-arn $ELBARN

  echo "Waiting for load balancer to be deleted..."
  aws elbv2 wait load-balancers-deleted --load-balancer-arns $ELBARN
else
  echo "No load balancer found to delete."
fi

if [ "$TARGETARN" != "" ] && [ "$TARGETARN" != "None" ]
then
  echo "Deleting target group..."
  aws elbv2 delete-target-group --target-group-arn $TARGETARN
else
  echo "No target group found to delete."
fi

echo "Finished destroying module-03 resources..."