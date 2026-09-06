#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
CLUSTER_NAME="${EKS_CLUSTER_NAME:-togglemaster-cluster}"
NAMESPACE="togglemaster"

if [[ ! -f backend.hcl ]]; then
  echo "ERRO: backend.hcl nao encontrado. Configure o backend S3 antes do teardown."
  echo "Exemplo: cp backend.hcl.example backend.hcl"
  exit 1
fi

echo "==> Inicializando o backend remoto..."
terraform init -input=false -backend-config=backend.hcl >/dev/null

echo "==> Atualizando kubeconfig..."
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME" >/dev/null 2>&1 || true

echo "==> Removendo Ingress e Services de Load Balancer..."
kubectl delete ingress --all -n "$NAMESPACE" --ignore-not-found --wait=true 2>/dev/null || true
kubectl delete service ingress-nginx-controller -n ingress-nginx --ignore-not-found --wait=true 2>/dev/null || true
kubectl delete service argocd-server -n argocd --ignore-not-found --wait=true 2>/dev/null || true

if command -v helm >/dev/null 2>&1; then
  echo "==> Removendo releases Helm..."
  helm uninstall ingress-nginx -n ingress-nginx --ignore-not-found 2>/dev/null || true
  helm uninstall metrics-server -n kube-system --ignore-not-found 2>/dev/null || true
  helm uninstall argocd -n argocd --ignore-not-found 2>/dev/null || true
fi

echo "==> Aguardando os Load Balancers serem liberados..."
for attempt in {1..12}; do
  if ! kubectl get service ingress-nginx-controller -n ingress-nginx >/dev/null 2>&1 \
     && ! kubectl get service argocd-server -n argocd >/dev/null 2>&1; then
    break
  fi
  sleep 5
done

# O provider Kubernetes/Helm nao deve tentar acessar o cluster durante a destruicao do EKS.
echo "==> Removendo recursos Kubernetes e Helm do state..."
terraform state list 2>/dev/null \
  | awk '/^(kubernetes_|helm_)/ { print }' \
  | while IFS= read -r resource; do
      terraform state rm "$resource" >/dev/null
    done

echo "==> Destruindo recursos AWS restantes..."
terraform destroy -auto-approve

echo "==> Teardown concluido."
