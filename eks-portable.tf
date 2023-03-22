terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.28.0"
    }
  }
  backend "s3" {
    bucket = "terraformstateplayground"
    key    = "eks/eks-template"
    region = "us-gov-west-1"
  }
}


provider "aws" {
  region = "us-gov-west-1"
}

data "aws_subnets" "pub-subnet" {
  filter {
    name   = "tag:Name"
    values = ["*Generic Default*"]
  }

}

/*
data "aws_subnet" "pub_subnet" {
  count = length(data.aws_subnets.pub-subnet.ids)
  id    = tolist(data.aws_subnets.pub-subnet.ids)[count.index]
}
*/



resource "aws_iam_role" "eks_cluster_role" {
  name = "experimental-MITRE-eks-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "eks_workers_node_ebs_policy" {
  name        = "Amazon_EBS_CSI_Driver"
  description = "Policy for EC2 Instances to access Elastic Block Store"
  policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AttachVolume",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteSnapshot",
        "ec2:DeleteTags",
        "ec2:DeleteVolume",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DetachVolume"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}
# And attach the new policy


resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws-us-gov:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws-us-gov:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_eks_cluster" "aws_eks" {
  name     = "MITRETestground"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.22"

  vpc_config {
    subnet_ids = data.aws_subnets.pub-subnet.ids
  }


  tags = {
    Name = "Cluster-MITRE-EKS"
  }
}

resource "aws_iam_role" "eks_nodes" {
  name = "MITRE-eks-node-group"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}
resource "aws_iam_role_policy_attachment" "work-node-AmazonEBSCSIDriver" {
  policy_arn = aws_iam_policy.eks_workers_node_ebs_policy.arn
  role       = aws_iam_role.eks_nodes.name
}
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws-us-gov:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws-us-gov:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws-us-gov:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_eks_node_group" "node" {
  cluster_name    = aws_eks_cluster.aws_eks.name
  node_group_name = "eks-node"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = data.aws_subnets.pub-subnet.ids

  #subnet_ids      = ["subnet-"l]
  instance_types = ["t2.large"]
  disk_size      = "100"
  remote_access {
    ec2_ssh_key = "MITRE-k8cluster-eks"
  }
  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }


  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}
