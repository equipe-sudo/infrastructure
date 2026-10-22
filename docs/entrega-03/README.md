# CyberVegas — Migração para Kubernetes (Entrega 03)

**Equipe SUDO** · 20 de outubro de 2026

> Migração do projeto **CyberVegas** (Mensal 1) — backend **FastAPI** + frontend
> **Angular** + banco **PostgreSQL** — para uma infraestrutura **Kubernetes**,
> executada localmente com **Minikube**, gerenciada por **Terraform** (IaC) e
> **ArgoCD** (GitOps).

## Integrantes

- Allan Marcos Cardoso Garcia
- João Pedro Santos
- Josiane Steiernagel

## Repositórios

| Repositório | Conteúdo |
|---|---|
| [`equipe-sudo/backend`](https://github.com/equipe-sudo/backend) | Código-fonte do backend (FastAPI) + Dockerfile |
| [`equipe-sudo/frontend`](https://github.com/equipe-sudo/frontend) | Código-fonte do frontend (Angular) + Dockerfile + nginx |
| [`equipe-sudo/infrastructure`](https://github.com/equipe-sudo/infrastructure) | Manifestos K8s, Terraform, ArgoCD, documentação e evidências |

## 1. Objetivo

Aplicar os conceitos de **conteinerização, orquestração, gerenciamento de aplicações
e comunicação entre serviços**, adaptando o CyberVegas para rodar integralmente
dentro de um cluster Kubernetes. Não foi desenvolvida uma nova aplicação — o código
do Mensal 1 foi reaproveitado e apenas instrumentado para o Kubernetes.

## 2. Arquitetura

```
                        ┌──────────────────────────────────────────┐
                        │                 Minikube                 │
                        │  ┌─────────────────────────────────────┐ │
   Navegador ─────────► │  │  frontend  · NodePort :32206       │ │
   (http://<ip>)        │  │  nginx → Angular   (2 réplicas)    │ │
                        │  └───────────────────┬─────────────────┘ │
                        │                      │ /api/*            │
                        │  ┌───────────────────▼─────────────────┐ │
                        │  │  backend  · ClusterIP :8000         │ │
                        │  │  FastAPI          (2 réplicas)      │ │
                        │  └───────────────────┬─────────────────┘ │
                        │                      │ DATABASE_URL      │
                        │  ┌───────────────────▼─────────────────┐ │
                        │  │  postgres · ClusterIP :5432 + PVC   │ │
                        │  │  PostgreSQL 16     (1 réplica)      │ │
                        │  └─────────────────────────────────────┘ │
                        └──────────────────────────────────────────┘
```

O frontend (Angular) acessa a API por URL relativa `/api`; o nginx faz proxy de
`/api/*` para o Service `backend:8000`. O backend acessa o banco via `DATABASE_URL`
(Service `postgres:5432`). Nenhum componente roda fora do cluster.

## 3. Recursos Kubernetes utilizados

| Recurso | Uso | Justificativa |
|---|---|---|
| **Deployment** | `backend` (2 réplicas), `frontend` (2 réplicas), `postgres` (1) | Gerenciar o ciclo de vida e a contagem de réplicas; recriar Pods automaticamente |
| **Service** | `backend`/`postgres` (ClusterIP), `frontend` (NodePort) | Comunicação estável entre componentes via DNS e exposição do frontend |
| **ConfigMap** | `cybervegas-config` | Configuração não sensível (`SALDO_INICIAL`, `ENVIRONMENT`, `ALLOW_SQLITE_FALLBACK`) |
| **Secret** | `cybervegas-secrets` | Credenciais do PostgreSQL e `DATABASE_URL` (não expostas no Deployment) |
| **PersistentVolumeClaim** | `postgres-data` (1 Gi) | Persistir os dados do banco além do ciclo de vida do Pod |
| **initContainer** | `wait-for-postgres` | Aguardar o PostgreSQL aceitar conexões antes de subir o backend |
| **Probes** | `liveness` (`/health`) e `readiness` (`/health/ready`) | Só receber tráfego quando o banco estiver acessível; reiniciar se travar |

## 4. Passo a passo (reprodução)

O guia completo, com todos os comandos, está em
[`kubernetes/README.md`](../../kubernetes/README.md). Resumo:

```bash
# 1. Subir o Minikube
minikube start --driver=docker

# 2. Buildar as imagens DENTRO do Minikube
minikube image build -t cybervegas-backend:latest  ../backend
minikube image build -t cybervegas-frontend:latest ../frontend

# 3. Aplicar via Terraform (ou kubectl apply -f k8s/)
cd kubernetes
terraform init && terraform apply

# 4. Acessar
kubectl port-forward svc/frontend 8080:80
# abrir http://localhost:8080
```

## 5. Terraform — portabilidade para a nuvem

Todo o deploy é descrito como código no diretório `kubernetes/`. Para migrar do
Minikube para um cluster na nuvem (OKE/EKS), **basta trocar o contexto** — os
manifestos e o Terraform não mudam:

```bash
terraform apply -var 'kube_context=meu-cluster-oke'
```

## 6. ArgoCD — GitOps

O ArgoCD (instalado via Helm pelo Terraform) observa o repositório e mantém o
cluster sincronizado com o estado declarado no Git:

```bash
$ kubectl -n argocd get application cybervegas
NAME         SYNC STATUS   HEALTH STATUS
cybervegas   Synced        Healthy
```

A `Application` aponta para `equipe-sudo/infrastructure` (diretório `k8s/`), com
`selfHeal` (corrige desvios) e `prune` (remove recursos apagados do Git).

## 7. Demonstrações validadas

- ✅ Aplicação **funcional** — `GET /api/saldo` retorna o saldo real do usuário (PostgreSQL).
- ✅ **2 réplicas** do backend e do frontend, com balanceamento de carga entre os Pods.
- ✅ **Recriação automática** de Pod após exclusão (`kubectl delete pod`).
- ✅ **ConfigMap + Secret + PVC** em uso.
- ✅ **ArgoCD** sincronizado e saudável (GitOps).
- ✅ **Observabilidade** (extra, seção 8) — métricas da aplicação e do nó + traces via OpenTelemetry.

As saídas e capturas reais estão em [`evidencias.md`](evidencias.md) e
[`app-logada.png`](app-logada.png).

## 8. EXTRA — Observabilidade do cluster e da aplicação

> **Extra** — vai além dos requisitos da Entrega 03. Instalamos uma stack de
> observabilidade **dentro do próprio cluster Minikube** para validar o
> **Kubernetes** (métricas do nó) e a **aplicação** (métricas e traces do backend).

### Fluxo dos dados

```
backend (OTel SDK) ──OTLP/HTTP :4318──► otel-collector ──/metrics :8889──► prometheus ──► grafana
node-exporter (DaemonSet) ────────────────────────────► prometheus
kube-state-metrics ───────────────────────────────────► prometheus
```

- **Backend instrumentado com OpenTelemetry** — auto-instrumentação do FastAPI
  (`instrumentation.py`) gera **métricas** e **traces** via OTLP/HTTP.
- **OpenTelemetry Collector** — recebe OTLP e expõe as métricas no formato Prometheus.
- **Prometheus** — coleta as métricas do Collector (aplicação), do **node-exporter** (nó)
  e do **kube-state-metrics** (estado do cluster).
- **Grafana** — visualização, com datasource Prometheus e **dois dashboards** provisionados.
- **node-exporter** — métricas de CPU/memória/disco/rede do nó.
- **kube-state-metrics** — estado dos objetos (pods, deployments, restarts, fases).

### Dashboards (provisionados)

| Dashboard | UID | Baseado em |
|---|---|---|
| **CyberVegas — Aplicação** | `cybervegas-app` | painéis de latência/erros/uso (modelo do dashboard do to-do da Equipe SUDO) |
| **CyberVegas — Cluster** | `cybervegas-cluster` | template `[TEMPLATE] - Kubernetes Cluster Health` do hub-grafana |

### O que cada sinal valida

| Sinal | Origem | Métricas |
|---|---|---|
| Aplicação | Backend → Collector → Prometheus | `http_server_duration_milliseconds`, `http_server_active_requests`, `http_server_response_size_bytes` |
| Nó (cluster) | node-exporter | `node_cpu_seconds_total`, `node_memory_*`, `node_disk_*` |
| Estado do cluster | kube-state-metrics | `kube_pod_status_phase`, `kube_pod_container_status_restarts_total`, `kube_deployment_status_replicas_unavailable` |
| Traces | Backend → Collector | spans por requisição HTTP |

### Acesso

```bash
kubectl port-forward svc/grafana 3000:3000       # Grafana (admin/admin)
kubectl port-forward svc/prometheus 9090:9090    # Prometheus (consulta)
```

### Arquivos

- `k8s/06-otel-collector.yaml` · `07-prometheus.yaml` · `08-grafana.yaml` · `09-node-exporter.yaml`
- `k8s/10-grafana-dashboard.yaml` (app) · `11-kube-state-metrics.yaml` · `12-grafana-dashboard-cluster.yaml`
- `backend/instrumentation.py` (SDK OpenTelemetry)

## 9. Considerações

- As imagens são construídas **dentro do Minikube** (sem registry externo). Para a
  nuvem, basta publicar no GHCR/OCIR e trocar a tag nos manifestos.
- O backend foi adaptado com endpoints `/health` e `/health/ready` e com
  `ALLOW_SQLITE_FALLBACK=false` (no cluster o banco é sempre o PostgreSQL dedicado).
- O ArgoCD acessa o repositório privado via token de leitura (documentado no README).
