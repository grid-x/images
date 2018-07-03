FROM buildkite/agent:3.0
MAINTAINER Joel Hermanns <j.hermanns@gridx.de>

RUN apk update && \
    apk add ca-certificates make openssl && \
    update-ca-certificates

ADD scripts/setup-k8s.sh /usr/local/bin/setup-k8s.sh

# Install kubectl
ENV KUBECTL_VERSION=1.9.0
RUN wget https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
chmod +x kubectl && \
mv kubectl /usr/local/bin/

# Install kontemplate
ENV KONTEMPLATE_VERSION=1.3.0
ENV KONTEMPLATE_URL=https://github.com/tazjin/kontemplate/releases/download/v${KONTEMPLATE_VERSION}/kontemplate-${KONTEMPLATE_VERSION}-98daa6b-linux-amd64.tar.gz
RUN wget ${KONTEMPLATE_URL} && \
tar xvzf *.tar.gz && \
mv kontemplate /usr/local/bin/ && \
rm *.tar.gz
