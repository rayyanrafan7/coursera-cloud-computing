# Add values
# Find the Ubuntu server 22.04 AMI for your region at this URL
# https://cloud-images.ubuntu.com/locator/ec2/

imageid                = ""
instance-type          = "t3.micro"
key-name               = "coursera-key"
vpc_security_group_ids = ""
tag-name               = "module-04"
raw-s3                 = "rayyan-raw-s3-module04"
finished-s3            = "rayyan-finished-s3-module04"
user-sns-topic         = "rayyan-topic-module04"
elb-name               = "rayyan-elb-module04"
tg-name                = "rayyan-tg-module04"
asg-name               = "rayyan-asg-module04"
desired                = 3
min                    = 2
max                    = 5
number-of-azs          = 3
region                 = "us-east-2"
raw-s3-bucket          = "rayyan-raw-s3-bucket-module04"
finished-s3-bucket     = "rayyan-finished-s3-bucket-module04"