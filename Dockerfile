FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y && apt-get upgrade -y
RUN dpkg-reconfigure tzdata
WORKDIR /app
RUN apt-get install -y ruby git
RUN git clone https://github.com/PharaohKJ/github_backupper.git
RUN gem install bundle
WORKDIR github_backupper
RUN bundle install
