#!/bin/bash
##############################################################################
# Module-05 Destroy Script
# Deletes S3 objects/buckets, ASGs, EC2 instances, ELBs, target groups,
# launch templates, and config.json.
##############################################################################

echo "Beginning destroy script for module-05 assessment..."

TAGNAME="module5-tag"
ltconfigfile="./config.json"

echo "Deleting S3 objects and buckets..."
BUCKETS=$(aws s3api list-buckets --query 'Buckets[*].Name' --output text)

if [ "$BUCKETS" != "" ]
then
  for BUCKET in $BUCKETS
  do
    echo "Emptying bucket: $BUCKET"
    aws s3 rm s3://$BUCKET --recursive

    echo "Deleting bucket: $BUCKET"
    aws s3api delete-bucket --bucket $BUCKET

    echo "Waiting for bucket to be deleted: $BUCKET"
    aws s3api wait bucket-not-exists --bucket $BUCKET
  done
else
  echo "No S3 buckets found."
fi

echo "Finding Auto Scaling Groups..."
ASGNAMES=$(aws autoscaling describe-auto-scaling-groups \
  --query 'AutoScalingGroups[*].AutoScalingGroupName' \
  --output text)

if [ "$ASGNAMES" != "" ]
then
  for ASGNAME in $ASGNAMES
  do
    echo "Setting Auto Scaling Group to 0 capacity: $ASGNAME"
    aws autoscaling update-auto-scaling-group \
      --auto-scaling-group-name $ASGNAME \
      --min-size 0 \
      --max-size 0 \
      --desired-capacity 0

    echo "Deleting Auto Scaling Group: $ASGNAME"
    aws autoscaling delete-auto-scaling-group \
      --auto-scaling-group-name $ASGNAME \
      --force-delete
  done
else
  echo "No Auto Scaling Groups found."
fi

echo "Waiting for Auto Scaling cleanup..."
sleep 90

echo "Finding running or pending EC2 instances with tag $TAGNAME..."
INSTANCEIDS=$(aws ec2 describe-instances \
  --output text \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --filters "Name=instance-state-name,Values=running,pending" "Name=tag:Name,Values=$TAGNAME")

echo $INSTANCEIDS

if [ "$INSTANCEIDS" != "" ]
then
  echo "Terminating remaining EC2 instances..."
  aws ec2 terminate-instances --instance-ids $INSTANCEIDS

  echo "Waiting for EC2 instances to terminate..."
  aws ec2 wait instance-terminated --instance-ids $INSTANCEIDS
else
  echo "No running or pending EC2 instances found."
fi

echo "Finding Load Balancers..."
ELBARNS=$(aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].LoadBalancerArn' \
  --output text 2>/dev/null)

if [ "$ELBARNS" != "" ]
then
  for ELBARN in $ELBARNS
  do
    echo "Deleting Load Balancer: $ELBARN"
    aws elbv2 delete-load-balancer --load-balancer-arn $ELBARN
  done

  echo "Waiting for Load Balancers to be deleted..."
  aws elbv2 wait load-balancers-deleted --load-balancer-arns $ELBARNS
else
  echo "No Load Balancers found."
fi

echo "Waiting before deleting target groups..."
sleep 30

echo "Finding Target Groups..."
TARGETARNS=$(aws elbv2 describe-target-groups \
  --query 'TargetGroups[*].TargetGroupArn' \
  --output text 2>/dev/null)

if [ "$TARGETARNS" != "" ]
then
  for TARGETARN in $TARGETARNS
  do
    echo "Deleting Target Group: $TARGETARN"
    aws elbv2 delete-target-group --target-group-arn $TARGETARN
  done
else
  echo "No Target Groups found."
fi

echo "Finding Launch Templates..."
LAUNCHTEMPLATES=$(aws ec2 describe-launch-templates \
  --query 'LaunchTemplates[*].LaunchTemplateName' \
  --output text 2>/dev/null)

if [ "$LAUNCHTEMPLATES" != "" ]
then
  for LAUNCHTEMPLATE in $LAUNCHTEMPLATES
  do
    echo "Deleting Launch Template: $LAUNCHTEMPLATE"
    aws ec2 delete-launch-template --launch-template-name $LAUNCHTEMPLATE
  done
else
  echo "No Launch Templates found."
fi

echo "Finding Launch template configuration file: $ltconfigfile..."
if [ -a $ltconfigfile ]
then
  echo "Deleting Launch template configuration file: $ltconfigfile..."
  rm $ltconfigfile
  echo "Deleted Launch template configuration file: $ltconfigfile..."
else
  echo "Launch template configuration file: $ltconfigfile doesn't exist, moving on..."
fi

echo "Finished destroying module-05 resources..."