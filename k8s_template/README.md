# FHDportal Deployment Guide

FHDportal is the Federated Human Data Portal developed by SIB Swiss Institute of Bioinformatics for federated human genomic and metadata management. These are partial extracts from our production deployment at SIB—provided for inspiration only.

## ⚠️ Important Disclaimer

These files represent **partial configuration extracts** from our SIB FHDportal deployment.  
They **will not work as-is** and require significant adaptation for your environment, including:  
- Custom values for your cluster, domains, and secrets  
- Complete manifests (these are excerpts only)  
- Testing in a non-production environment first  

**Use at your own risk.** Review all configurations thoroughly before applying.

## Prerequisites

Before deploying, ensure your Kubernetes cluster meets these requirements:

- **Kubernetes**: v1.30+ (CloudNativePG supports up to 1.33) [cloudnative-pg](https://cloudnative-pg.io/docs/1.26/release_notes/v1.26/)
- **PostgreSQL Operator (CloudNativePG)**: Install the latest stable release (v1.28 as of March 2026) [cloudnative-pg.github](https://cloudnative-pg.github.io/docs/devel/release_notes/)
  ```bash
  kubectl apply --server-side -f \
  https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.28/releases/cnpg-1.28.1.yaml
  ```
- **Ingress Controller**: Installed and configured (e.g., NGINX Ingress via Helm) [hoop](https://hoop.dev/blog/kubernetes-ingress-deployment-a-complete-guide-to-setup-best-practices-and-scaling/)
  Example:  
  ```bash
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace
  ```
- **Volume Manager (CSI Driver)**: Dynamic provisioning enabled with a default StorageClass (e.g., for PersistentVolumes) [docs.cloud.google](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/install-csi-driver)
  Verify: `kubectl get storageclass` (should have at least one with `provisioner` set)

***

**Last updated**: March 2026 | **License**: MIT (configs for inspiration only)