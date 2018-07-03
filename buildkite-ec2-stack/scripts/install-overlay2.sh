#!/bin/bash
set -euo pipefail

sudo mkdir -p /etc/docker
sudo cp /tmp/conf/docker/daemon.overlay2.json /etc/docker/daemon.json
sudo cp /tmp/conf/docker/daemon.userns-remap.overlay2.json /etc/docker/daemon.userns-remap.json
