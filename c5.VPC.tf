resource "aws_vpc" "JVPC-Do-Not-Delete" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "JVPC-Do-Not-Delete"
  }
}

resource "aws_subnet" "JSubnet-Do-Not-Delete" {
  vpc_id                  = aws_vpc.JVPC-Do-Not-Delete.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "JIGW-Do-Not-Delete" {
  vpc_id = aws_vpc.JVPC-Do-Not-Delete.id
}

resource "aws_route_table" "JRouteTable" {
  vpc_id = aws_vpc.JVPC-Do-Not-Delete.id
}
resource "aws_route" "JROute" {
  route_table_id         = aws_route_table.JRouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.JIGW-Do-Not-Delete.id
}

resource "aws_route_table_association" "JRouteTableAssociation" {
  route_table_id = aws_route_table.JRouteTable.id
  subnet_id      = aws_subnet.JSubnet-Do-Not-Delete.id
}

resource "aws_security_group" "JSecurityGroup" {
  name        = "JSecurityGroup"
  description = "JSecurityGroup"
  vpc_id      = aws_vpc.JVPC-Do-Not-Delete.id
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH from VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    cidr_blocks = []
  }
  # ingress {
  #   description = "port 8080"
  #   from_port   = 8080
  #   to_port     = 8080
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  # ingress {
  #   description = "port K8s API Server"
  #   from_port   = 6443
  #   to_port     = 6443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  # ingress {
  #   description = "port Etcd server client API"
  #   from_port   = 2379
  #   to_port     = 2379
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  # ingress {
  #   description = "port Etcd server client API"
  #   from_port   = 2380
  #   to_port     = 2380
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  # ingress {
  #   description = "port Kubelet API "
  #   from_port   = 10250
  #   to_port     = 10250
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  # ingress {
  #   description = "port Kube-Scheduler"
  #   from_port   = 10251
  #   to_port     = 10251
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  # ingress {
  #   description = "port Kuber-Controller"
  #   from_port   = 10252
  #   to_port     = 10252
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

