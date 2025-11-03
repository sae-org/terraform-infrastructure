#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

APT_OPTS="-y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"

# Update & upgrade
apt-get update -y
apt-get upgrade $APT_OPTS

# Install core utilities
apt-get install $APT_OPTS \
  python3 python3-pip python3-boto3 python3-botocore \
  git unzip curl jq rsync ca-certificates \
  software-properties-common docker.io

# Install Ansible from official PPA
add-apt-repository --yes --update ppa:ansible/ansible
apt-get install $APT_OPTS ansible

# Enable Docker for ubuntu + ssm-user
systemctl enable docker
systemctl start docker
for u in ubuntu ssm-user; do
  id -u "$u" >/dev/null 2>&1 && usermod -aG docker "$u" || true
done

# Install AWS CLI v2
if ! command -v /usr/local/bin/aws >/dev/null 2>&1; then
  curl -sSLo /tmp/awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
  unzip -q /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install
  rm -rf /tmp/aws /tmp/awscliv2.zip
fi

# Shared Ansible paths so all users see same collections/roles
mkdir -p /opt/ansible/{collections,roles}
chown -R ubuntu:ubuntu /opt/ansible
chmod -R g+rws /opt/ansible

# Sanity info (goes to cloud-init-output.log)
echo "== Installed Versions ==" 
ansible --version | head -n1 || true
/usr/local/bin/aws --version || true
docker --version || true
python3 -m pip --version || true
