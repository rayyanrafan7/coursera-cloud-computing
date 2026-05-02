#!/bin/bash
##############################################################################
# Module-04 Destroy Script
# Deletes Auto Scaling Group, Launch Template, EC2 instances,
# Load Balancer, Target Group, and config.json.
##############################################################################

echo "Beginning destroy script for module-04..."

TAGNAME="module4-tag"
TARGETGROUPNAME="rr-tg4"
ELBNAME="rr-elb4"
LAUNCHTEMPLATENAME="rr-lt4"
ASGNAME="rr-asg4"
ltconfigfile="./config.json"

echo "Finding Auto Scaling Group..."
ASGEXISTS=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $ASGNAME \
  --query 'AutoScalingGroups[0].AutoScalingGroupName' \
  --output text 2>/dev/null)

echo $ASGEXISTS

if [ "$ASGEXISTS" != "" ] && [ "$ASGEXISTS" != "None" ]
then
  echo "Setting Auto Scaling Group desired/min/max capacity to 0..."
  aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name $ASGNAME \
    --min-size 0 \
    --max-size 0 \
    --desired-capacity 0

  echo "Waiting for Auto Scaling Group instances to terminate..."
  sleep 90

  echo "Deleting Auto Scaling Group..."
  aws autoscaling delete-auto-scaling-group \
    --auto-scaling-group-name $ASGNAME \
    --force-delete
else
  echo "No Auto Scaling Group found."
fi

echo "Finding running/pending EC2 instances with tag $TAGNAME..."
INSTANCEIDS=$(aws ec2 describe-instances \
  --output text \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --filters "Name=instance-state-name,Values=running,pending" "Name=tag:Name,Values=$TAGNAME")

echo $INSTANCEIDS

if [ "$INSTANCEIDS" != "" ]
then
  echo "Terminating remaining EC2 instances..."
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

echo "Finding target group ARN..."
TARGETARN=$(aws elbv2 describe-target-groups \
  --names $TARGETGROUPNAME \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text 2>/dev/null)

echo $TARGETARN

if [ "$TARGETARN" != "" ] && [ "$TARGETARN" != "None" ]
then
  echo "Deleting target group..."
  aws elbv2 delete-target-group --target-group-arn $TARGETARN
else
  echo "No target group found to delete."
fi

echo "Deleting launch template..."
aws ec2 delete-launch-template \
  --launch-template-name $LAUNCHTEMPLATENAME 2>/dev/null

echo "Finding Launch template configuration file: $ltconfigfile..."
if [ -a $ltconfigfile ]
then
  echo "Deleting Launch template configuration file: $ltconfigfile..."
  rm $ltconfigfile
  echo "Deleted Launch template configuration file: $ltconfigfile..."
else
  echo "Launch template configuration file: $ltconfigfile doesn't exist, moving on..."
fi

echo "Finished destroying module-04 resources..."