#!/bin/bash
set -e

# Update and install prerequisites
apt-get update -y
apt-get install -y docker.io unzip curl

# Ensure Docker starts on boot
systemctl enable docker
systemctl start docker

# Install AWS CLI v2 if missing
if ! command -v aws >/dev/null 2>&1; then
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip -q /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install --update
fi

# ----------------------------
# App Docker Image Bootstrap
# ----------------------------
ACCOUNT_ID="886687538523"    
REPO="my-dev-ecr-repo-1"          
CONTAINER_NAME="myapp"
HOST_PORT=80
CONTAINER_PORT=80
TAG="dev"      

# It calls the EC2 Metadata Service to get the instance’s Availability Zone (like us-east-1a) and saves it in AZ.
AZ="$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone || true)"
REGION="${AZ::-1}" # drop last letter from AZ 
if [ -z "$REGION" ]; then # -z checks for empty strings 
  REGION="us-east-1"
fi
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# ECR login + pull
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

docker pull "$REGISTRY/$REPO:$TAG"

# Run/replace container 
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart=always \
  -p ${HOST_PORT}:${CONTAINER_PORT} \
  "$REGISTRY/$REPO:$TAG"