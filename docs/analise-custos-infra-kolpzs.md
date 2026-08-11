# Análise de Custos e Viabilidade — Conta Pessoal OCI (kolpzs)

> **Data:** 23/07/2026  
> **Conta:** kolpzs (TENLS-6209)  
> **Região:** sa-saopaulo-1 (AD-1)  
> **Perfil OCI CLI:** `KOLPZS` (separado do perfil corporativo `DEFAULT`/yvy)

---

## 1. Situação Atual da Conta

A conta **kolpzs** está **zerada** — sem compartments, sem VMs, sem banco, sem buckets. Apenas o tenancy raiz existe, com 1 Availability Domain.

Isso é um **cenário ideal** para começar o projeto do 8º período: garantia de que **nenhum recurso legado** pode gerar custo inesperado.

---

## 2. Limites Always Free Confirmados via CLI

| Recurso | Limite Always Free | O que podemos usar |
|---|---|---|
| **VM (Ampere A1)** | Até **4 OCPUs** + **24 GB RAM** | 1 VM com 2 OCPUs + 12 GB (sobra para outro app) |
| **Boot Volume** | Até **200 GB** total (incluindo boot) | 1 disco boot de ~50 GB + 150 GB para dados |
| **Object Storage** | **20 GB** padrão | Buckets para assets, backups de config, tfstate |
| **Autonomous DB** | Até **2 DBs**, 1 OCPU + 20 GB cada | BD para aplicação do semestre |
| **Load Balancer** | 1 instance (10 Mbps flex) | Opcional — para expor múltiplos serviços |
| **VCN** | 1 VCN + 3 IPs públicos | Rede do projeto |
| **Bandwidth** | 10 TB/mês (outbound) | Mais que suficiente para projeto acadêmico |
| **Monitoring** | 500M ingestion / 10B retrieval | Métricas do sistema gratuitas |
| **DNS** | 1 zona pública | Se precisar de domínio |

> ⚠️ **Importante:** Os limites de conta via CLI mostram valores maiores (ex: `standard-a1-core-regional-count: 16`), mas o **Always Free** se aplica apenas aos primeiros 4 OCPUs A1 + 24 GB. Acima disso começa a cobrar.

---

## 3. Comparativo: Relatório Original vs Conta Real

| Item do Relatório | Reivindicado | Real (kolpzs) | Custo |
|---|---|---|---|
| VM Linux (2 núcleos ARM, 12 GB RAM) | ✅ | ✅ Ampere A1 Flex cabe perfeitamente | **R$ 0,00** |
| 200 GB de disco | ✅ | ✅ 200 GB Always Free | **R$ 0,00** |
| IP público | ✅ | ✅ 3 disponíveis na camada gratuita | **R$ 0,00** |
| 20 GB para arquivos/backups | ✅ | ✅ Object Storage 20 GB | **R$ 0,00** |
| PostgreSQL (ou banco) | ✅ | ✅ Pode rodar na própria VM ou usar Autonomous DB grátis | **R$ 0,00** |
| Nginx | ✅ | ✅ Roda na VM sem custo extra | **R$ 0,00** |
| GitHub Actions (CI/CD) | ✅ | ✅ GitHub Actions grátis para org GitHub (pública) | **R$ 0,00** |
| Kubernetes (OKE) | ⚠️ | OKE não é Always Free — VMs do cluster são cobradas | ⚠️ **Evitar** |

---

## 4. Riscos de Custo — O que NÃO fazer

### 🔴 OKE (Oracle Kubernetes Engine)
O maior risco de custo. OKE provisiona **VMs adicionais** para os nodes do cluster. Mesmo o serviço OKE sendo gratuito, **as VMs dos nodes são cobradas** (shape `VM.Standard.E4.Flex` ou similar). A conta corporativa (yvy) paga por um cluster OKE; na pessoal, **não crie OKE**.

### 🟡 Shapes que não são Always Free
| Shape | Custo/hora (approx) | Custo/mês (approx) |
|---|---|---|
| `VM.Standard.E4.Flex` | ~US$ 0,02/OCPU/h | ~US$ 15+ |
| `VM.Standard.E5.Flex` | ~US$ 0,025/OCPU/h | ~US$ 18+ |
| `VM.Standard.E6.Flex` | ~US$ 0,03/OCPU/h | ~US$ 22+ |

**Solução:** Use **sempre** `VM.Standard.A1.Flex` (Ampere ARM), que é o shape coberto pelo Always Free.

### 🟡 Block Volume acima de 200 GB
O boot volume conta nos 200 GB. Se criar um volume extra, some ao boot. Ex: boot de 100 GB + volume de 150 GB = 250 GB → **50 GB serão cobrados**.

