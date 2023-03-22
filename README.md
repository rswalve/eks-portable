This project is for deploying a portable EKS cluster with Terraform. It can be used to deploy into any environment by adding a vars.tf file on your local machine with environment specific parameters.

## EKS CLuster
This Terraform script creates:
   - Two subnets
   - The EKS cluster
   - The Node group
   - IAM roles for [ cluster | nodes ]
   - IAM role policy attachments


## Getting started

Run this from a RHEL machine. You will need the following:

    Software
        Git
        Terraform
        AWS CLI
    AWS Credentials
        AWS profile configured 
        Key Pair 


## Building the cluster

Clone the git repository

Navigate to
eks/eks-portable/

Change parameters as necessary for your environment:
### env.tfvars
  aws_region
  vpc_id

Run the Terraform Commands:
```
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```
Cluster will de deployed

--------------------------------------------------------------------------
# Still in progress

## Validating the cluster

- [ ] [Persistent volume test]
- [ ] [Deploy an app]

## Auto-generating the Kubectl Config file
