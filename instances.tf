#Get linux AMI ID using SSM parameter endpoint in us-east-1
data "aws_ssm_parameter" "linuxAmi" {
  provider = aws.region-master
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

data "aws_ssm_parameter" "linuxAmi_slave" {
  provider = aws.region-slave
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# Create Key Pair for logging into EC2 in us-east-1
resource "aws_key_pair" "master-key" {
  provider   = aws.region-master
  key_name   = "splunk"
  public_key = file("~/.ssh/id_rsa.pub")
}

#Create Key Pair for logging into EC2 in us-west-2
resource "aws_key_pair" "slave-key" {
  provider   = aws.region-slave
  key_name   = "splunk"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Create and bootstrap EC2 in us-east-1
resource "aws_instance" "splunk-master" {
  provider                    = aws.region-master
  ami                         = data.aws_ssm_parameter.linuxAmi.value
  instance_type               = var.instance-type
  key_name                    = aws_key_pair.master-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.splunk-sg.id]
  subnet_id                   = aws_subnet.subnet_1_master.id

  tags = {
    Name = "splunk-master_tf"
  }
  depends_on = [aws_main_route_table_association.set-master-default-rt-assoc]

  provisioner "local-exec" {
    command = <<EOF
aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region-master} --instance-ids ${self.id} && ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ansible_templates/splunk-master-sample.yml
EOF
  }
}

# Create and bootstrap EC2 in us-east-2
resource "aws_instance" "splunk-slave" {
  provider                    = aws.region-slave
  count                       = var.slave-count
  ami                         = data.aws_ssm_parameter.linuxAmi_slave.value
  instance_type               = var.instance-type
  key_name                    = aws_key_pair.slave-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.splunk-sg-slave.id]
  subnet_id                   = aws_subnet.subnet_1_slave.id

  tags = {
    Name = join("_", ["splunk-slave_tf", count.index + 1])
  }
  depends_on = [aws_main_route_table_association.set-slave-default-rt-assoc, aws_instance.splunk-master]

  provisioner "local-exec" {
    command = <<EOF
aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region-slave} --instance-ids ${self.id} && ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ansible_templates/splunk-slave-sample.yml
EOF
  }
}
