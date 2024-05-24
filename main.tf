provider "aws" {
    region     = "us-east-1"
}

# resource "<provider>_<resource_type>" "name" 

# launch template for ec2 instances in ASG
# Note: hardcoding AMI image built in previous step, hardcode yours here
# Note: hardcode your pem key here (if using SSH, you can leave it out otherwise)
resource "aws_launch_template" "template" {
    name_prefix             = "tf-launch-template-harrod"
    image_id                = "ami-hardcode-your-ami-id"
    instance_type           = "t2.micro"
    vpc_security_group_ids  = [aws_security_group.launch_template_sg.id]
    key_name = "harrod-ec2"
    user_data = base64encode(file("user_data.sh"))
}

# sg attached to the launch template
# Note: hardcode VPC
resource "aws_security_group" "launch_template_sg" {
    name = "tf=launch-template-sg-harrod"
    description = "security group for ec2 instances spun up by launch template"
    vpc_id = "your-vpc-id"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        
        cidr_blocks = ["10.0.0.0/8"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/8"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.nlb_sg.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Note: hardcode subnet
resource "aws_autoscaling_group" "autoscale" {
    name = "tf-autoscaling-group-harrod"
    desired_capacity = 3
    max_size = 6
    min_size = 3
    health_check_type = "EC2"
    termination_policies  = ["OldestInstance"]
    vpc_zone_identifier   = ["your-subnet-id"]

    launch_template {
        id      = aws_launch_template.template.id
        version = "$Latest"
    }
}

# Note: hardcode subnet
resource "aws_lb" "nlb" {
    name = "tf-nlb-harrod"
    internal = true
    load_balancer_type = "network"
    subnets = ["your-subnet-id"]
    security_groups = [aws_security_group.nlb_sg.id]
}

# sg attached to nlb
# Note: hardcode vpc
resource "aws_security_group" "nlb_sg" {
    name = "tf-nlb-sg-harrod"
    description = "Allow inbound traffic to the NLB"
    vpc_id = "your-vpc-id"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/8"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "tf-nlb-security-group-harrod"
    }

}

resource "aws_lb_listener" "nlb-listener" {
    load_balancer_arn = aws_lb.nlb.arn
    port = "80"
    protocol = "TCP"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.tg.arn
    }
}

# Note: hardcode vpc
resource "aws_lb_target_group" "tg" {
    name = "tf-target-group-harrod"
    port = 80
    protocol = "TCP"
    vpc_id = "your-vpc-id"

    health_check {
        enabled = true
        path = "/"
    }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
    autoscaling_group_name = aws_autoscaling_group.autoscale.name
    lb_target_group_arn = aws_lb_target_group.tg.arn
}
