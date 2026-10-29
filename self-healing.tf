# ── Self-Healing (Fase 4) ──────────────────────────────────────────────────
# Usuário IAM dedicado ao workflow .github/workflows/self-healing.yml (repo FIAP-DevOps-kubernetes).
#
# O usuário é criado pelo console, FORA do Terraform, para que ele e a access key sobrevivam ao
# teardown (os secrets do GitHub não precisam mudar a cada recriação da infra). Na AWS ele só tem
# eks:DescribeCluster (policy inline criada junto com o usuário no console).
#
# Aqui o Terraform só liga esse usuário ao cluster: ele entra no grupo "togglemaster:self-healing",
# que o RBAC em manifests/platform/self-healing-rbac.yaml limita a reiniciar deployments do
# namespace togglemaster.
#
# Fica desligado enquanto self_healing_iam_user_name estiver vazio.

variable "self_healing_iam_user_name" {
  description = "Nome do usuário IAM usado pelo workflow de self-healing (ex: togglemaster-self-healing)"
  type        = string
  default     = ""
}

data "aws_iam_user" "self_healing" {
  count     = var.self_healing_iam_user_name != "" ? 1 : 0
  user_name = var.self_healing_iam_user_name
}

resource "aws_eks_access_entry" "self_healing" {
  count             = var.self_healing_iam_user_name != "" ? 1 : 0
  cluster_name      = module.eks.cluster_name
  principal_arn     = data.aws_iam_user.self_healing[0].arn
  kubernetes_groups = ["togglemaster:self-healing"]
  type              = "STANDARD"
}
