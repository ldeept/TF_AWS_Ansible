output "splunk-master-node-public-ip" {
  value = aws_instance.splunk-master.public_ip
}

output "splunk-slave-public-ip" {
  value = {
    for instance in aws_instance.splunk-slave :
    instance.id => instance.public_ip
  }
}
