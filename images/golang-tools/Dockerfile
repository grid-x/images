ARG GO_VERSION=
FROM golang:${GO_VERSION}
ARG GOLINT_COMMITREF=
ARG GLIDE_COMMITREF=

COPY setup_tools.sh ./setup_tools.sh
RUN chmod +x setup_tools.sh && ./setup_tools.sh && rm ./setup_tools.sh