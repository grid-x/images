ARG GO_VERSION=
FROM gridx/golang-tools:${GO_VERSION}

RUN apt-get update && apt-get -y install socat unzip && rm -rf /var/lib/apt/lists/* && \
    curl http://www.modbusdriver.com/downloads/diagslave.2.12.zip -o diagslave.zip && \
    mkdir -p bin && \
    unzip -p diagslave.zip linux/diagslave > bin/diagslave && \
    rm diagslave.zip && \
    chmod +x bin/diagslave
