# Roteiro de Apresentação — Entrega 03 (CyberVegas no Kubernetes)

**Equipe SUDO** · Duração total: ~18–20 min · 4 apresentadores

> Objetivo da apresentação: demonstrar a migração do CyberVegas para Kubernetes
> (Minikube) e explicar os recursos utilizados, conforme os requisitos da Entrega 03.

## Divisão dos blocos

| Bloco | Apresentador | Conteúdo | Tempo |
|---|---|---|---|
| 1. Abertura | Fernanda | Equipe, projeto, objetivo | ~2 min |
| 2. A aplicação e a arquitetura | Allan | Componentes, comunicação, diagrama | ~3 min |
| 3. Preparação (conteinerização) | Thiago | Dockerfiles, imagens no Minikube, repositórios | ~3 min |
| 4. Implantação no Kubernetes | João | Deployments, Services, ConfigMap, Secret, PVC, probes | ~4 min |
| 5. Terraform e ArgoCD | João | IaC portável + GitOps | ~2 min |
| 6. Demonstração ao vivo | João | Comandos `kubectl`, app, balanceamento, recriação | ~5 min |
| 7. Encerramento | Fernanda | Resumo, entregas, perguntas | ~1 min |

---

## Bloco 1 — Abertura (Fernanda) · ~2 min

**Falar:**
- Boa tarde/noite; somos a Equipe SUDO (citar os 4 nomes).
- Nosso projeto é o **CyberVegas**, um cassino web (slot machine) com carteira de
  saldo e histórico de giros.
- Nesta entrega, o objetivo **não foi criar uma nova aplicação**, e sim **migrar o
  CyberVegas do Mensal 1 para o Kubernetes**, rodando tudo dentro de um cluster
  Minikube — aplicando conteinerização, orquestração e comunicação entre serviços.
- Roteiro do que vamos mostrar: arquitetura → preparação → implantação → demo ao vivo.

## Bloco 2 — A aplicação e a arquitetura (Allan) · ~3 min

**Falar:**
- O CyberVegas tem **3 componentes**:
  1. **Frontend** — Angular 19, servido por nginx.
  2. **Backend** — API FastAPI (Python), com os endpoints de jogo (`/girar`),
     carteira (`/saldo`, `/depositar`), autenticação (`/cadastrar`, `/login`).
  3. **Banco** — PostgreSQL 16.
- **Comunicação entre componentes** (ponto obrigatório da entrega):
  - O navegador acessa o frontend (Service `frontend`, NodePort).
  - O nginx do frontend faz proxy de `/api/*` para o Service `backend:8000`
    (o Angular usa URL relativa `/api`, então não há IP fixo no código).
  - O backend acessa o banco pelo Service `postgres:5432`, via `DATABASE_URL`
    vinda de um **Secret**.
- Mostrar o **diagrama de arquitetura** (slide) e reforçar: nenhum componente roda
  fora do cluster; toda a comunicação é via Services (DNS interno do Kubernetes).

## Bloco 3 — Preparação / conteinerização (Thiago) · ~3 min

**Falar:**
- Cada componente tem seu **Dockerfile** (já existia no Mensal 1):
  - `backend/Dockerfile` (FastAPI, Python 3.11-slim, porta 8000).
  - `frontend/Dockerfile` (build Angular em 2 estágios → nginx, porta 80).
  - Banco usa a imagem oficial `postgres:16-alpine`.
- As imagens foram buildadas **dentro do Minikube** (`minikube image build`), para
  os Pods encontrarem sem precisar de registry externo.
- Adaptações que fizemos no código para o Kubernetes:
  - Endpoints `/health` e `/health/ready` (para os probes).
  - `ALLOW_SQLITE_FALLBACK=false` (no cluster o banco é sempre o PostgreSQL).
- Onde está cada coisa nos repositórios (backend, frontend, infrastructure).

## Bloco 4 — Implantação no Kubernetes (João) · ~4 min

**Falar (explicar cada recurso usado):**
- **Deployments** — `backend` com **2 réplicas**, `frontend` com **2 réplicas**,
  `postgres` com 1 (atende ao requisito de ≥2 réplicas de um componente).
