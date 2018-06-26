#!/bin/bash
set -eu -o pipefail

DOCKER_VERSION=17.06.0-ce
DOCKER_COMPOSE_VERSION=1.14.0

# This performs a manual install of Docker. The init.d script is from the
# 1.11 yum package

echo "Installing docker..."

sudo apt-get update -y
sudo apt-get install -y \
     linux-image-extra-virtual \
     aufs-tools \
     apt-transport-https \
     ca-certificates \
     curl \
     software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository -y \
     "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update -y
sudo apt-get install -y docker-ce

# Add docker group
sudo usermod -a -G docker ubuntu


echo "Downloading docker-compose..."
sudo curl -Lsf -o /usr/bin/docker-compose https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64
sudo chmod +x /usr/bin/docker-compose
docker-compose --version

echo "Adding docker cron tasks..."
sudo cp /tmp/conf/docker/cron.hourly/docker-gc /etc/cron.daily/docker-gc
sudo cp /tmp/conf/docker/cron.hourly/docker-low-disk-gc /etc/cron.daily/docker-low-disk-gc
sudo chmod +x /etc/cron.daily/docker-*

echo "Downloading jq..."
sudo curl -Lsf -o /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
sudo chmod +x /usr/bin/jq
jq --version

#sudo bash -c "
#mkdir -p /etc/docker && echo '
#{
#  \"storage-driver\": \"overlay2\"
#}
#' > /etc/docker/daemon.json"
