# Add values
# Use the AMI of the custom Ec2 image you previously created
imageid = "ami-09f21dfc5519a063f"
# Use t2.micro for the AWS Free Tier
instance-type          = "t3.micro"
key-name               = "coursera-key"
vpc_security_group_ids = ""
tag-name               = "module-07"
user-sns-topic         = "rayyan-topic-module07"
elb-name               = "rayyan-elb-module07"
tg-name                = "rayyan-tg-module07"
asg-name               = "rayyan-asg-module07"
desired                = 1
min                    = 1
max                    = 2
number-of-azs          = 3
region                 = "us-east-2"
raw-s3-bucket          = "rayyan-raw-s3-bucket-module07"
finished-s3-bucket     = "rayyan-finished-s3-bucket-module07"
sqs-name               = "rayyan-sqs-module07"
dynamodb-name          = "company"
lambda-name            = "rayyan-lambda-module07"
source-account         = "404931288564"
