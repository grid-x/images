#!/bin/bash
set -eu -o pipefail

LIFECYCLED_VERSION=v2.0.0-rc2

echo "Installing lifecycled..."

sudo touch /etc/lifecycled
sudo curl -Lf -o /usr/bin/lifecycled \
	https://github.com/lox/lifecycled/releases/download/${LIFECYCLED_VERSION}/lifecycled-linux-amd64
sudo chmod +x /usr/bin/lifecycled
sudo curl -Lf -o /lib/systemd/system/lifecycled.service \
	   https://raw.githubusercontent.com/lox/lifecycled/${LIFECYCLED_VERSION}/init/systemd/lifecycled.unit

sudo systemctl enable lifecycled
