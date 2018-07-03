#!/bin/bash
set -euo pipefail

echo "Installing aufs..."
sudo apt-get install -y linux-image-extra-virtual

sudo mkdir -p /etc/docker
sudo cp /tmp/conf/docker/daemon.aufs.json /etc/docker/daemon.json
sudo cp /tmp/conf/docker/daemon.userns-remap.aufs.json /etc/docker/daemon.userns-remap.json
