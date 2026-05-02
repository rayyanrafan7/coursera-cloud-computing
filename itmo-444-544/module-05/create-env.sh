#!/bin/bash
##############################################################################
# Module-05 Create Script
# Creates launch template, ASG, target group, load balancer, EBS mapping, and S3.
##############################################################################

ltconfigfile="./config.json"

if [ $# = 0 ]
then
  echo "You don't have enough variables in your arguments.txt, perhaps you forgot to run: bash ./create-env.sh $(< ~/arguments.txt)"
  exit 1
elif ! [[ -a $ltconfigfile ]]
then
  echo "The launch template configuration JSON file doesn't exist."
  echo "Run: bash ./create-lt-json.sh $(< ~/arguments.txt)"
  exit 1
else

echo "Launch template data file: $ltconfigfile exists..."

echo "Finding and storing default VPCID value..."
VPCID=$(aws ec2 describe-vpcs \
  --filters "Name=is-default,Values=true" \
  --query "Vpcs[0].VpcId" \
  --output text)
echo $VPCID

echo "Finding and storing the subnet IDs for Availability Zone 1 and 2..."
SUBNET2A=$(aws ec2 describe-subnets \
  --query 'Subnets[0].SubnetId' \
  --output text \
  --filters "Name=availability-zone,Values=${10}" "Name=default-for-az,Values=true")

SUBNET2B=$(aws ec2 describe-subnets \
  --query 'Subnets[0].SubnetId' \
  --output text \
  --filters "Name=availability-zone,Values=${11}" "Name=default-for-az,Values=true")

echo $SUBNET2A
echo $SUBNET2B

echo "Creating the AutoScalingGroup Launch Template..."
aws ec2 create-launch-template \
  --launch-template-name ${12} \
  --version-description AutoScalingVersion1 \
  --launch-template-data file://config.json \
  --region ${17}

echo "Launch Template created..."

echo "Creating the TARGET GROUP and storing the ARN in TARGETARN..."
TARGETARN=$(aws elbv2 create-target-group \
  --name ${8} \
  --protocol HTTP \
  --port 80 \
  --vpc-id $VPCID \
  --target-type instance \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)
echo $TARGETARN

echo "Creating ELBv2 Elastic Load Balancer..."
ELBARN=$(aws elbv2 create-load-balancer \
  --name ${9} \
  --subnets $SUBNET2A $SUBNET2B \
  --security-groups ${4} \
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

echo "Creating Auto Scaling Group..."
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name ${13} \
  --launch-template LaunchTemplateName=${12},Version='$Latest' \
  --min-size ${14} \
  --max-size ${15} \
  --desired-capacity ${16} \
  --target-group-arns $TARGETARN \
  --vpc-zone-identifier "$SUBNET2A,$SUBNET2B" \
  --tags Key=Name,Value=${7},PropagateAtLaunch=true

echo "Waiting for Auto Scaling Group to create EC2 instances..."
sleep 120

echo "Collecting Instance IDs..."
INSTANCEIDS=$(aws ec2 describe-instances \
  --output text \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --filters "Name=instance-state-name,Values=running,pending" "Name=tag:Name,Values=${7}")

echo $INSTANCEIDS

if [ "$INSTANCEIDS" != "" ]
then
  echo "Waiting until instances are in RUNNING state..."
  aws ec2 wait instance-running --instance-ids $INSTANCEIDS
  echo "Instances are running."
else
  echo "There are no running or pending instances to wait for..."
fi

echo "Waiting for targets to become healthy..."
aws elbv2 wait target-in-service --target-group-arn $TARGETARN
echo "Targets are healthy."

echo "Creating S3 bucket: ${19}..."
aws s3api create-bucket \
  --bucket ${19} \
  --region ${17} \
  --create-bucket-configuration LocationConstraint=${17}

echo "Creating S3 bucket: ${20}..."
aws s3api create-bucket \
  --bucket ${20} \
  --region ${17} \
  --create-bucket-configuration LocationConstraint=${17}

echo "Preparing upload files..."
mkdir -p ./images

if [ ! -f ./images/illinoistech.png ]; then echo "module5 file 1" > ./images/illinoistech.png; fi
if [ ! -f ./images/rohit.jpg ]; then echo "module5 file 2" > ./images/rohit.jpg; fi
if [ ! -f ./images/elevate.webp ]; then echo "module5 file 3" > ./images/elevate.webp; fi
if [ ! -f ./images/ranking.jpg ]; then echo "module5 file 4" > ./images/ranking.jpg; fi

echo "Uploading two objects to bucket ${19}..."
aws s3 cp ./images/illinoistech.png s3://${19}/illinoistech.png
aws s3 cp ./images/rohit.jpg s3://${19}/rohit.jpg

echo "Uploading two objects to bucket ${20}..."
aws s3 cp ./images/elevate.webp s3://${20}/elevate.webp
aws s3 cp ./images/ranking.jpg s3://${20}/ranking.jpg

echo "Listing content of bucket ${19}..."
aws s3 ls s3://${19}

echo "Listing content of bucket ${20}..."
aws s3 ls s3://${20}

echo "Retrieving ELB URL..."
URL=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns $ELBARN \
  --query 'LoadBalancers[0].DNSName' \
  --output text)
echo $URL

fi