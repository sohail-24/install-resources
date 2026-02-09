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
Paste everything you copy from aws master

# Fix permissions (very important)

```bash
chmod 600 ~/.kube/config
```


# Create SSH tunnel (Mac → AWS master)

Run on Mac terminal:

```bash
ssh -i <your-key.pem> -L 6443:10.0.1.216:6443 ubuntu@13.234.239.3
```
Open new terminal tab on Mac:

```bash
kubectl get nodes
```


