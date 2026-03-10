

resource "aws_instance" "webserver" {
  ami = "ami-075924b436aa32cd4"
  instance_type = "t2.micro"
  tags = {
    Resource        = "EC2"
    Environment = "DEV"
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<h1>Welcome to the Web Server</h1>" > /var/www/html/index.html
              EOF
  key_name = aws_key_pair.web.id 
  vpc_security_group_ids = [aws_security_group.web_ssh_access.id]
}

resource "aws_key_pair" "web" {
  public_key = file("${path.module}/web.pub")
}

resource "aws_security_group" "web_ssh_access" {
  name        = "web_ssh_access"
  description = "Allow HTTP and SSH traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output public_ip {
  value = aws_instance.webserver.public_ip
}

