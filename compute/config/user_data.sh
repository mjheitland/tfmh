#!/bin/bash
yum install httpd -y
EC2_AZ=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
echo "availability zone from ec2 instance meta data: $EC2_AZ<br>" >> /var/www/html/index.html
echo "ec2 instance type from Terraform: $TF_INSTANCE_TYPE<br>" >> /var/www/html/index.html
service httpd start
chkconfig httpd on
