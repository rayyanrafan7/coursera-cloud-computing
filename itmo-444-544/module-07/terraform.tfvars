imageid                = "ami-0eacb8127f9b58e90"
instance-type          = "t3.micro"
key-name               = "coursera-key"
vpc_security_group_ids = "sg-0a73fa41a9170ea15"
cnt                    = 3
install-env-file       = "install-env.sh"

elb-name               = "rr-elb7"
tg-name                = "rr-tg7"
asg-name               = "rr-asg7"
lt-name                = "rr-lt7"
module-tag             = "module7-tag"

raw-s3-bucket          = "rr-module7-raw-404931288564"
finished-s3-bucket     = "rr-module7-finished-404931288564"