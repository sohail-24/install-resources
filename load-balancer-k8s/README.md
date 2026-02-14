# 🚀 Kubernetes kubeadm on AWS (Production Style)

This guide builds a **real production-style Kubernetes cluster on AWS using kubeadm**  
with:

- Kubernetes v1.29
- containerd runtime
- Calico CNI
- AWS External Cloud Controller Manager (CCM)
- AWS NLB (Service Type LoadBalancer)
- NGINX Ingress Controller
- cert-manager (Let's Encrypt)
- Route53 ready
- Production IAM + Subnet tagging

---

# 🏗️ Architecture

EC2 (Master + Workers)
        |
        |
AWS Cloud Controller Manager
        |
        |
AWS NLB (LoadBalancer Service)
        |
        |
NGINX Ingress
        |
        |
Application Pods

---

# 1️⃣ EC2 Requirements

### Open these ports in EC2 Security Group

| Port | Purpose |
|------|---------|
| 22 | SSH |
| 6443 | Kubernetes API |
| 10250 | Kubelet |
| 30000-32767 | NodePort |
| 80 | HTTP |
| 443 | HTTPS |

---

# 2️⃣ IAM Role (MANDATORY)

Create Policy: `KubernetesCloudControllerPolicy`

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeRegions",
        "ec2:DescribeRouteTables",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcs",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateSecurityGroup",
        "ec2:CreateTags",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:DeleteSecurityGroup"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "iam:CreateServiceLinkedRole",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "iam:AWSServiceName": "elasticloadbalancing.amazonaws.com"
        }
      }
    }
  ]
}
```

Attach this policy to EC2 Instance Role.

---

# 3️⃣ Subnet Tagging (CRITICAL)

Go to VPC → Subnets

Add these tags to PUBLIC subnets:

```
Key: kubernetes.io/role/elb
Value: 1
```

```
Key: kubernetes.io/cluster/k8s-cluster
Value: owned
```

Cluster name MUST match Helm install.

---

# 4️⃣ Common Setup (All Nodes)

Run:

```
sudo bash common.sh
```

---

# 5️⃣ Initialize Control Plane

Run on master:

```
kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --upload-certs \
  --cloud-provider=external
```

Setup kubeconfig:

```bash
mkdir -p $HOME/.kube
```

```bash
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
```

```bash
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

---

# 6️⃣ Install Calico

```
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml
```

---

# 7️⃣ Join Worker Nodes

Use the kubeadm join command generated.

---

# 8️⃣ Install AWS Cloud Controller Manager

Install Helm:

```
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Add repo:

```
helm repo add aws-cloud-controller-manager https://kubernetes.github.io/cloud-provider-aws
helm repo update
```

Install CCM:

```
helm install aws-ccm aws-cloud-controller-manager/aws-cloud-controller-manager \
  -n kube-system \
  --set clusterName=k8s-cluster \
  --set region=ap-south-1 \
  --set serviceAccount.create=true \
  --set hostNetworking=true \
  --set extraArgs.configure-cloud-routes=false \
  --set extraArgs.allocate-node-cidrs=false

```

Verify:

```
kubectl -n kube-system get pods
```

CCM must be Running.

---

# 9️⃣ Test LoadBalancer

Create app:

```bash
kubectl create deployment nginx --image=nginx
```

```bash
kubectl expose deployment nginx --type=LoadBalancer --port=80
```

Check:

```
kubectl get svc
```

You should see:

```
EXTERNAL-IP: *.elb.amazonaws.com
```

Test:

```
curl localhost:<NodePort>
```

Then open ELB DNS in browser.

---

# 🔟 Install NGINX Ingress

```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

```
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer
```

---

# 1️⃣1️⃣ Install cert-manager

```
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

```
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true
```

---

# 1️⃣2️⃣ Production Checklist

✔ IAM role attached  
✔ Subnets tagged  
✔ kubeadm init with external cloud provider  
✔ CCM running  
✔ Nodes Ready  
✔ LoadBalancer created  
✔ Ingress installed  
✔ TLS ready  

---

# 🏆 What You Built

You built:

- Real kubeadm cluster
- External AWS CCM integration
- AWS NLB provisioning
- Production networking model
- Ingress + TLS ready foundation

This is real DevOps production-level architecture.
