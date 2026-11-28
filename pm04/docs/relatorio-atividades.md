# Relatório de Atividades — PM-04 · 27/11/2026

> **Equipe:** SUDO (Fernanda Andrieli Chini Konzen, João Pedro Pereira dos Santos)
> **Repositório:** https://github.com/equipe-sudo/infrastructure (diretório `pm04/`)

---

## 1. Objetivo

Projeto final (PM-04): automatizar a infraestrutura do **Smart Construction** (Bubikas Holdings) com **Terraform + Ansible + GitHub Actions**, cobrindo provisionamento, configuração, atualização e encerramento. Foco do dia: entregar o PDF e deixar o deploy em andamento para a demonstração.

---

## 2. Linha do tempo (ações do dia)

| Horário (UTC) | Ação |
|---|---|
| ~13:36 | Destruída a infra OCI antiga (projeto slots/CyberVegas) para liberar capacidade Always Free |
| ~14:15 | 1ª tentativa de deploy na OCI (`A1.Flex` ARM) → **"Out of host capacity"** |
| ~18:19–20:06 | Tentativas com `E2.1.Micro` (AMD) → também **sem capacidade** |
| ~18:30 | Diagnóstico: tenancy limitada a **1 região** e **0 NAT gateways** (Free Tier) |
| ~18:45 | Decisão: **migrar para AWS Free Tier** |
| ~19:00–20:50 | Criação da conta AWS, IAM, secrets; resolução da cadeia de bloqueios (ver §3) |
| ~20:55 | `terraform apply` **concluído** — VPC, 2 subnets, SGs, 2× EC2 `t3.micro` provisionadas |
| ~21:55 | PDF de entrega gerado |
| ~00:57 | `terraform destroy` (encerrar tudo, custo zero) |

---

## 3. Decisões de arquitetura

- **Provedor: AWS Free Tier** (a partir de OCI). A OCI foi descartada por dois bloqueios operacionais — `sa-saopaulo-1` sem capacidade Always Free e tenancy limitada a 1 região — e não por custo (Always Free é vitalício).
- **2 VMs**: `vm-sc-app` (pública, Docker com nginx/web/api/storages) + `vm-sc-db` (privada, PostgreSQL 17 exclusivo).
- **Banco privado sem IP público**, com egress via **NAT na própria VM app** (masquerade) — evita o NAT Gateway pago (~US$ 32/mês).
- **Imagens privadas no GHCR**, puxadas pela VM app via `docker login` (secrets do repo).

---

## 4. FinOps + Observabilidade (integrado)

O controle de custo e a observação do ambiente estão unificados no workflow **`pm04-infra-report.yml`**, que gera um relatório (no Job Summary) com **estado da infra + custo** ao mesmo tempo:

| Sinal | O que mede | Fonte |
|---|---|---|
| **EC2** (instâncias, tipos, estados, IPs) | o que está rodando | `aws ec2 describe-instances` |
| **Custo mensal estimado** (on-demand) | FinOps — previsão | taxas por tipo de instância |
| **EBS** (GB total) | armazenamento vs Free Tier (30 GB) | `aws ec2 describe-volumes` |
| **Elastic IPs não-associados** | alerta de custo oculto (~US$ 0,005/h) | `aws ec2 describe-addresses` |
| **S3** (buckets) | state + objetos | `aws s3api list-buckets` |
| **Cost Explorer** (custo real 7 dias) | FinOps — custo real | `aws ce get-cost-and-usage` |
| **Status Free Tier** | resumo de uso vs 750 h/mês | cálculo próprio |

**Disparo:** manual (`workflow_dispatch`) + automático diário (`cron 0 12 * * *`).

### Observabilidade do deploy

- **Smoke test** no `pm04-deploy.yml`: valida `http/https://<app>/healthz` (retry 10×, falha com `::error::`).
- **Passo de diagnóstico** (`if: failure()`): em caso de erro, faz SSH na VM app e coleta `docker logs` + `docker ps` — foi isso que revelou o bug do `role smart_api`.
- **Logs**: Terraform (`plan`/`apply`), Ansible (callback `default`) e Docker (`logging: local`).

### Custos (FinOps)

- **Estimativa mensal: US$ 0,00** no uso de demo (Free Tier: 750 h/mês de `t3.micro`, 30 GB EBS, 5 GB S3, 100 GB egress).
- **US$ 100 de crédito AWS** como margem de segurança.
- **Budget** configurado em US$ 10/mês (alerta), **sem** SpendLimit (o SCP de deny travava a criação de recursos).
- **Encerramento:** `pm04-destroy.yml` remove tudo (EC2/VPC/SGs/EBS) → custo zero após o dia.

---

## 5. Bloqueios encontrados e resolvidos (lições)

| # | Bloqueio | Causa | Solução |
|---|---|---|---|
| 1 | `Out of host capacity` (OCI) | região sem capacidade Always Free | migrar para AWS |
| 2 | `nat-gateway-count = 0` | Free Tier não tem NAT gateway | NAT na VM app |
| 3 | Tenancy limitada a 1 região | limite do Free Tier | não dá para trocar de região |
| 4 | SCP `BudgetsSpendLimitDeny...` negava `s3:CreateBucket` | SpendLimit ativado com limite baixo | usar a Management Account + subir o limite |
| 5 | `invalid value for name (cannot begin with sg-)` | prefixo `sg-` reservado pela AWS | renomear SGs para `sc-*` |
| 6 | `Character sets beyond ASCII` | acento na `description` do SG | remover acentos |
| 7 | `community.docker`/`community.general` ausentes | collections não instaladas | `ansible-galaxy collection install` |
| 8 | `yaml` callback removido | community.general v12 removeu o plugin | `stdout_callback = default` |
| 9 | `curl` conflita com `curl-minimal` | AL2023 já tem curl-minimal | remover `curl` do `extra_packages` |
| 10 | `unauthorized` no pull do GHCR | imagens privadas | `docker login` na VM app |
| 11 | `role "smart_api" does not exist` | `CREATE ROLE` em bloco DO (proibido) | `EXECUTE` + task idempotente |

---

## 6. Pendências (para a apresentação)

1. **`api-migrate`** — confirmar a migração Alembic após o fix do role `smart_api`.
2. **Domínio Cloudflare** (`equipe-sudo.kolpzs.com`) — HTTPS real via Cloudflare Tunnel.
3. **Rodar os 3 cenários ao vivo** (criação / atualização / idempotência) e capturar evidências reais.

---

## 7. Estado atual

- ✅ Código completo (Terraform + Ansible + CI/CD) e versionado.
- ✅ Infraestrutura provisionada e encerrada (destroy) — custo **zero** no momento.
- ✅ PDF de entrega gerado (`pm04/docs/entrega-final.pdf`).
- ⏳ Demonstração ao vivo (smoke test + 3 cenários) para a apresentação.
