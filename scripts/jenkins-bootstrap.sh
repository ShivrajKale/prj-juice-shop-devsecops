#!/bin/bash
set -euo pipefail

echo "=== Installing Java 17 ==="
sudo apt update
sudo apt install -y fontconfig openjdk-17-jre

echo "=== Installing Jenkins LTS ==="
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install -y jenkins

echo "=== Installing Docker ==="
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu

echo "=== Installing kubectl ==="
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

echo "=== Installing Helm ==="
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "=== Installing AWS CLI v2 ==="
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install -y unzip
unzip -o awscliv2.zip && sudo ./aws/install --update

echo "=== Installing Trivy ==="
sudo apt install -y wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt update
sudo apt install -y trivy

echo "=== Installing Git ==="
sudo apt install -y git

echo "=== Configuring kubeconfig for Jenkins user ==="
sudo -u jenkins aws eks update-kubeconfig --region us-east-1 --name juice-shop-cluster

echo "=== Restarting Jenkins ==="
sudo systemctl restart jenkins
sudo systemctl enable jenkins

echo "=== Setup complete ==="
echo "Jenkins initial password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

