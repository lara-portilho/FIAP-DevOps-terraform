# FIAP DevOps - Terraform

Infraestrutura como codigo para o Tech Challenge Fase 3. O projeto provisiona a base AWS e os recursos de execucao do ToggleMaster.

## Recursos

- VPC com subnets publicas e privadas, NAT Gateway e endpoints S3/DynamoDB
- Cluster Amazon EKS e node group em subnets privadas
- Repositorios ECR para os cinco microsservicos
- Tres bancos PostgreSQL no Amazon RDS
- Redis no Amazon ElastiCache
- Fila Amazon SQS e tabela DynamoDB para analytics
- Metrics Server e Nginx Ingress via Helm
- Namespace, Secrets, ConfigMaps, Deployments, Services, Ingress e HPAs no Kubernetes

## Pre-requisitos

- Terraform >= 1.5
- AWS CLI configurada com permissao para os recursos acima
- `kubectl` e acesso ao cluster EKS
- Imagens dos microsservicos publicadas no ECR antes dos Deployments entrarem em operacao
- Um bucket S3 para armazenar o estado remoto do Terraform

## Uso

1. Copie o arquivo de variaveis:

```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Substitua todos os valores `CHANGE_ME` por valores locais. Nunca versione `terraform.tfvars`.

3. Crie previamente o bucket S3 de state, habilite versionamento e aplique uma politica que permita acesso somente ao time. O bucket precisa existir antes do `terraform init`.

Copie o exemplo, substitua `SEU_BUCKET_DE_STATE` pelo bucket criado e inicialize usando configuracao parcial:

```bash
cp backend.hcl.example backend.hcl
terraform init -backend-config=backend.hcl
```

O backend usa S3 com criptografia. Em versoes do Terraform que suportam locking nativo, adicione `use_lockfile = true` ao `backend.hcl`; alternativamente, configure locking por DynamoDB. Nao versione `backend.hcl` se ele contiver dados especificos do ambiente.

4. Inicialize e valide:

```bash
terraform init
terraform fmt -check
terraform validate
```

5. Revise e aplique:

```bash
terraform plan
terraform apply
```

6. Configure o acesso ao cluster:

```bash
aws eks update-kubeconfig --region us-east-1 --name togglemaster-cluster
kubectl get pods -n togglemaster
```

Para remover a infraestrutura, revise o impacto e execute `terraform destroy`.

Como os providers Kubernetes e Helm dependem do cluster EKS e o Ingress cria um Load Balancer, a remocao direta pode falhar. Use o script abaixo para limpar esses recursos enquanto o cluster ainda esta acessivel:

```bash
./teardown.sh
```

O script exige `backend.hcl`, usa `AWS_REGION` e `EKS_CLUSTER_NAME` quando informados, e nao remove Load Balancers de outros projetos.

## AWS Academy

Em ambiente AWS Academy, a LabRole existente deve ser usada e o projeto nao pode criar IAM Roles ou Policies. Nesse caso, adapte `eks.tf` para referenciar a LabRole por data source ou variavel antes de aplicar. A configuracao atual cria roles proprias e e adequada para conta AWS pessoal, conforme a Op\u00e7ao B do enunciado.

## Estrutura

Cada arquivo `.tf` concentra uma parte da infraestrutura: rede (`vpc.tf`), EKS (`eks.tf`), ECR (`ecr.tf`), bancos (`rds.tf`), cache (`elasticache.tf`), mensageria (`sqs.tf`), DynamoDB (`dynamodb.tf`), Helm (`helm.tf`) e workloads Kubernetes (`k8s.tf`).

O arquivo `.terraform.lock.hcl` fixa as versoes dos providers. Estados, credenciais e arquivos locais sao ignorados pelo Git. O `teardown.sh` faz a remocao ordenada dos recursos dependentes do EKS.
