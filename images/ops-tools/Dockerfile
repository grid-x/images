FROM ubuntu:16.04

RUN apt-get update -y && apt-get upgrade -y && \
    apt-get install ca-certificates wget python3-pip unzip -y && \
    pip3 install --upgrade pip

# Install awscli
RUN pip3 install awscli

# Install terraform
ENV TERRAFORM_VERSION=0.11.8
RUN  wget https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
     unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
     mv terraform /usr/local/bin/ && \
     rm *.zip

# Install packer
ENV PACKER_VERSION=1.2.4
RUN wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip && \
    unzip packer_${PACKER_VERSION}_linux_amd64.zip && \
    mv packer /usr/local/bin/ && \
    rm *.zip

ADD scripts/setup-k8s.sh /usr/local/bin/setup-k8s.sh

# Install kubectl
ENV KUBECTL_VERSION=1.10.0
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

# Install kubeval
ENV KUBEVAL_VERSION=0.7.3
ENV KUBEVAL_URL=https://github.com/garethr/kubeval/releases/download/${KUBEVAL_VERSION}/kubeval-linux-amd64.tar.gz
RUN wget ${KUBEVAL_URL} && \
    tar xvzf *.tar.gz && \
    mv kubeval /usr/local/bin/ && \
    rm *.tar.gz

ENV KOPS_VERSION=1.10.0
RUN wget https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-amd64 && \
    mv kops-linux-amd64 /usr/local/bin/kops
