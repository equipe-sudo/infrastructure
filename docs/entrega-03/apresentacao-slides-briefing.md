# Briefing para o agente de PowerPoint — Entrega 03

> Use este texto como prompt/comando para um agente gerar os slides. Ele descreve
> o que cada slide deve ter, em ordem, com conteúdo, visual e quem apresenta.

## Instruções gerais de design

- Tema **escuro com acentos neon** (verde `#57d38a` e roxo/dourado, remetendo ao
  cassino CyberVegas), ou um tema claro limpo se preferir — mas **consistente** em
  todos os slides.
- Fonte de títulos sem serifa (ex.: Montserrat/Poppins); **código e comandos em
  fonte monoespaçada** (ex.: JetBrains Mono / Consolas), com fundo escuro e texto
  claro.
- Um **diagrama de arquitetura** (slide 4) desenhado com caixas e setas, usando a
  mesma paleta.
- Menos texto, mais **bullets curtos** (máx. 5–6 por slide). Slides de código
  mostram o comando grande e centralizado.
- Rodapé em todos os slides: "Equipe SUDO — Entrega 03 · CyberVegas no Kubernetes".

## Slides (12)

### Slide 1 — Capa
- Título: **CyberVegas no Kubernetes**
- Subtítulo: "Migração para Minikube · Entrega 03"
- Linha: **Equipe SUDO** — João Pedro, Fernanda, Thiago, Allan
- Visual: fundo escuro com acento neon; ícone de dado/cassino sutil.

### Slide 2 — Objetivo
- Título: **Objetivo da entrega**
- Bullets:
  - Migrar o CyberVegas (Mensal 1) para Kubernetes (Minikube).
  - Aplicar conteinerização, orquestração e comunicação entre serviços.
  - **Não** desenvolver app nova — adaptar a existente.
- Visual: 3 ícones (container → cluster → rede).

### Slide 3 — A aplicação
- Título: **CyberVegas — o que é**
- 3 cards:
  - **Frontend** — Angular 19 + nginx
  - **Backend** — FastAPI (Python) — `/girar`, `/saldo`, `/depositar`, login
  - **Banco** — PostgreSQL 16
- Visual: 3 caixas horizontais.

### Slide 4 — Arquitetura
- Título: **Arquitetura no cluster**
- Diagrama: `Navegador → frontend (NodePort, 2 réplicas) → backend (ClusterIP, 2 réplicas) → postgres (ClusterIP + PVC)`.
- Nota: "Comunicação via Services (DNS interno). URL relativa `/api`."

### Slide 5 — Conteinerização
- Título: **Preparação — Dockerfiles**
- Bullets:
  - `backend/Dockerfile` (FastAPI, porta 8000)
  - `frontend/Dockerfile` (build Angular → nginx, porta 80)
  - `postgres:16-alpine` (imagem oficial)
  - Imagens buildadas dentro do Minikube (`minikube image build`)
- Visual: trechos dos Dockerfiles em fonte mono.

### Slide 6 — Recursos Kubernetes (1/2)
- Título: **Implantação — Deployments e Services**
- Tabela:
  | Recurso | Réplicas | Service |
  |---|---|---|
  | backend | 2 | ClusterIP :8000 |
  | frontend | 2 | NodePort :32206 |
  | postgres | 1 | ClusterIP :5432 |

### Slide 7 — Recursos Kubernetes (2/2)
- Título: **ConfigMap, Secret, PVC e probes**
- Bullets:
  - **ConfigMap** — config não sensível (SALDO_INICIAL, ENVIRONMENT).
  - **Secret** — credenciais do banco + DATABASE_URL.
  - **PVC** — persistência do PostgreSQL (1 Gi).
  - **initContainer + probes** — espera o banco; liveness/readiness.

### Slide 8 — Disponibilidade
- Título: **2 réplicas, balanceamento e recriação**
- 3 bullets com mini-screenshot/ícone:
  - 2 réplicas do backend/frontend.
  - Balanceamento de carga (round-robin do Service).
  - `kubectl delete pod` → Deployment recria automaticamente.

### Slide 9 — Terraform (IaC)
- Título: **Tudo como código (Terraform)**
- Bullets:
  - Deploy descrito em Terraform (portável).
  - Migrar à nuvem = trocar `kube_context`.
- Comando: `terraform apply -var 'kube_context=meu-cluster'`

### Slide 10 — ArgoCD (GitOps)
- Título: **GitOps com ArgoCD**
- Bullets:
  - ArgoCD observa o repositório e sincroniza o cluster.
  - Estado: `Synced` / `Healthy`.
- Visual: badge verde "Synced · Healthy".

### Slide 11 — Demonstração
- Título: **Demonstração ao vivo**
- Lista dos comandos (fonte mono): `kubectl get pods -o wide`, `kubectl get services`,
  `kubectl get deployments`, `kubectl delete pod -l app=backend`.
- Nota: "Aplicação respondendo via `curl /api/saldo` → `{"saldo":100.0}`."

### Slide 12 — Encerramento
- Título: **Obrigado / Perguntas**
- Bullets resumo + links (repositórios GitHub) + "Equipe SUDO".
- Visual: logo/acento neon, contato.

## Notas de quem apresenta (para o agente colocar nos comentários do slide)

1. Capa — Fernanda
2. Objetivo — Fernanda
3. A aplicação — Allan
4. Arquitetura — Allan
5. Conteinerização — Thiago
6. Recursos 1/2 — João
7. Recursos 2/2 — João
8. Disponibilidade — João
9. Terraform — João
10. ArgoCD — João
11. Demonstração — João
12. Encerramento — Fernanda
