# Getting started

## Estimated AWS costs

This repo will help you deploy a UniFi Controller in AWS. It will run on an [AWS T4g.micro](https://aws.amazon.com/ec2/instance-types/t4/) instance.

NOTE: T4g.micro instances are currently free through March, 2021. Do not purchase a savings plan until AWS makes you pay for the instances! You are still responsible for storage costs.

Expected monthly costs:
* T4g EC2 Instance Savings Plan
  * $0.004/hour commitment
  * 3 year reservation w/no upfront payment
    * 30d month: **$2.88/month** ($6.05 w/o savings plan)
    * 31d month: **$2.98/month** ($6.25 w/o savings plan)
* 20GB GP2 root storage volume
  * **$2.00/month**
* Total by region (max)
  * US East 2 (Ohio): **$4.98/month**

The Terraform code will not purchase a savings plan for you. You need to do that yourself.

## Configuration

### AWS

Create a user in AWS IAM to manage your UniFi deployment.

TODO: develop constrained policy. For now I'm attaching AmazonEC2FullAccess to the new account.

```bash
cat << EOF >> ~/.aws/credentials
[unifi]
aws_access_key_id = ...
aws_secret_access_key = ...
EOF
```

### Terraform

Edit terraform.tfvars and set the following variables:
* hostname: some DNS name that you control
  * otherwise it will default to the AWS EC2 hostname
  * you could map it to something nice with /etc/hosts
* management_cidr_blocks: trusted CIDRs (jumphost, ...)
  * allows SSH, management WebUI/API, ICMP
* region: AWS region to deploy in
* site_cidr_blocks: site CIDRs (e.g. insert.your.public.IP/32 if you only have your home network)
  * allows all required ports (excluding speed test) according to UniFi documentation
  * also allows SSH

## Deploy

Execute deploy.sh. **DO NOT** run this script again after a successful deploy. If a new Ubuntu AMI is deployed, Terraform will want to delete your existing EC2 instance and redeploy.
