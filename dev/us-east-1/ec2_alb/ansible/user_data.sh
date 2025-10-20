#!/usr/bin/env bash

apt update -y
apt upgrade -y
apt install -y \
  python3 python3-pip git unzip curl jq software-properties-common

add-apt-repository --yes --update ppa:ansible/ansible
apt install ansible -y

apt install -y rsync

apt install -y docker.io unzip curl

systemctl enable docker
systemctl start docker

curl -sSLo /tmp/awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

python3 -m pip install --upgrade pip --break-system-packages
python3 -m pip install "ansible>=9.0.0" boto3 botocore --break-system-packages

