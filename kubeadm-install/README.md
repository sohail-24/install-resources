# Kubernetes Cluster Setup using kubeadm (Master & Worker)

This repository provides a **step-by-step guide and scripts** to set up a **production-ready Kubernetes cluster** using **kubeadm**, including:

* Master & Worker node initialization
* CNI networking (Calico)
* Metrics Server
* HPA, PDB, Network Policies
* NGINX Ingress Controller
* Internal service communication and validation
* Load Balancer

---

## 📁 Repository Structure

```
install-kubeadm/
├── k8s-master.sh
├── k8s-worker.sh
└── README.md
```

---

## 🚀 Master Node Setup

```bash
cd kubeadm-install
```

```bash
chmod +x k8s-master.sh
```

```bash
sudo ./k8s-master.sh
```


---

## 🚀 Worker Node Setup

```bash
cd kubeadm-install
```

```bash
chmod +x k8s-worker.sh
```

```bash
sudo ./k8s-worker.sh
```


---

## 🔧 Initialize Kubernetes Control Plane (Master)

```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
```

### Configure kubectl Access

```bash
mkdir -p ~/.kube
```

```bash
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
```

```bash
sudo chown $(id -u):$(id -g) ~/.kube/config
```

Verify:

```bash
kubectl get nodes
```

---

## 🌐 Install CNI (Calico)

⚠️ **Install Calico ONLY after kubeadm init**

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml
```

---

## 🔗 Join Worker Node(s)

### On Master

```bash
kubeadm token create --print-join-command
```

### On Worker

Open port 6443 in AWS SG

```bash
sudo kubeadm join <MASTER-IP>:6443 --token <TOKEN> \
--discovery-token-ca-cert-hash sha256:<HASH>
```

Verify on Master:

```bash
kubectl get nodes
```


# Add label for workers

```bash
kubectl label node ip-10-0-1-198 node-role.kubernetes.io/worker=worker
```

---

## ✅ STEP 4 — Workload Validation

```bash
kubectl create deployment nginx --image=nginx
```

```bash
kubectl scale deployment nginx --replicas=2
```

```bash
kubectl get pods
```


---

## 📊 STEP 5 — Metrics Server

Open ALL traffic Security Group to Security Group only

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Patch Metrics Server:

```bash
kubectl patch deployment metrics-server -n kube-system \
  --type=json -p='[
    {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}
  ]'
```

Edit deployment:

```bash
kubectl edit deployment metrics-server -n kube-system
```

Add and Change:

```
args:
- --cert-dir=/tmp
- --secure-port=4443
- --kubelet-insecure-tls
- --kubelet-preferred-address-types=InternalIP

ports:
- containerPort: 4443
```

Edit service:

```bash
kubectl edit svc metrics-server -n kube-system
```

Change:

```
targetPort: 4443
```

Restart:

```bash
kubectl rollout restart deployment metrics-server -n kube-system
```

Verify:

```bash
kubectl get pods -n kube-system | grep metrics
```

Wait until it is completely ready

```bash
kubectl get apiservices | grep metrics
```

```bash
kubectl top nodes
kubectl top pods
```

---

## 📈 STEP 6 — Horizontal Pod Autoscaler (HPA)

```bash
kubectl set resources deployment nginx \
  --requests=cpu=100m --limits=cpu=200m
```

```bash
kubectl autoscale deployment nginx \
  --cpu-percent=50 --min=1 --max=5
```

```bash
kubectl get hpa
```

---

## 🛡️ STEP 7 — PodDisruptionBudget (PDB)

Create `nginx-pdb.yaml`:

```bash
vi nginx-pdb.yaml
```

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: nginx-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: nginx
```

Apply:

```bash
kubectl apply -f nginx-pdb.yaml
kubectl get pdb
```

---

## 🔗 STEP 8 — ClusterIP Service (Internal)

```bash
kubectl expose deployment nginx \
  --name=nginx-clusterip \
  --port=80 \
  --target-port=80 \
  --type=ClusterIP
```

Test:

```bash
kubectl run test --rm -it --image=busybox -- /bin/sh
```

Then inside run this commands:

```bash
wget -qO- http://nginx-clusterip.default.svc.cluster.local
```

```bash
exit
```


---

## 🔐 STEP 9 — Network Policies (Zero Trust)

### Default Deny Policy

Create `nginx-default-deny.yaml`:

```bash
vi nginx-default-deny.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: nginx-default-deny
spec:
  podSelector:
    matchLabels:
      app: nginx
  policyTypes:
  - Ingress
```

Apply:

```bash
kubectl apply -f nginx-default-deny.yaml
```

### Allow Traffic from Ingress Controller Only

Create `nginx-allow-ingress.yaml`:

```bash
vi nginx-allow-ingress.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: nginx-allow-from-ingress
spec:
  podSelector:
    matchLabels:
      app: nginx
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: ingress-nginx
    ports:
    - protocol: TCP
      port: 80
```

Apply:

```bash
kubectl apply -f nginx-allow-ingress.yaml
kubectl get networkpolicy
```

---

## 🌍 STEP 10 — NGINX Ingress Controller (Bare Metal)

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml
```

Verify:

```bash
kubectl get pods -n ingress-nginx
```

```bash
kubectl get svc -n ingress-nginx
```


---

## 🌐 Create Ingress Rules

Create `nginx-ingress.yaml`:

```bash
vi nginx-ingress.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-clusterip
            port:
              number: 80
```

Apply & Verify:

```bash
kubectl apply -f nginx-ingress.yaml
kubectl get ingress
kubectl describe ingress nginx-ingress
```

---

## 🌐 Access Application

To check ports and allow in aws security group

```bash
kubectl get svc -n ingress-nginx
```

Access via:

```
http://<NODE_PUBLIC_IP>:<INGRESS_NODEPORT>
```

# Install ArgoCD into the cluster

```bash
kubectl create namespace argocd
```

```bash
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

```bash
kubectl patch svc argocd-server -n argocd -p '{
  "spec": {
    "type": "NodePort"
  }
}'
```

# password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

## 🌐 Access Application

```bash
kubectl get svc -n argocd
```

# storageClass

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
```

# Verify

```bash
kubectl get storageclass
kubectl get pvc -n sms
kubectl get pods -n sms
```

---
Install nginx steps

```bash
sudo apt update
sudo apt install -y nginx
```


---

## ✅ Outcome

You now have a **fully functional Kubernetes cluster** with:

* Secure networking (Calico + NetworkPolicies)
* Autoscaling (HPA)
* High availability (PDB)
* Observability (Metrics Server)
* Ingress-based traffic routing

---

👨‍💻 **Author:** Mohammed Sohail
🔧 **Role:** DevOps Engineer
