provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_instance" "imported_ec2" {
    ami                                  = "ami-075924b436aa32cd4"
    availability_zone                    = "ap-southeast-2a"
    instance_type                        = "t2.micro"
    key_name                             = "tf-import-sample"
    region                               = "ap-southeast-2"
    subnet_id                            = "subnet-0d2c59a4de7e64be8"
    vpc_security_group_ids               = [
        "sg-0f4194c32ff254d19",
    ]
}