# CyberVegas no Kubernetes (Minikube) + Terraform + ArgoCD

Migração do projeto **CyberVegas** (backend FastAPI + frontend Angular + PostgreSQL)
para Kubernetes, gerenciada com **Terraform** (IaC portável) e **ArgoCD** (GitOps).

| Componente | Tecnologia | Réplicas | Porta |
|---|---|---|---|
| `frontend` | Angular 19 servido por nginx | 2 | 80 (NodePort) |
| `backend` | FastAPI (Python 3.11) | 2 | 8000 |
| `postgres` | PostgreSQL 16 | 1 (PVC) | 5432 |

O frontend acessa a API por URL relativa `/api`; o nginx faz proxy de `/api/*` para o
Service `backend:8000`. O backend acessa o banco via `DATABASE_URL` (Service `postgres`).

```
Browser ──► frontend (nginx, /api) ──► backend (FastAPI) ──► postgres
              (2 réplicas)             (2 réplicas)          (1 + PVC)
```

---

## 1. Pré-requisitos

- Docker
- Minikube (`minikube`)
- kubectl
- Terraform (`>= 1.5`)

## 2. Subir o Minikube

```bash
minikube start --driver=docker --cpus=4 --memory=3072 --disk-size=20g
minikube status
```

## 3. Buildar as imagens e disponibilizá-las no Minikube

As imagens são construídas **dentro** do daemon do Minikube, para que os Pods as
encontrem sem precisar de um registry externo.

Os três repositórios precisam estar clonados **lado a lado** (diretórios irmãos):

```text
workspace/
├── infrastructure/   # este repositório
├── backend/          # FastAPI
└── frontend/         # Angular
```

Rode a partir de `infrastructure/kubernetes/`:

```bash
minikube image build -t cybervegas-backend:latest  ../../backend
minikube image build -t cybervegas-frontend:latest ../../frontend
```

Se os repositórios estiverem em outros caminhos, use o caminho absoluto:
`minikube image build -t cybervegas-backend:latest /caminho/para/backend`.

> Use `minikube image build` (e **não** `docker build`). Com o runtime **containerd**
> do Minikube atual, `eval "$(minikube docker-env)"` + `docker build` falha no buildx
> e a imagem não fica disponível para os Pods.
>
> Confirme com: `minikube image ls | grep cybervegas`

## 4. Aplicar com Terraform (recomendado, portável)

O Terraform aplica os manifestos YAML de `../k8s/` (fonte única de verdade) e instala
o ArgoCD. Para migrar para a nuvem, basta trocar o contexto.

```bash
cd kubernetes

terraform init

# Local (minikube)
terraform apply

# Na nuvem — mesmo código, só o contexto muda
terraform apply -var 'kube_context=meu-cluster-oke' -var 'kubeconfig_path=~/.kube/config'

# ArgoCD com acesso ao repo privado (opcional)
terraform apply -var 'argocd_repo_token=SEU_TOKEN'
```

O que o Terraform faz:
1. Aplica `k8s/*.yaml` (Secret, ConfigMap, PVC, Deployments, Services).
2. Instala o ArgoCD (Helm) no namespace `argocd`.
3. Registra a credencial do repositório privado (se `argocd_repo_token` informado).
4. Cria a `Application` do ArgoCD que sincroniza o diretório `k8s/` do Git.

## 5. (Alternativa) Aplicar direto com kubectl

```bash
kubectl apply -f k8s/
```

## 6. Acessar a aplicação

```bash
minikube service frontend --url
# Ex.: http://192.168.49.2:30XXX

# Testar a API pelo proxy do frontend:
curl http://192.168.49.2:30XXX/api/          # -> {"status":"online",...}
curl http://192.168.49.2:30XXX/api/saldo     # -> {"saldo":<saldo do jogador>,...}
curl http://192.168.49.2:30XXX/api/pagamentos
```

## 7. ArgoCD (GitOps)

```bash
# URL da UI
minikube service -n argocd argocd-server --url

# Senha inicial do admin
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d

# Ver o status da aplicação
kubectl -n argocd get application cybervegas
```

