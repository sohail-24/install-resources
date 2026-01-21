# Installing All packages

---

## step to install

1. give access to .sh file
  ```bash
chmod 777 install-kind.sh
 ```
2. run .sh file
  ```bash
./install-kind.sh
```
3. give access to docker first
  ```bash
sudo usermod -aG docker $USER
```
4. add docker in group
  ```bash
sudo newgrp docker
```
5. create a cluster using configuration file
 ```bash
kind create cluster --config kind-config.yaml --name tws-kind-cluster
```
6. verifi the cluster
 ```bash
kubectl get nodes
kubectl cluster-info
```
7. deleting the cluster
 ```bash
kind delete cluster --name tws-kind-cluster
```

# Notes for kind cluster
---
Multiple Clusters: KIND supports multiple clusters. Use unique --name for each cluster. Custom Node Images: Specify Kubernetes versions by updating the image in the configuration file. Ephemeral Clusters: KIND clusters are temporary and will be lost if Docker is restarted.

---
# Install Jenkins

---

1. setup Jenkins
```bash
sudo apt update
```
```bash
sudo apt install openjdk-17-jre -y
```
```bash
java -version
```
```bash
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
```
```bash
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
```
```bash
sudo apt update
```
```bash
sudo apt install jenkins -y
```
```bash
sudo systemctl start jenkins
```
```bash
sudo systemctl enable jenkins
```
```bash
sudo systemctl status jenkins
```
```bash
sudo usermod -aG docker jenkins
```
```bash
sudo systemctl restart jenkins
```
---
#  Download AWS CLI v2

---
1. install
 ```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
```
2. install unzip 
```bash
sudo apt install unzip -y
```
3. unzip
```bash
unzip awscliv2.zip
```
4. install aws cli
```bash
sudo ./aws/install
```
5. chect install 
```bash
aws --version
```
6. configure aws credentials.
```bash
aws configure
```
7. Then run this to connect kubectl to EKS
```bash
aws eks --region ap-south-1 update-kubeconfig --name sms-cluster
```
8. test nodes
```bash
kubectl get nodes
```
---
# Installing Terraform on AWS Ubuntu (EC2)

---
1. update
```bash
sudo apt update -y
```
2. Install required dependencies
```bash
sudo apt install -y gnupg software-properties-common
```
3. Add HashiCorp GPG key
```bash
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
```
4. update again 
```bash
sudo apt update -y
```
5. Install Teraform
```bash
sudo apt install terraform -y
```
6. Verify installation
```bash
terraform -version
```
---
# Install Ansible

---

1. update and upgrade
```bash
sudo apt update -y
sudo apt upgrade -y
```
2. Install required dependencies
```bash
sudo apt install -y software-properties-common
```
3. Add Ansible official PPA
```bash
sudo add-apt-repository --yes --update ppa:ansible/ansible
```
4. Install Ansible
```bash
sudo apt install -y ansible
```
5. Verify installation
```bash
ansible --version
```
---

Thank you....
