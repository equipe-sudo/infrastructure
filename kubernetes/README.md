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

```bash
# Repositório backend (FastAPI)
cd <repo>/backend
docker build -t cybervegas-backend:latest .

# Repositório frontend (Angular)
cd <repo>/frontend
docker build -t cybervegas-frontend:latest .

# OU, a partir da raiz deste repositório:
eval "$(minikube docker-env)"
docker build -t cybervegas-backend:latest  /caminho/para/backend
docker build -t cybervegas-frontend:latest /caminho/para/frontend
```

> No `eval "$(minikube docker-env)"`, o `docker` passa a apontar para o daemon do
> Minikube. Sem isso, a imagem vai para o Docker local e o cluster não a encontra.

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
curl http://192.168.49.2:30XXX/api/saldo     # -> {"saldo":100.0,...}
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

A `Application` aponta para `https://github.com/equipe-sudo/infrastructure` (diretório
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
for i in $(seq 1 20); do curl -s http://$(minikube service frontend --url)/api/saldo >/dev/null; done
kubectl logs -l app=backend --prefix --tail 20   # as linhas alternam entre os 2 Pods

# Recriação automática de um Pod:
kubectl delete pod -l app=backend
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
