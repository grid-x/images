#!/bin/bash
set -euo pipefail

docker info | grep "Storage Driver:"
