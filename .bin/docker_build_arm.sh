#!/usr/bin/env bash
set -eou pipefail

docker run --rm --privileged multiarch/qemu-user-static:register --reset

chmod +x .bin/docker_build.sh
.bin/docker_build.sh
