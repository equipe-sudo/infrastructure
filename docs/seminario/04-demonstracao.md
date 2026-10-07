# Demonstração prática — Redes e Isolamento (VPC/Subnets/Security Groups/NAT)

> Roteiro da demonstração da **Pergunta 5**, apresentada por **João**.
> Objetivo: provar na prática, usando a infraestrutura real da equipe na OCI, que rede bem
> configurada = **só o necessário fica acessível**. Depois, traduzir os conceitos para a AWS.

---

## Contexto (o que já temos rodando)

| Recurso | Valor |
|---|---|
| Domínio público | `https://equipe-sudo.kolpzs.com` |
| IP público da VM | `129.148.50.233` (verificar antes!) |
| Entrada de tráfego | Apenas via Cloudflare Tunnel (conexão outbound) |
| Porta aberta na VM | **SSH 22** (única inbound liberada no Security List) |
| Back-end (Express) | porta interna `5000` — **bloqueado** da internet |
| Banco (MongoDB) | porta interna `27017` — **bloqueado** da internet |
| Front-end (Nginx) | porta interna `80` — acessível só via tunnel |

---

## Pré-flight (fazer ANTES de apresentar, ~5 min)

Rode estes testes no seu notebook para confirmar que a demo vai funcionar no palco:

```bash
# 1. Confirmar que o site está no ar (esperado: HTTP/2 200)
curl -sI https://equipe-sudo.kolpzs.com | head -n 1

# 2. Confirmar que o back-end direto está BLOQUEADO (esperado: timeout/expira)
curl -m 5 -sS http://129.148.50.233:5000/health ; echo "exit=$?"

# 3. Confirmar que o banco direto está BLOQUEADO (esperado: timeout/expira)
curl -m 5 -sS http://129.148.50.233:27017 ; echo "exit=$?"
```

- Se o item 1 retornar `200` e os itens 2 e 3 **falharem/travarem**, a demo está pronta.
- Se algum IP mudou (VM recriada), descubra o novo IP:

```bash
oci --profile KOLPZS compute instance list --compartment-id <OCID> \
  --query 'data[].{name:"display-name", ip:"public-ip"}' --output table
# ou, mais simples, pelo Terraform:
terraform output vm_public_ip
```

---

## Automação (3 opções)

Para não precisar digitar na frente da turma, a demo está automatizada de três formas:

### Opção 1 — Script interativo (recomendado para o palco)

`scripts/demo-rede.sh` roda tudo sozinho, pausando a cada passo (você aperta Enter e narra).

```bash
# do diretório raiz do repo
./scripts/demo-rede.sh
```

- Passo a passo: site → back-end bloqueado → banco bloqueado → SSH aberto → resumo.
- Controle o ritmo: aperte `Enter` para avançar (ou rode `AUTO=1 SLEEP=3` para avançar sozinho).
- Sobrescrever valores se o IP mudar: `DOMAIN=... VM_IP=... ./scripts/demo-rede.sh`.

### Opção 2 — Workflow de evidência (plano B / prova reprodutível)

`.github/workflows/demo-rede.yml` executa as mesmas checagens no GitHub Actions (disparo
manual pelo botão "Run workflow"). O log da execução é a **prova** de isolamento — útil se a
internet do local da apresentação cair.

- Vantagem: roda em ambiente controlado, gera um link público da execução.
- Como usar: aba **Actions → Demo — Isolamento de rede → Run workflow**.

### Opção 3 — Terraform (mostrar que a infra é código)

A regra que **faz o isolamento acontecer** está em `terraform/vcn.tf` (Security List: só SSH 22
ingress + egress total). Você pode exibir isso de forma segura:

```bash
cd terraform
terraform plan    # SEGURO: mostra "no changes" e prova que a infra é declarativa
```

- **Recomendado:** mostrar `terraform plan` (rápido, sem efeito colateral) + abrir o `vcn.tf`.
- **Evitar** `terraform apply` ao vivo: é lento, depende de credenciais OCI e, se houver
  drift no estado, pode alterar/re criar recursos e derrubar a aplicação que está rodando.

---

## Roteiro da apresentação (~3 min)

### Passo 1 — Mostrar a rede isolada (30s)

Abra o console da OCI (ou um screenshot) e aponte:

- **VCN** `vcn-equipe-sudo-dev` → é o nosso "VPC".
- **Subnet** `sn-equipe-sudo-public-dev` → é a nossa "subnet".
- **Internet Gateway** `igw-equipe-sudo-dev` → a porta de saída para a internet.

