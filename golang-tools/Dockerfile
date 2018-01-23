FROM golang:1.8

ENV GOLINT_PATH=$GOPATH/src/github.com/golang/lint
RUN mkdir -p $GOLINT_PATH && cd $GOLINT_PATH && \
    git clone https://github.com/golang/lint . && \
    git reset --hard e14d9b0f1d332b1420c1ffa32562ad2dc84d645d && \
    go get -t -v ./... && \
    go install -v ./golint

ENV GLIDE_PATH=$GOPATH/src/github.com/Masterminds/glide
RUN mkdir -p $GLIDE_PATH && cd $GLIDE_PATH && \
    git clone https://github.com/Masterminds/glide . && \
    git reset --hard 67790b3dbede72cfdc54aa53be4706322c9499e0 && \
    go install -v
