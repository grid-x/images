#!/usr/bin/env bash
set -eou pipefail

export GOLINT_PATH=$GOPATH/src/github.com/golang/lint
mkdir -p $GOLINT_PATH && cd $GOLINT_PATH && \
    git clone https://github.com/golang/lint . && \
    git reset --hard $GOLINT_COMMITREF && \
    go get -t -v ./... && \
    go install -v ./golint

export GLIDE_PATH=$GOPATH/src/github.com/Masterminds/glide
mkdir -p $GLIDE_PATH && cd $GLIDE_PATH && \
    git clone https://github.com/Masterminds/glide . && \
    git reset --hard $GLIDE_COMMITREF && \
    go install -v

