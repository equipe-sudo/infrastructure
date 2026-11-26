# Custos — PM-04 (Smart Construction)

> **Projeto:** PM-04 — "Smart Construction"
> **Provedor:** OCI — Always Free, região `sa-saopaulo-1`
> **Preços de referência:** lista pública OCI (valores estimados em USD/mês, sem imposto, arredondados).

---

## 1. Estimativa mensal por recurso

### 1.1 Cenário Always Free (real) — **USD 0,00/mês**

| Recurso | Quantidade | Always Free | Custo/mês |
|---|---|---|---|
| VM `vm-sc-app` — `VM.Standard.E2.1.Micro` (1 OCPU, 1 GB) | 1 | ✅ | **$0,00** |
| VM `vm-sc-db` — `VM.Standard.E2.1.Micro` (1 OCPU, 1 GB) | 1 | ✅ | **$0,00** |
| Boot volumes (2× ~47 GB) | ~94 GB | ✅ (limite 200 GB) | **$0,00** |
| Block volume de dados (se usado) | até ~100 GB | ✅ (soma ≤ 200 GB) | **$0,00** |
| Object Storage (backups, tfstate) | ≤ 20 GB | ✅ | **$0,00** |
| Rede: Internet Gateway, VCN, 1 IP público (app) | conjunto | ✅ | **$0,00** |
| Egress de Internet | ≪ 10 TB/mês | ✅ | **$0,00** |
| **TOTAL** | | | **$0,00 / mês** |

### 1.2 Se sair do free tier (referência de shapes equivalentes pagos)

| Recurso | Equivalente pago | Custo estimado (USD/mês) |
|---|---|---|
| 2× VM aplicação+banco | `VM.Standard.E4.Flex` 1 OCPU / 1 GB (~US$0,025/OCPU/h) | ~US$ 36–38 |
| 2× VM (alternativa ARM) | `VM.Standard.A1.Flex` 1 OCPU + 1 GB | ~US$ 8–10 |
| Boot volume além dos 200 GB | Block volume ~US$0,04/GB/mês | + US$ 4 / +100 GB |
| Object Storage além dos 20 GB | ~US$0,0255/GB/mês | + US$ 2,55 / +100 GB |
| Egress além dos 10 TB | ~US$0,0085/GB | + US$ 8,50 / +1 TB |
| Backup de boot volume | ~US$0,025/GB/mês | ~US$ 1,20 / 50 GB |
| **TOTAL estimado (se pago)** | | **~US$ 40–55 / mês** |

> Os valores pagos são **referência** e dependem de SKU/região; servem para dimensionar o custo de saída do free tier, não para faturamento.

---

## 2. Premissas de uso

| Item | Premissa |
|---|---|
| **Horas de VM** | 2 VMs ligadas 24/7 (~730 h/mês cada) — dentro do Always Free. |
| **Tráfego (egress)** | Projeto acadêmico/demo: estimado **< 50 GB/mês** de saída (bem abaixo dos 10 TB gratuitos). |
| **Armazenamento** | Boot volumes 2× ~47 GB + volumes de dados/SeaweedFS e banco somando **< 200 GB** no total. |
| **Object Storage** | Backups de banco + tfstate + assets: **< 20 GB** (limite free). |
| **Sessões/usuários** | Carga leve de demonstração e avaliação — sem pico comercial. |

---

## 3. Justificativa do custo zero

O **Always Free da OCI cobre integralmente a demanda acadêmica**:

- As duas VMs `E2.1.Micro` (AMD, 1 OCPU/1 GB) são **gratuitas e vitalícias** — suficientes para Next.js + FastAPI + PostgreSQL 17 + SeaweedFS com carga de demonstração.
- O limite de **200 GB de block/boot volume** comporta banco, storage e sistema com folga.
- Os **10 TB de egress mensal** são ordens de grandeza acima do tráfego esperado de uma turma avaliando o app.
- Não há necessidade de serviços pagos (banco gerenciado, load balancer, OKE), que seriam os únicos itens com custo real.

Ou seja: **custo zero não é uma coincidência de "trial", é a capacidade permanente do tier gratuita aplicada a um workload pequeno.**

---

## 4. Alternativas consideradas

| Alternativa | Vantagens | Trade-offs | Veredito |
|---|---|---|---|
| **AWS Free Tier (t2.micro/t3.micro)** | Ecossistema maduro, familiaridade ampla | Free tier **expira em 12 meses**; depois ~US$ 8–10/mês por instância; egress pago | ❌ descartado (não é vitalício) |
| **VPS único barato (Hetzner/DigitalOcean ~US$ 4–6)** | Simples, previsível, IP fixo | Custo mensal **permanente**; banco e app no mesmo host sem isolamento de rede | ❌ descartado (custo > 0) |
| **GCP Free Tier (e2-micro)** | Instância gratuita vitalícia (1 por região) | 1 VM apenas — não atende o requisito de isolar o banco em VM exclusiva | ❌ descartado (limite de 1 VM) |
| **Azure (créditos estudantis)** | Créditos temporários generosos | Créditos **expiram**; sem caminho zero-custo contínuo | ❌ descartado |
| **OCI Always Free (escolhido)** | Vitalício, 2 VMs, isolamento de rede completo, sem cartão | Lock-in OCI; shapes free têm 1 GB (ajuste de imagem leve) | ✅ adotado |

---

## 5. O que permanece gerando cobrança e como encerrar

**Idealmente: nada.** O desenho mantém todos os recursos dentro dos limites gratuitos.

**Riscos que podem gerar cobrança (e mitigação):**

| Risco | Mitigação |
|---|---|
| Criar shape pago (E4/E5/E6 ou A1 além de 4 OCPU/24 GB) | Fixar shapes `E2.1.Micro`/`A1.Flex` no Terraform (validação já existente). |
| Estourar 200 GB de block volume | Alertar via métricas de disco; somar boot+block ≤ 200 GB. |
| Exceder 20 GB de Object Storage | Rotação de backups; retenção limitada de dumps. |
| Exceder 10 TB de egress | Irrelevante para a carga acadêmica; monitorar por garantia. |
| Criar OKE (nós cobrados) | Proibido no free tier — manter Docker Compose. |

**Como encerrar (se precisar desligar o ambiente):**

1. `terraform destroy` (remove VMs, subnets, security lists, gateways e IPs reservados).
2. Esvaziar e remover buckets de Object Storage (backups e tfstate) para zerar armazenamento.
3. Remover imagens no container registry, se houver.
4. Confirmar no console OCI que não restam recursos faturados (Compartments vazios).

> Ações de exclusão (`terraform destroy`, remoção de buckets) exigem aprovação explícita antes de executar.
