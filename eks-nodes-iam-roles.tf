# Create iam roles for eks nodes
resource "aws_iam_role" "eks-rails-node-role" {
  name = "eks-rails-node-role"

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

# Attach AmazonEKSWorkerNodePolicy
resource "aws_iam_role_policy_attachment" "eks-rails-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.eks-rails-node-role.name}"
}

# Attach AmazonEKS_CNI_Policy
resource "aws_iam_role_policy_attachment" "eks-rails-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.eks-rails-node-role.name}"
}
# Attach AmazonEC2ContainerRegistryReadOnly
resource "aws_iam_role_policy_attachment" "eks-rails-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.eks-rails-node-role.name}"
}

# Attach instance profile to the role
resource "aws_iam_instance_profile" "eks-rails-node-instance-profile" {
  name = "eks-rails-node"
  role = "${aws_iam_role.eks-rails-node-role.name}"
}

# Setting up security groups for EKS nodes
resource "aws_security_group" "eks-rails-node-sg" {
  name        = "eks-rails-node-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${aws_vpc.eks-rail-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "eks-rail-node",
     "kubernetes.io/cluster/${var.cluster-name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "eks-rails-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.eks-rails-node-sg.id}"
  source_security_group_id = "${aws_security_group.eks-rails-node-sg.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-rails-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks-rails-node-sg.id}"
  source_security_group_id = "${aws_security_group.eks-rails-cluster.id}"
  to_port                  = 65535
  type                     = "ingress"
}

# Open ports for pods to communicate with api server (from pods to api)
resource "aws_security_group_rule" "eks-rails-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks-rails-cluster.id}"
  source_security_group_id = "${aws_security_group.eks-rails-node-sg.id}"
  to_port                  = 443
  type                     = "ingress"
}