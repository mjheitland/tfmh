#!/bin/bash
yum install httpd -y
EC2_AZ=\`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone\`
echo "availability zone: $EC2_AZ" >> /var/www/html/index.html
service httpd start
chkconfig httpd on
