packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

// builder
source "amazon-ebs" "example" {
  ami_name      = "harrod-packer-example-${local.timestamp}"
  instance_type = "t2.micro"
  region        = "us-east-1"
  source_ami    = "ami-0bb84b8ffd87024d8"
  ssh_username  = "ec2-user"
}

// specifies builders to use and any provisioning steps to be performed
build {
  sources = [
    "source.amazon-ebs.example"
  ]
  
  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd",
      "sudo mkdir -p /var/www/html"
    ]
  }
}