A `Application` aponta para o repositório definido em `argocd_repo_url` (padrão:
`https://github.com/equipe-sudo/infrastructure`), diretório
`k8s/`). Com `selfHeal` e `prune`, qualquer mudança nos manifestos do Git é aplicada
automaticamente, e qualquer desvio no cluster é corrigido.

## 8. Demonstração (comandos da apresentação)

```bash
kubectl get pods -o wide
kubectl get services
kubectl get deployments
kubectl get pvc

# Balanceamento de carga (2 réplicas do backend):
kubectl get endpoints backend            # mostra os 2 IPs dos Pods
# gerando tráfego:
URL=$(minikube service frontend --url)
for i in $(seq 1 20); do curl -s "$URL/api/saldo" > /dev/null; done
kubectl logs -l app=backend --prefix --tail 100 | grep saldo

# Recriação automática de UM Pod (substitua pelo nome real):
kubectl get pods -l app=backend
kubectl delete pod <nome-de-um-pod>
kubectl get pods -o wide                 # o Deployment recria imediatamente
```

## 9. Migração para a nuvem

1. Aponte as imagens para um registry (GHCR/OCIR) e aplique `imagePullPolicy: Always`
   (ou troque as tags nos manifestos).
2. Rode `terraform apply -var 'kube_context=<contexto-do-cluster>'` — nada mais muda.
3. O estado do Terraform pode ir para um backend remoto (OCI Object Storage) para
   trabalho em equipe.

---

## Estrutura

```
k8s/                    # Manifestos Kubernetes (fonte única de verdade)
  01-secrets.yaml       #   credenciais do PostgreSQL
  02-configmap.yaml     #   config não sensível do backend
  03-postgres.yaml      #   PVC + Deployment + Service do PostgreSQL
  04-backend.yaml       #   Deployment (2 réplicas) + Service do FastAPI
  05-frontend.yaml      #   Deployment (2 réplicas) + Service do Angular
argocd/application.yaml # Application do ArgoCD (GitOps)
kubernetes/             # Terraform que aplica tudo (portável)
  provider.tf  variables.tf  main.tf  argocd.tf  outputs.tf
```

## 10. Reprodução em outra máquina (checklist)

Ordem exata para quem clonar os repositórios:

```bash
# 1. Pré-requisitos: docker, minikube, kubectl, terraform >= 1.5
minikube start --driver=docker --cpus=4 --memory=3072 --disk-size=20g

# 2. Imagens DENTRO do minikube (antes do apply)
minikube image build -t cybervegas-backend:latest  ../backend
minikube image build -t cybervegas-frontend:latest ../frontend
minikube image ls | grep cybervegas          # confirme as duas imagens

# 3. Aplicar tudo
cd kubernetes && terraform init && terraform apply

# 4. Validar
kubectl get pods -o wide
kubectl port-forward svc/frontend 8080:80    # http://localhost:8080
```

### ArgoCD em outra máquina

O ArgoCD aponta, por padrão, para o repositório privado da equipe. Sem acesso,
escolha uma das opções:

```bash
# A) Apontar para o seu fork, autenticando com PAT
terraform apply \
  -var 'argocd_repo_url=https://github.com/<seu-usuario>/infrastructure' \
  -var 'argocd_repo_username=<seu-usuario>' \
  -var 'argocd_repo_token=<PAT com escopo repo>'

# B) Não instalar o ArgoCD (a aplicação sobe igual, via Terraform)
terraform apply -var 'enable_argocd=false'
```

Na opção B, o cluster fica sem ArgoCD e sem a `Application`; todo o restante
(aplicação, observabilidade e dashboards) continua funcionando.

### O que não está no repositório (e por quê)

| Item | Motivo |
|---|---|
| Imagens `cybervegas-*` | Construídas localmente no Minikube (passo 2) |
| `terraform.tfstate` | Estado local, ignorado pelo `.gitignore` |
| Token do ArgoCD | Credencial pessoal, nunca versionada |
| Credenciais reais | O `Secret` usa credenciais de demonstração |

### Limitações conhecidas

- Sem registry externo: as imagens precisam ser construídas no Minikube.
- Não há Tempo/Jaeger: os traces chegam ao Collector, mas não são exploráveis.
- Não há cAdvisor: os dashboards não mostram CPU/memória por Pod.
- O PostgreSQL é validado por readiness; métricas internas exigiriam `postgres-exporter`.
