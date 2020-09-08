# Create SG for LB only TCP/8000, TCP/443 and outbound access

resource "aws_security_group" "lb-sg" {
  provider    = aws.region-master
  name        = "lb-sg"
  description = "Allow 443 and traffic to Splunk SG"
  vpc_id      = aws_vpc.vpc_master.id
  ingress {
    description = "Allow 443 from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow 8000 from anywhere for redirection"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow traffic to go out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create SG to Splunk Master for allowing TCP/8000/8191/8089 from * and TCP/22 from your IP in us-east-1
resource "aws_security_group" "splunk-sg" {
  provider    = aws.region-master
  name        = "splunk-sg"
  description = "Allow TCP/8089 and TCP/22"
  vpc_id      = aws_vpc.vpc_master.id
  ingress {
    description = "Allow 22 from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description     = "Allow anyone on port 8000"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.lb-sg.id]
  }
  #  ingress {
  #    description = "Allow traffic on port 8089"
  #    from_port   = 8089
  #    to_port     = 8089
  #    protocol    = "tcp"
  #    cidr_blocks = ["10.0.0.0/24"]
  #  }
  ingress {
    description = "Allow traffic from us-west-2"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.1.0/24"]
  }
  egress {
    description = "Allow traffic to go out from sg in us-east-1"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create SG to Splunk Slave SG for allowing TCP/8089/8191/9997 and TCP/22 from your IP in us-west-2

resource "aws_security_group" "splunk-sg-slave" {
  provider    = aws.region-slave
  name        = "splunk-sg-slave"
  description = "Allow TCP/8089/8191/9997 and TCP/22"
  vpc_id      = aws_vpc.vpc_slave.id
  ingress {
    description = "Allow 22 from your public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description = "Allow traffic from us-east-1"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24"]
  }
  egress {
    description = "Allow traffic to go out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
