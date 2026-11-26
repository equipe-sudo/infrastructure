# Custos — PM-04 (Smart Construction)

> **Projeto:** PM-04 — "Smart Construction"
> **Provedor:** AWS — Free Tier, região `us-east-1` (variável `aws_region`)
> **Preços de referência:** lista pública AWS (valores estimados em USD/mês, sem imposto, arredondados).

---

## 1. Estimativa mensal por recurso

### 1.1 Cenário Free Tier (real, uso de demo) — **USD 0,00/mês**

| Recurso | Quantidade | Free Tier | Custo/mês |
|---|---|---|---|
| EC2 `app` — `t3.micro` (2 vCPU, 1 GB) | 1 | ✅ (750 h/mês) | **$0,00** |
| EC2 `db` — `t3.micro` (2 vCPU, 1 GB) | 1 | ✅ (750 h/mês) | **$0,00** |
| Elastic IP (`app`) | 1 | ✅ (associado a instância ativa) | **$0,00** |
| EBS root volumes (2× `gp3` ~30 GB) | ~60 GB | ✅ (30 GB free por instância) | **$0,00** |
| S3 (backups, assets) | ≤ 5 GB | ✅ | **$0,00** |
| Rede: VPC, subnets, IGW, NAT via app | conjunto | ✅ | **$0,00** |
| Egress de Internet | ≤ 100 GB/mês | ✅ | **$0,00** |
| **TOTAL** | | | **$0,00 / mês** |

> **Atenção ao uso 24/7.** O Free Tier da AWS concede **750 horas de `t3.micro` por mês** (não "2 instâncias grátis"). Duas instâncias ligadas 24/7 somam **~1.460 h/mês**, ou seja, **a 2ª VM estoura as 750 h**. No cenário de **demo acadêmica** (ambiente ligado sob demanda, não 24/7), o uso fica dentro do Free Tier. Ver §2.

### 1.2 Se rodar 24/7 (referência do excedente)

| Recurso | Premissa | Custo estimado (USD/mês) |
|---|---|---|
| Excedente de horas `t3.micro` | ~730 h/mês além das 750 h gratuitas | ~US$ 7–10 |
| On-demand `t3.micro` | US$ 0,0104/h (us-east-1) | ~US$ 7,60 por instância/mês |
| **TOTAL estimado (24/7, 2 VMs)** | | **~US$ 7–10 / mês** |

> Valores são **referência** (SKU/região variam) e servem para dimensionar o custo caso o ambiente fique ligado ininterruptamente. No modo demo previsto, esse custo **não ocorre**.

---

## 2. Margem de segurança — US$ 100 de crédito AWS

A conta dispõe de **US$ 100 de crédito AWS** (crédito educacional/promocional). Esse montante funciona como colchão para:

- Uso pontual acima do Free Tier (horas de `t3.micro` além das 750 h/mês).
- Egress acima de 100 GB (improvável na carga acadêmica).
- Qualquer SKU faturado por engano antes de ser corrigido.

**Interpretação:** mesmo no pior cenário de 24/7 (~US$ 7–10/mês), os US$ 100 cobririam **mais de 10 meses** de excedente — margem ampla para um semestre letivo.

---

## 3. Premissas de uso

| Item | Premissa |
|---|---|
| **Horas de VM** | Uso de **demo/avaliação**: instâncias ligadas sob demanda, não 24/7. Total mensal **< 750 h** combinadas (dentro do Free Tier). |
| **Tráfego (egress)** | Projeto acadêmico/demo: estimado **< 50 GB/mês** de saída (bem abaixo dos 100 GB gratuitos). |
| **Armazenamento EBS** | Root volumes 2× ~30 GB (`gp3`) — dentro dos 30 GB free por instância. |
| **S3** | Backups de banco + assets: **< 5 GB** (limite free). |
| **Sessões/usuários** | Carga leve de demonstração e avaliação — sem pico comercial. |

---

## 4. Justificativa do custo zero e a decisão OCI→AWS

