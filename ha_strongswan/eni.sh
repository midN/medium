#!/bin/bash
instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
if ! ifconfig | grep $2 > /dev/null
then
    aId=$(aws ec2 describe-network-interfaces --network-interface-ids $1 --query 'NetworkInterfaces[].Attachment.AttachmentId' --output text)
    if [ "$aId" != "" ]; then aws ec2 detach-network-interface --attachment-id $aId; fi
    aws ec2 wait network-interface-available --network-interface-ids $1
    aws ec2 attach-network-interface --instance-id ${instance_id} --device-index 1 --network-interface-id $1
    while [ ! -f "/sys/class/net/eth1/address" ];do echo ENI not available, waiting; sleep 2;done
    hwaddr=$(cat /sys/class/net/eth1/address)
    default_route=$(ip route | awk '/default/ { print $3 }')
    echo "GATEWAYDEV=eth0" >> /etc/sysconfig/network
cat > /etc/sysconfig/network-scripts/ifcfg-eth1 << EOL
DEVICE=eth1
NAME=eth1
HWADDR=${hwaddr}
BOOTPROTO=dhcp
ONBOOT=yes
TYPE=Ethernet
USERCTL=no
NM_CONTROLLED=no
EOL
cat > /etc/sysconfig/network-scripts/route-eth1 << EOL
default via ${default_route} dev eth1 table 1000
$2 dev eth1 table 1000
EOL
cat > /etc/sysconfig/network-scripts/rule-eth1 << EOL
from $2 lookup 1000
EOL
    service network restart
fi