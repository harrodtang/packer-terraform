# Packer and Terraform
Basic example utilizing Hashicorp Packer and Terraform.

- Builds a custom AMI using Packer
- Uses Terraform to spin up an ASG where each EC2 instance uses the custom AMI that we build in the previous step. Throws an NLB in front of the ASG to make the EC2 instances accessible. The necessary security groups and listeners are also created.

## Build AMI
```bash
packer init .
packer build .
```

## Deploy IaC with Terraform
```bash
terraform init
terraform plan
terraform apply
```

## Destroy Terraform Resources
```bash
terraform destroy
```

## Notes
This code was developed on a private VPC. That's why you'll notice that the security groups are accepting traffic from 10.0.0.0/8. Update the CIDR blocks accordingly for your use case.

Some values need to be hardcode (ami id, subnet id, vpc id). I've added comments starting in `Note:` for the TF resources that need these changes.
