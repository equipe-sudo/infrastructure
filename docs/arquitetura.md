# Arquitetura Cloud — Equipe SUDO

> Jogo de Slots (Caça-Níquel) — OCI Always Free

## Diagrama

```
                          Internet
                             │
                             ▼
┌──────────────────────────────────────────────────┐
│  OCI — sa-saopaulo-1 (Tenancy: kolpzs)           │
│                                                   │
│  ┌─────────────────────────────────────────────┐ │
│  │  VCN: 10.0.0.0/16                           │ │
│  │                                             │ │
│  │  ┌───────────────────────────────────────┐  │ │
│  │  │  Subnet Pública: 10.0.1.0/24          │  │ │
│  │  │                                       │  │ │
│  │  │  ┌─────────────────────────────────┐  │  │ │
│  │  │  │  VM A1.Flex (2 OCPU + 12 GB)    │  │  │ │
│  │  │  │  Oracle Linux 8                  │  │  │ │
│  │  │  │                                 │  │  │ │
│  │  │  │  ┌───────────────────────────┐  │  │  │ │
│  │  │  │  │  Docker Compose            │  │  │  │ │
│  │  │  │  │                           │  │  │  │ │
│  │  │  │  │  ┌───────┐ ┌───────────┐  │  │  │  │ │
│  │  │  │  │  │Nginx  │ │ Backend   │  │  │  │  │ │
│  │  │  │  │  │:80    │→│ :8000     │  │  │  │  │ │
│  │  │  │  │  └───────┘ │ FastAPI   │  │  │  │  │ │
│  │  │  │  │            └─────┬─────┘  │  │  │  │ │
│  │  │  │  │                  │        │  │  │  │ │
│  │  │  │  │            ┌─────▼─────┐  │  │  │  │ │
│  │  │  │  │            │ PostgreSQL│  │  │  │  │ │
│  │  │  │  │            │ :5432     │  │  │  │  │ │
│  │  │  │  │            │ Volume    │  │  │  │  │ │
│  │  │  │  │            │ pgdata    │  │  │  │  │ │
│  │  │  │  │            └───────────┘  │  │  │  │ │
│  │  │  │  └───────────────────────────┘  │  │  │ │
│  │  │  └─────────────────────────────────┘  │  │ │
│  │  └───────────────────────────────────────┘  │ │
│  └─────────────────────────────────────────────┘ │
│                                                   │
│  ┌─────────────────────────────────────────────┐ │
│  │  Object Storage: equipe-sudo-tfstate         │ │
│  │  (terraform.tfstate remoto — futuro)         │ │
│  └─────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────┘
```

## Componentes

| Componente | Tecnologia | Porta | Descrição |
|---|---|---|---|
| **VCN** | OCI VCN | — | Rede virtual isolada |
| **Subnet** | Pública | — | 10.0.1.0/24, IPs públicos habilitados |
| **VM** | A1.Flex | 22, 80, 443, 8000 | Oracle Linux 8, 2 OCPU, 12 GB RAM |
| **Nginx** | Docker | 80 | Reverse proxy + serve frontend estático |
| **Backend** | FastAPI (Docker) | 8000 | API do jogo de slots |
| **PostgreSQL** | Docker | 5432 | Banco com volume persistente |
| **Volume** | Docker named vol | — | `pgdata` — sobrevive a restart |

## Fluxo do Jogador

```
Navegador → http://<ip> → Nginx:80
                              │
                              ├── / → index.html (frontend estático)
                              ├── /api/girar → proxy → Backend:8000/girar
                              ├── /api/depositar → proxy → Backend:8000/depositar
                              ├── /api/historico → proxy → Backend:8000/historico
                              └── /docs → proxy → Backend:8000/docs (Swagger)
```

## Justificativa das Escolhas

Ver [justificativas-tecnicas.md](./justificativas-tecnicas.md).
