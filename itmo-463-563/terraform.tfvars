# Add values
# Find the Ubuntu server 22.04 AMI for your region at this URL
# https://cloud-images.ubuntu.com/locator/ec2/
imageid                = "ami-06b83968631539180"
# Use t2.micro for the AWS Free Tier
instance-type          = "t3.micro"
key-name               = "coursera-key"
vpc_security_group_ids = 
tag-name               = 
raw-bucket             = 
finished-bucket        = 
sns-topic              = 
sqs                    = 
dbname                 = 
uname                  = 
pass                   = 
elb-name               = "jrh-elb"
asg-name               = "jrh-asg"
min                    = 2
max                    = 5
desired                = 3
tg-name                = 