> Fala: "Na AWS isso se chama VPC e Subnet. Na OCI, que é onde rodamos, se chama VCN e
> subnet. Mesma ideia: uma rede privada isolada dentro da nuvem."

### Passo 2 — Provar que o site funciona (30s)

```bash
curl -sI https://equipe-sudo.kolpzs.com
```

**Saída esperada (resumo):**
```
HTTP/2 200
content-type: text/html
...
```

> Fala: "O site está no ar e acessível pela internet. Mas reparem: ele **não** entra por uma
> porta aberta na VM. Ele entra pelo **Cloudflare Tunnel**, uma conexão de **saída**. Isso já é
> isolamento: a VM não precisa abrir porta 80/443 para o mundo."

### Passo 3 — Provar que o back-end está BLOQUEADO (40s)

```bash
curl -m 5 -v http://129.148.50.233:5000/health 2>&1 | tail -n 3
```

**Saída esperada:** o comando trava e termina com `Operation timed out` (ou "connection timed out").

> Fala: "O back-end roda na porta 5000 dentro da VM, mas **não** está acessível pela internet.
> O Security List bloqueia tudo que não seja SSH. Isso é exatamente o que um **Security Group**
> faz na AWS: liberar só o necessário."

### Passo 4 — Provar que o banco está BLOQUEADO (30s)

```bash
curl -m 5 -v http://129.148.50.233:27017 2>&1 | tail -n 3
```

**Saída esperada:** `Operation timed out` novamente.

> Fala: "Mesma coisa com o MongoDB, na porta 27017. Banco de dados nunca deve ser exposto
> à internet. Na AWS, o banco ficaria numa **subnet privada** com um Security Group liberando
> acesso só para a aplicação."

### Passo 5 — Mostrar O PORQUÊ: o firewall (40s)

No console OCI, abra o **Security List** da subnet e mostre as regras de entrada:

| Direção | Protocolo/Porta | Origem | Situação |
|---|---|---|---|
| Ingress | TCP **22** (SSH) | 0.0.0.0/0 | **Permitido** |
| Ingress | TCP 80/443/5000/27017 | — | **Bloqueado** (não há regra) |
| Egress | ALL | 0.0.0.0/0 | Permitido (necessário p/ tunnel + updates) |

> Fala: "A regra é simples: **tudo bloqueado, exceto o necessário**. É a mesma filosofia do
> Security Group da AWS. Só entra SSH (para operação); o tráfego web entra pelo tunnel."

### Passo 6 — Traduzir para AWS (30s)

Mostre a tabela de equivalência:

| OCI (demonstrado ao vivo) | AWS (equivalente) |
|---|---|
| VCN + Subnet | **VPC + Subnets** |
| Security List (só SSH 22 aberto) | **Security Group / NACL** |
| Back-end 5000 e banco 27017 bloqueados | **SG liberando só o necessário** |
| Cloudflare Tunnel (saída) | **NAT Gateway / IGW controlado** |

> Fala final: "Rede bem configurada não é sobre abrir tudo — é sobre **liberar só o que
> precisa**. O que acabamos de ver na OCI é o mesmo princípio de VPC, Subnets e Security
> Groups na AWS."

---

## Plano B (se a rede falhar na hora)

Nunca dependa 100% de conexão ao vivo. Prepare **screenshots** com antecedência:

1. **Console OCI — VCN** mostrando `vcn-equipe-sudo-dev` e a subnet.
2. **Console OCI — Security List** mostrando só SSH 22 liberado.
3. **Terminal com os curls** já executados: site `200 OK`, back-end `timeout`, banco `timeout`.
4. **Diagrama** de arquitetura (do arquivo de resposta).

Se a internet cair, mostre os screenshots e conte exatamente o que cada um prova — a narrativa
é a mesma.

---

## Dicas de apresentação

- **Conte a história, não decore comandos:** "aqui está o site, aqui está ele bloqueado, aqui
  está o porquê".
- **Contraste é o que convence:** mostrar `200 OK` ao lado de `timeout` é o argumento visual
  mais forte.
- **Tenha os curls num terminal já aberto** (uma aba por comando) para não digitar na frente da turma.
- **Deixe o timer à vista:** 30s + 30s + 40s + 30s + 40s + 30s = ~3 min.
