On AWS MASTER (source of truth)

```bash
cat ~/.kube/config
```
Now copy THE ENTIRE OUTPUT (from apiVersion: till end).

# BACKUP Mac kubeconfig (always do this)

On Mac:

```bash
cp ~/.kube/config ~/.kube/config.backup
```

```bash
rm -f ~/.kube/config
```

 REMOVE old EKS context
Now verify:

```bash
kubectl config get-contexts
```
👉 It should show NO contexts or empty

```bash
vi ~/.kube/config
```
# Paste keys you copy from aws master

```bash
apiVersion: v1
kind: Config

clusters:
- name: kubernetes
  cluster:
    server: https://13.232.165.68:6443
    insecure-skip-tls-verify: true

contexts:
- name: kubernetes-admin@kubernetes
  context:
    cluster: kubernetes
    user: kubernetes-admin

current-context: kubernetes-admin@kubernetes

users:
- name: kubernetes-admin
  user:
    client-certificate-data: <PASTE_CLIENT_CERT_DATA>
    client-key-data: <PASTE_CLIENT_KEY_DATA>

preferences: {}
```

# Fix permissions (very important)

```bash
chmod 600 ~/.kube/config
```


# Create SSH tunnel (Mac → AWS master)

Run on Mac terminal:

```bash
ssh -i <your-key.pem> ssh -i sohail.pem ubuntu@13.232.165.68
```
Open new terminal tab on Mac:

```bash
kubectl get nodes
```