- **Services** — `backend`/`postgres` como **ClusterIP** (só internos) e `frontend`
  como **NodePort** (exposto ao navegador).
- **ConfigMap** — `cybervegas-config` (`SALDO_INICIAL`, `ENVIRONMENT`,
  `ALLOW_SQLITE_FALLBACK`).
- **Secret** — `cybervegas-secrets` (credenciais do banco + `DATABASE_URL`).
- **PersistentVolumeClaim** — `postgres-data` (1 Gi) para os dados sobreviverem à
  recriação do Pod.
- **initContainer** — `wait-for-postgres` espera o banco antes de subir o backend.
- **Probes** — liveness (`/health`) e readiness (`/health/ready`, que só responde
  200 quando o banco está acessível).

## Bloco 5 — Terraform e ArgoCD (João) · ~2 min

**Falar:**
- Todo o deploy é **Infraestrutura como Código** (Terraform): os manifestos de
  `k8s/` são aplicados pelo Terraform. Para migrar à nuvem, troca-se apenas o
  `kube_context` — nada mais muda.
- **ArgoCD (GitOps)**: instalado via Helm pelo Terraform; a `Application` observa o
  repositório e mantém o cluster sincronizado com o Git (estado atual: `Synced` e
  `Healthy`).

## Bloco 6 — Demonstração ao vivo (João) · ~5 min

> Roteiro exato dos comandos, na ordem. Manter um terminal aberto.

1. **Minikube de pé:**
   ```bash
   minikube status
   ```

2. **Pods (2 réplicas de backend e frontend):** *(requisito)*
   ```bash
   kubectl get pods -o wide
   ```
   → apontar as 2 réplicas do backend e as 2 do frontend (IPs distintos).

3. **Services:** *(requisito)*
   ```bash
   kubectl get services
   ```
   → frontend NodePort, backend e postgres ClusterIP.

4. **Deployments:** *(requisito)*
   ```bash
   kubectl get deployments
   ```

5. **Aplicação funcionando** (acessar e mostrar): *(requisito)*
   ```bash
   kubectl port-forward svc/frontend 8080:80
   # em outro terminal ou navegador: http://localhost:8080
   curl http://localhost:8080/api/saldo      # {"saldo":100.0,...}
   curl http://localhost:8080/api/pagamentos
   ```

6. **Balanceamento de carga** (2 Pods dividindo o tráfego):
   ```bash
   kubectl get endpoints backend
   kubectl logs -l app=backend --prefix --tail 30
   ```
   → mostrar as linhas alternando entre os 2 Pods.

7. **Recriação automática de Pod:** *(requisito)*
   ```bash
   kubectl get pods -l app=backend          # escolher UM pod
   kubectl delete pod <nome-de-um-pod>      # apagar só ele (não -l app=backend, que apaga os dois)
   kubectl get pods -o wide                 # novo Pod criado automaticamente
   ```

8. **ArgoCD (opcional, 10 s):**
   ```bash
   kubectl -n argocd get application cybervegas   # Synced / Healthy
   ```

## Bloco 7 — Encerramento (Fernanda) · ~1 min

**Falar:**
- Recapitular: CyberVegas 100% dentro do Minikube, com 2 réplicas, balanceamento,
  recriação automática, ConfigMap/Secret, persistência, Terraform e ArgoCD.
- Entregas: código-fonte, Dockerfiles, manifestos, README passo a passo e evidências
  (apontar os links no GitHub).
- Abrir para perguntas.

---

## Dicas gerais

- **Todos devem compreender a arquitetura** — o professor pode perguntar a qualquer
  um (requisito explícito). Revisar juntos o diagrama e a tabela de recursos.
- Ter o cluster já **pronto antes** de começar (pods `Running`) para a demo não ter
  espera.
- Se o `port-forward` não abrir no navegador, usar `curl` — a prova é a resposta JSON.
- Manter os comandos do Bloco 6 colados num terminal à parte para não digitar errado.
