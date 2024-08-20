provider "aws" {
  region = "us-east-2" # Change this to your preferred region
}

# Data source to get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Define a security group to allow inbound SSH traffic
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow inbound SSH traffic"
  vpc_id      = data.aws_vpc.default.id # Use the default VPC ID from the data source

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "terraform_key" {
  key_name   = "terraform2-key"  # Name the key pair
  public_key = file("terraform2.pub")  # Use the public key corresponding to terraform2.pem
}

resource "aws_instance" "ubuntu" {
  ami           = "ami-0119b1e7fe7303882"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.terraform_key.key_name  # Associate the instance with the key pair

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  associate_public_ip_address = true

  tags = {
    Name = "UbuntuInstance"
  }
}



output "instance_ip" {
  value = aws_instance.ubuntu.public_ip
}

# Define null_resource to run Ansible playbook
resource "null_resource" "ansible_provision" {
  provisioner "local-exec" {
    command = <<EOT
      sleep 30
      ansible-playbook -i ${aws_instance.ubuntu.public_ip}, -u ubuntu --private-key terraform2.pem playbook.yml
    EOT
  }

  depends_on = [aws_instance.ubuntu]
}


