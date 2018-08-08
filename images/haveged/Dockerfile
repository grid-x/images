FROM multiarch/debian-debootstrap:armhf-stretch-slim

RUN apt-get update && apt-get install -y --no-install-recommends haveged && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/sbin/haveged", "-F", "-w", "1024"]
