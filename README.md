# FIAP DevOps - Terraform

Infraestrutura como codigo para o Tech Challenge Fase 3. O projeto provisiona a base AWS e os recursos de execucao do ToggleMaster.

## Recursos

- VPC com subnets publicas e privadas, NAT Gateway e endpoints S3/DynamoDB
- Cluster Amazon EKS e node group em subnets privadas
- Repositorios ECR para os cinco microsservicos
- Tres bancos PostgreSQL no Amazon RDS
- Redis no Amazon ElastiCache
- Fila Amazon SQS e tabela DynamoDB para analytics
- Metrics Server, Nginx Ingress e ArgoCD via Helm (add-ons de plataforma do cluster)

Este repositorio cobre a infraestrutura (Requisito 1 do Tech Challenge Fase 3) + a instalacao do ArgoCD.
Namespace, Secrets, ConfigMaps, Deployments, Services, Ingress das aplicacoes e HPAs **nao** sao
provisionados aqui — ficam no repositorio `FIAP-DevOps-kubernetes` (GitOps), sincronizados pelo ArgoCD
instalado por este Terraform. Veja "Integracao com GitOps/ArgoCD" abaixo.

## Pre-requisitos

- Terraform >= 1.5
- AWS CLI configurada com permissao para os recursos acima
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

6. Configure o acesso ao cluster (nenhum pod de aplicacao aparece neste ponto — eles sao criados pelo ArgoCD a partir do repositorio de GitOps):

```bash
aws eks update-kubeconfig --region us-east-1 --name togglemaster-cluster
kubectl get nodes
```

Para remover a infraestrutura, revise o impacto e execute `terraform destroy`.

Como o provider Helm depende do cluster EKS e o Nginx Ingress cria um Load Balancer, a remocao direta pode falhar. Use o script abaixo para limpar esses recursos enquanto o cluster ainda esta acessivel:

```bash
./teardown.sh
```

O script exige `backend.hcl`, usa `AWS_REGION` e `EKS_CLUSTER_NAME` quando informados, e nao remove Load Balancers de outros projetos.

## AWS Academy

Em ambiente AWS Academy, a LabRole existente deve ser usada e o projeto nao pode criar IAM Roles ou Policies. Nesse caso, adapte `modules/eks/main.tf` para referenciar a LabRole por data source ou variavel (em vez dos `aws_iam_role` atuais) antes de aplicar. A configuracao atual cria roles proprias e e adequada para conta AWS pessoal, conforme a Opcao B do enunciado.

## Integracao com GitOps/ArgoCD

Este repositorio instala o ArgoCD (`helm_release.argocd`, namespace `argocd`) mas nao cria nenhum manifesto
Kubernetes das aplicacoes — isso fica no repositorio `FIAP-DevOps-kubernetes`. Depois do `terraform apply`,
para montar os Secrets desse repositorio, use os valores abaixo:

```bash
terraform output ecr_repositories     # URLs dos 5 repositorios ECR (imagem por servico)
terraform output rds_endpoints        # endpoint de cada instancia RDS (auth, flags, targeting)
terraform output redis_endpoint       # endpoint do ElastiCache
terraform output sqs_queue_url        # URL da fila SQS
terraform output dynamodb_table_name  # nome da tabela DynamoDB
terraform output eks_cluster_name     # nome do cluster, para update-kubeconfig
```

O namespace `togglemaster`, os Secrets com as connection strings acima, os Deployments/Services/Ingress dos 5
microsservicos e os HPAs sao criados pelos manifestos do `FIAP-DevOps-kubernetes` (sincronizados pelo
ArgoCD) — nao pelo Terraform. O Nginx Ingress Controller (`helm.tf`) ja fica disponivel no cluster para esse
Ingress apontar.

### Acessar a interface do ArgoCD

O `server.service` do ArgoCD e um `LoadBalancer` dedicado (NLB), separado do Load Balancer do Nginx
Ingress usado pelas aplicacoes. Depois do `terraform apply`, o hostname leva alguns minutos pra ficar
disponivel:

```bash
kubectl -n argocd get svc argocd-server
# aguarde a coluna EXTERNAL-IP preencher com um hostname *.elb.amazonaws.com

# senha admin inicial:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

Abra `https://<EXTERNAL-IP-do-svc>` no navegador (o certificado e autoassinado, o navegador vai avisar —
aceite o risco), usuario `admin` + a senha acima. Esse endereco pode ser compartilhado com o time, sem
precisar de `port-forward` nem VPN. Depois de aplicar os manifestos de `argocd/` do repositorio
`FIAP-DevOps-kubernetes` (`kubectl apply -f argocd/`), os 6 Applications (plataforma + 5 microsservicos)
aparecem nessa interface.

Esse Load Balancer extra tem um custo pequeno (~US$0,60/dia) enquanto o cluster existir — lembre de
`terraform destroy` quando terminar de gravar o video.

## Estrutura

O projeto e componentizado em modulos, um por responsabilidade. O root module (`main.tf`) so instancia
cada um passando as variaveis necessarias e liga as saidas de um modulo como entrada de outro:

```
.
├── main.tf                  # providers (aws, helm) + chamada dos modulos
├── variables.tf             # variaveis do projeto (region, tamanhos, credenciais de banco)
├── outputs.tf                # agrega as saidas dos modulos (ECR, RDS, Redis, SQS, DynamoDB, EKS)
├── backend.tf                # backend remoto S3
├── helm.tf                   # add-ons de plataforma: Metrics Server, Nginx Ingress e ArgoCD
└── modules/
    ├── networking/           # VPC, subnets publicas/privadas, IGW, NAT, route tables, VPC endpoints
    ├── eks/                  # IAM roles, cluster EKS, security group e node group
    ├── database/             # security groups, 3 RDS PostgreSQL, ElastiCache Redis, tabela DynamoDB
    ├── messaging/            # fila SQS
    └── ecr/                  # 5 repositorios ECR + politica de lifecycle
```

Cada modulo tem seu proprio `variables.tf`/`outputs.tf` e nao referencia recursos de outro modulo
diretamente — toda a ligacao entre eles (ex: o modulo `eks` recebendo o `vpc_id` do modulo `networking`)
acontece explicitamente no `main.tf` do root.

O arquivo `.terraform.lock.hcl` fixa as versoes dos providers. Estados, credenciais e arquivos locais sao ignorados pelo Git. O `teardown.sh` faz a remocao ordenada dos recursos dependentes do EKS.