### 🟡 Autonomous Database acima de 2 instâncias
A terceira instância de Autonomous DB começa a cobrar. Mantenha no máximo 2.

---

## 5. Arquitetura Proposta — Zero Custo

```
┌─────────────────────────────────────────────────┐
│                   OCI (kolpzs)                   │
│               sa-saopaulo-1 (AD-1)               │
│                                                  │
│  ┌─────────────────────────────────────────┐    │
│  │  VCN (10.0.0.0/16)                      │    │
│  │  ┌──────────────────────────────────┐   │    │
│  │  │  Subnet Pública (10.0.1.0/24)    │   │    │
│  │  │                                  │   │    │
│  │  │  VM.Standard.A1.Flex             │   │    │
│  │  │  ├── 2 OCPUs + 12 GB RAM         │   │    │
│  │  │  ├── Ubuntu 22.04 LTS            │   │    │
│  │  │  ├── Docker / Podman             │   │    │
│  │  │  ├── PostgreSQL                  │   │    │
│  │  │  ├── Nginx (reverse proxy)       │   │    │
│  │  │  └── Aplicação Python            │   │    │
│  │  └──────────────────────────────────┘   │    │
│  │                                          │    │
│  │  Boot Volume: 50 GB                      │    │
│  │  Block Volume extra: 150 GB (dados)      │    │
│  │  → Total: 200 GB (dentro do limite!)     │    │
│  │                                          │    │
│  │  Object Storage: 20 GB                   │    │
│  │  ├── Bucket: tfstate (Terraform state)   │    │
│  │  └── Bucket: backups                     │    │
│  └─────────────────────────────────────────┘    │
│                                                  │
│  IP Público: 1 (reservado, Elastic IP)          │
└─────────────────────────────────────────────────┘
         │
         ├── GitHub (org pessoal do semestre)
         │   ├── Repo: infra (Terraform/IaC)
         │   ├── Repo: app (código da aplicação)
         │   └── GitHub Actions (CI/CD gratuito)
         │
         └── Acesso SSH (porta 22 apenas por chave)
```

---

## 6. Projeção de Custos

### Cenário Base (dentro do Always Free) — **R$ 0,00/mês**

| Item | Custo |
|---|---|
| 1x VM.Standard.A1.Flex (2 OCPU + 12 GB) | **Grátis** |
| 1x Boot Volume (50 GB) | **Grátis** |
| 1x Block Volume (150 GB) | **Grátis** |
| 1x Object Storage (20 GB) | **Grátis** |
| 1x VCN + IP Público | **Grátis** |
| Bandwidth (10 TB outbound) | **Grátis** |
| GitHub (org pública, Actions grátis) | **Grátis** |
| **TOTAL** | **R$ 0,00** |

### Cenário de Crescimento (se um dia sair do Always Free)

Se o projeto precisar de mais recursos e optar por upgrade pago:

| Item | Custo estimado (USD/mês) |
|---|---|
| Dobro da VM (4 OCPU + 24 GB A1) | ~US$ 25–28 |
| Block Volume extra (+100 GB) | ~US$ 5 |
| Load Balancer (10 Mbps) | ~US$ 10 |
| **TOTAL (estimado)** | **~US$ 25–28/mês** |

---

## 7. Conclusão

A conta pessoal **kolpzs** na OCI atende **totalmente** a demanda do projeto do 8º período **sem gerar nenhum custo**. Basta seguir as regras:

1. ✅ Usar **sempre** shape `VM.Standard.A1.Flex` (Ampere ARM)
2. ✅ Manter boot + block volume **≤ 200 GB** no total
3. ✅ Máximo de **2 Autonomous Databases**
4. ✅ Máximo de **1 Load Balancer** (se usar)
5. ❌ **Não criar** OKE (Kubernetes) — inviável no Always Free
6. ❌ **Não usar** shapes E4/E5/E6 — são cobrados
7. ✅ Git Actions + GitHub: usar **repositórios públicos** para não consumir minutos privados

---

## Anexo: Perfis OCI CLI

| Perfil | Conta | Uso |
|---|---|---|
| `DEFAULT` | **yvy** (corporativa H2O) | Trabalho |
| `KOLPZS` | **kolpzs** (pessoal) | Faculdade / Projetos pessoais |

Comando para usar o perfil pessoal:
```bash
oci --profile KOLPZS <comando>
```

Ou exportar como padrão da sessão:
```bash
export OCI_CLI_PROFILE=KOLPZS
```
