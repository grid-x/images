#!/bin/bash
set -eu -o pipefail

echo "Updating package resources"
sudo apt-get update -y
sudo apt-mark hold grub-legacy-ec2
sudo apt-get upgrade -y

echo "Instaling python-pip"
sudo apt-get install -y python-pip python3-pip

echo "Instaling aws"
sudo pip install --upgrade pip awscli
sudo ln -s /usr/local/bin/aws /usr/bin/aws

echo "Installing zip utils and curl"
sudo apt-get install -y zip unzip curl

echo "Installing dumb-init"
sudo pip install --upgrade dumb-init

echo "Installing bats..."
sudo apt-get install -y git
sudo git clone https://github.com/sstephenson/bats.git /tmp/bats
sudo /tmp/bats/install.sh /usr/local

echo "Installing bk elastic stack bin files..."
sudo chmod +x /tmp/conf/bin/bk-*
sudo mv /tmp/conf/bin/bk-* /usr/local/bin

echo "Configuring awscli to use v4 signatures..."
sudo aws configure set s3.signature_version s3v4

echo "Installing ec2-metadata script..."
sudo mkdir -p /opt/aws/bin
sudo wget http://s3.amazonaws.com/ec2metadata/ec2-metadata -O /opt/aws/bin/ec2-metadata
sudo chmod +x /opt/aws/bin/ec2-metadata

echo "Installing cfn-bootstrap scripts..."
sudo wget https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz
tar xvzf aws-cfn-bootstrap-latest.tar.gz
(cd aws-cfn-bootstrap-*; sudo python3 setup.py install)
