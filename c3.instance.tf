resource "aws_instance" "Jserver-Do-Not-Delete-master" {
  ami                    = var.aws_ami
  instance_type          = "t3.medium"
  key_name               = "T"
  vpc_security_group_ids = [aws_security_group.JSecurityGroup.id]
  subnet_id              = aws_subnet.JSubnet-Do-Not-Delete.id
  availability_zone      = var.aws_region
  user_data              = file("c8-master.sh")
  iam_instance_profile   = aws_iam_instance_profile.k8s_node_profile.name
  tags = {
    Name = "Master"
  }

}

resource "aws_instance" "Jserver-2-Do-Not-Delete-Worker1" {
  ami                    = var.aws_ami
  instance_type          = "t3.medium"
  key_name               = "T"
  vpc_security_group_ids = [aws_security_group.JSecurityGroup.id]
  subnet_id              = aws_subnet.JSubnet-Do-Not-Delete.id
  availability_zone      = var.aws_region
  user_data              = file("c9-k8sworker.sh")
  iam_instance_profile   = aws_iam_instance_profile.k8s_node_profile.name 
  tags = {
    Name = "Worker-1"
  }
}

# Create IAM role for EC2
resource "aws_iam_role" "k8s_node_role" {
  name = "k8s-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Create policy to allow S3 access to your join command file
resource "aws_iam_policy" "k8s_s3_policy" {
  name = "k8s-s3-access-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::ssoin5/join-command.txt"
      }
    ]
  })
}

#  Attach policy to role
resource "aws_iam_role_policy_attachment" "k8s_s3_attach" {
  role       = aws_iam_role.k8s_node_role.name
  policy_arn = aws_iam_policy.k8s_s3_policy.arn
}

# Create instance profile
resource "aws_iam_instance_profile" "k8s_node_profile" {
  name = "k8s-node-instance-profile"
  role = aws_iam_role.k8s_node_role.name
}