**Custo zero no modo demo:** o Free Tier da AWS cobre integralmente a demanda acadêmica — 750 h/mês de `t3.micro`, 30 GB de EBS por instância, 5 GB de S3 e 100 GB de egress. Com o ambiente **não-24/7**, os recursos ficam dentro dos limites gratuitos.

**Por que AWS e não OCI (decisão de arquitetura):** a OCI foi descartada **não por custo** (o Always Free é vitalício), mas por dois bloqueios operacionais:

- A região `sa-saopaulo-1` passou a retornar **"Out of host capacity"** nos shapes Always Free — as VMs não subiam.
- A tenancy estava **limitada a 1 região**, sem possibilidade de migrar para outra região com capacidade.

A AWS remove os dois bloqueios (Free Tier em `us-east-1`/`us-east-2` e troca de região por variável), com o custo continuando **zero** para o uso de demo — e com US$ 100 de crédito como margem de segurança.

Ou seja: **custo zero é o resultado do Free Tier aplicado a um workload de demonstração, com margem de crédito para imprevistos — não de um "trial" prestes a expirar.**

---

## 5. Alternativas consideradas

| Alternativa | Vantagens | Trade-offs | Veredito |
|---|---|---|---|
| **OCI Always Free** | Vitalício, 2 VMs, isolamento de rede completo, sem cartão | **"Out of host capacity"** em `sa-saopaulo-1`; tenancy limitada a 1 região — inviável provisionar | ❌ descartado (capacidade/região, não custo) |
| **NAT Gateway gerenciado (AWS)** | Serviço gerenciado, HA nativa | ~US$ 0,045/h (~US$ 32/mês) + taxa por GB — inviabiliza o custo zero | ❌ descartado (custo) → adotado **NAT via EC2 app** |
| **VPS único barato (Hetzner/DigitalOcean ~US$ 4–6)** | Simples, previsível, IP fixo | Custo mensal **permanente**; banco e app no mesmo host sem isolamento de rede | ❌ descartado (custo > 0) |
| **GCP Free Tier (e2-micro)** | Instância gratuita vitalícia (1 por região) | 1 VM apenas — não atende o requisito de isolar o banco em VM exclusiva | ❌ descartado (limite de 1 VM) |
| **AWS Free Tier (adotado)** | `t3.micro` 750 h/mês, S3 5 GB, egress 100 GB, US$ 100 crédito, multi-região | Free Tier expira em 12 meses; 24/7 estoura as 750 h (~US$ 7–10/mês) | ✅ adotado |

---

## 6. O que permanece gerando cobrança e como encerrar

**Idealmente: nada.** O desenho mantém todos os recursos dentro dos limites gratuitos no uso de demo.

**Riscos que podem gerar cobrança (e mitigação):**

| Risco | Mitigação |
|---|---|
| 2ª VM estourar as 750 h/mês (24/7) | Manter uso de demo (ligar sob demanda); desligar instâncias quando não em uso. |
| Shape maior que `t3.micro` | Fixar `instance_type = "t3.micro"` no Terraform (validação de shape). |
| EBS além dos 30 GB free por instância | Alertar via métricas de disco; manter root volumes em `gp3` ~30 GB. |
| Egress além de 100 GB | Irrelevante para a carga acadêmica; monitorar por garantia. |
| NAT Gateway pago criado por engano | Proibido no desenho — o NAT é feito pela EC2 `app` (masquerade). Manter sem `aws_nat_gateway` no Terraform. |
| Elastic IP não associado | EIP dissociado de instância ativa gera cobrança — manter associado à `app`. |

**Como encerrar (se precisar desligar o ambiente):**

1. `terraform destroy` (remove EC2, VPC, subnets, security groups, IGW, ENI e EIP).
2. Esvaziar e remover buckets S3 (backups) para zerar armazenamento.
3. Remover snapshots/AMIs, se houver.
4. Confirmar no console AWS (Cost Explorer / Billing) que não restam recursos faturados.

> Ações de exclusão (`terraform destroy`, remoção de buckets S3) exigem aprovação explícita antes de executar.
