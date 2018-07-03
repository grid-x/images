FROM golang:1.8

WORKDIR /

RUN apt-get update -y && apt-get install -y wget unzip make

ENV PROTO_VERSION=3.3.0
ENV PROTOC_URL=https://github.com/google/protobuf/releases/download/v${PROTO_VERSION}/protoc-${PROTO_VERSION}-linux-x86_64.zip
RUN wget -O protoc.zip ${PROTOC_URL} && \
    unzip protoc.zip && \
    mv bin/protoc /usr/local/bin/protoc

ENV PROTOC_GEN_PATH=$GOPATH/src/github.com/golang/protobuf
RUN mkdir -p $PROTOC_GEN_PATH && cd $PROTOC_GEN_PATH && \
    git clone https://github.com/golang/protobuf . && \
    git reset --hard ab9f9a6dab164b7d1246e0e688b0ab7b94d8553e && \
    make install


ENV PROTOC_LINT_PATH=$GOPATH/src/github.com/ckaznocha/protoc-gen-lint
RUN mkdir -p $PROTOC_LINT_PATH && cd $PROTOC_LINT_PATH && \
    git clone https://github.com/ckaznocha/protoc-gen-lint . && \
    git reset --hard 7e4e2489513a4db3e6469be652b8704bb7c5fc18 && \
    go install -v
