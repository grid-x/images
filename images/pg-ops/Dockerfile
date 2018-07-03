FROM ubuntu:16.04

RUN apt-get update -y && apt-get install -y software-properties-common python-software-properties wget
RUN add-apt-repository 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
    apt-key add - && \
    apt-get update && \
    apt-get install -y postgresql-client-10 python-pip
RUN pip install awscli
RUN apt-get install --reinstall groff-base # needed to get awscli working
