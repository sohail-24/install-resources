## 🚀 Kubernetes kubeadm on AWS (Production Style)


📌 Architecture

Kubernetes: v1.29

Runtime: containerd

CNI: Calico

Cloud Provider: AWS (External CCM)

Load Balancer: AWS NLB (Service Type LoadBalancer)

Ingress: NGINX Ingress Controller

TLS: cert-manager (Let's Encrypt)

Domain: Route53 / External DNS ready

IAM: EC2 Instance Role

Subnet Tagging: Required for ELB discovery



Security Group must allow:

6443 (K8s API)

10250

NodePort range (30000–32767)

80

443


## 2️⃣ IAM Configuration

Create Policy:
KubernetesCloudControllerPolicy

```bash

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

## 3️⃣ Subnet Tagging (MANDATORY)


VPC → Subnets

Key: kubernetes.io/role/elb
Value: 1

Key: kubernetes.io/cluster/k8s-cluster
Value: owned

## 5️⃣ Initialize Control Plane

Run on Master:

```bash
kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --upload-certs \
  --cloud-provider=external
```

# Setup kubeconfig:

```bash
mkdir -p $HOME/.kube
```

```bash
cp /etc/kubernetes/admin.conf $HOME/.kube/config
```

```bash
chown $(id -u):$(id -g) $HOME/.kube/config
```

# 6️⃣ Install Calico


```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml
```

Verify:

kubectl get pods -n kube-system


# 7️⃣ Join Worker Nodes

# 8️⃣ Install AWS Cloud Controller Manager (CCM)

Add Helm repo:

```bash
helm repo add aws-cloud-controller-manager https://kubernetes.github.io/cloud-provider-aws
helm repo update
```

Install:

```bash
helm install aws-ccm aws-cloud-controller-manager/aws-cloud-controller-manager \
  -n kube-system \
  --set clusterName=k8s-cluster \
  --set region=ap-south-1 \
  --set serviceAccount.create=true \
  --set hostNetworking=true \
  --set extraArgs.configure-cloud-routes=false
```

Verify:

```bash
kubectl -n kube-system get pods | grep aws
```

# 9️⃣ Test AWS LoadBalancer

```bash
kubectl create deployment nginx --image=nginx
```

```bash
kubectl expose deployment nginx --type=LoadBalancer --port=80
```

check

```bash
kubectl get svc
```
# 🔟 Install NGINX Ingress Controller

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer
```

Verify:

kubectl get svc -n ingress-nginx

# 1️⃣1️⃣ Install cert-manager

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

```bash
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true
```

verifr:

kubectl get pods -n cert-manager


# 1️⃣2️⃣ Configure Let's Encrypt Issuer

```bash
vi cluster-issuer.yaml
```

```bash

apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: your-email@gmail.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
```

```bash
kubectl apply -f cluster-issuer.yaml
```

#1️⃣3️⃣ Configure Domain

Point your domain (Route53 or Cloudflare):

```bash
A Record → NGINX LoadBalancer External IP
```

# 1️⃣4️⃣ Example TLS Ingress

```bash
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - yourdomain.com
    secretName: nginx-tls
  rules:
  - host: yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
```

```bash
kubectl apply -f ingress.yaml
```

# ✅ Final Production Checklist

✔ IAM Role attached
✔ Subnets tagged
✔ CCM running
✔ Nodes Ready
✔ LoadBalancer created
✔ Ingress installed
✔ cert-manager running
✔ Domain pointing correctly
✔ TLS issued

🏆 What You Built

You built:

Production-style kubeadm cluster

External AWS Cloud Controller

Real AWS NLB integration

TLS automation

Ingress routing

Domain-based production setup

This is real DevOps level production knowledge.

If you want next:

Add ArgoCD

Add ExternalDNS

Add Prometheus + Grafana

Convert to HA Control Plane

Convert to GitOps structure






