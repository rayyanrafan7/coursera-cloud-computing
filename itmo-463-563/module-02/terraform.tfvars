# Add values
# Find the Ubuntu server 22.04 AMI for your region at this URL
# https://cloud-images.ubuntu.com/locator/ec2/
imageid                = "ami-076bd9cabcf9c4e85"
# Use t2.micro for the AWS Free Tier
instance-type          = "t2.micro"
key-name               = "coursera-key"
vpc_security_group_ids = "sg-0edb42a6ab6921d03"
cnt                    = 1
tag-name               = "module-02"
raw-bucket             = "rayyan-raw-bucket-463-20260501"
finished-bucket        = "rayyan-finished-bucket-463-20260501"
sns-topic              = "rayyan-topic"
sqs                    = "rayyan-sqs"
dbname                 = "rayyanmodule02"
uname                  = "controller"
pass                   = "wizard168"
elb-name               = "rayyan-elb"
asg-name               = "rayyan-asg"
min                    = 2
max                    = 5
desired                = 3
tg-name                = "rayyan-tg"
