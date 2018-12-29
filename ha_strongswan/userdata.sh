#!/bin/bash
# Instance setup
export AWS_DEFAULT_REGION="us-east-1"
instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

yum update -y
yum install -y vim iperf3 wget bzip2 gcc gcc-c++ make gmp-devel

# AWSCLI
curl "https://bootstrap.pypa.io/get-pip.py" -o /tmp/get-pip.py
python /tmp/get-pip.py
sudo pip install awscli

# Strongswan
wget http://download.strongswan.org/strongswan-5.7.1.tar.bz2
tar xjvf strongswan-5.7.1.tar.bz2
cd strongswan-5.7.1 && \
./configure --prefix=/usr --sysconfdir=/etc && \
make && make install
systemctl enable strongswan

# Network
cat > /etc/sysctl.conf << EOL
net.ipv4.ip_forward = 1
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.tcp_max_syn_backlog = 1280
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_mtu_probing = 1
EOL

sysctl -p /etc/sysctl.conf

# SSM
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm