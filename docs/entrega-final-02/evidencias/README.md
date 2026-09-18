# Evidências — Entrega Final 02

> Executado no **ambiente real** em **2026-09-15**, entre 22:40 e 23:15 (UTC).
> Ambiente: `https://equipe-sudo.kolpzs.com` (Cloudflare Pages + OCI) e Grafana em
> `https://grafana-equipe-sudo.kolpzs.com`.
> Fuso dos painéis: `browser` (dados armazenados em UTC).

Este documento reúne os **resultados observados** dos testes controlados. As capturas de tela dos
painéis podem ser geradas a partir dos comandos abaixo (ver "Como reproduzir") — os números aqui
foram extraídos diretamente do Prometheus e do Loki no momento de cada cenário.

---

## Como reproduzir

```bash
# 1) Tráfego de negócio (CRUD + volume + falhas controladas de aplicação)
#    As chamadas usam o Service Token do Access (mesmo caminho do back-end que o
#    navegador percorre via Pages Function).
API="https://api-equipe-sudo.kolpzs.com/api"
H=(-H "CF-Access-Client-Id: <id>" -H "CF-Access-Client-Secret: <secret>" -H "Content-Type: application/json")
curl -s "${H[@]}" $API/todos
curl -s "${H[@]}" -X POST $API/todos -d '{"text":"evidencia"}'
curl -s "${H[@]}" -X PATCH  $API/todos/<id>
curl -s "${H[@]}" -X DELETE $API/todos/<id>
curl -s "${H[@]}" -X POST $API/todos -d '{}'          # 400 (campo obrigatorio)

# 2) Falha controlada de banco
ssh opc@<VM_APP> "cd /home/opc/slots && docker compose stop mongo"
curl -s "${H[@]}" $API/todos                           # 500
curl -s -o /dev/null -w '%{http_code}\n' https://equipe-sudo.kolpzs.com/api/health/ready  # 503
ssh opc@<VM_APP> "cd /home/opc/slots && docker compose start mongo"

# 3) Consultas de validação (na VM de observabilidade)
ssh opc@<VM_OBS> 'curl -s http://127.0.0.1:9090/api/v1/query --data-urlencode "query=<PromQL>"'
```

> **Uso normal pelo navegador:** o fluxo do usuário é idêntico ao das chamadas acima (a Pages
> Function executa exatamente o mesmo caminho até o back-end): abrir
> `https://equipe-sudo.kolpzs.com`, autenticar no Cloudflare Access e usar a lista de tarefas.
> Para as capturas de tela, use o navegador e registre data/hora + período do painel.

---

## Resumo dos cenários

| # | Cenário | Painéis | Esperado | **Observado** |
|---|---|---|---|---|
| E1 | Uso normal pelo domínio (CRUD completo) | 3, 5, 6 | 200/201 nas rotas e operações de negócio/banco registradas | **200, 201, 200, 200, 200**; `create success = 86,9`, `list success = 45,1`, `find = 45,1`, `insert = 87,0` ✅ |
| E2 | Volume: 40 criações + 20 listagens | 4, 5 | Taxas e volume sobem e ficam visíveis | `POST /todos 201 ≈ 86,9` e `GET /todos 200 ≈ 45,1` no intervalo ✅ |
| E3 | Falha controlada de aplicação (`POST /todos` sem `text`) | 4, 8 | 4xx > 0 % e log de aviso no Loki | **5× HTTP 400**; painel 4 `/todos 400`; Loki `todos.create.invalid = 10` ✅ |
| E3b | Falha controlada (id inexistente) | 4, 8 | 404 registrado | **HTTP 404**; `toggle not_found = 1,15` ✅ |
| E4 | Falha controlada de **banco** (MongoDB parado) | 1, 4, 6, 7, 8 | 500 na API, readiness 503, painel 7 > 0 %, log de erro | `/todos → **500**`, `/health/ready → **503**` (liveness `/health` continuou **200**); **painel 7: 0 % → 1,44 %**; Loki `todos.list.failed = 1`; disponibilidade caiu para **66,7 %** ✅ |
| E5 | Disponibilidade pelo domínio | 1, 2 | 100 % com o serviço saudável | **100 %** (janela de 2–3 min); `2xx = 1` e `5xx = 0` frescos nos dois alvos ✅ |
| E6 | Correspondência diagrama ↔ ambiente | — | Nomes/portas/regras iguais aos do diagrama | Containers, Security List e DNS conferem (abaixo) ✅ |

---

## Números capturados (Prometheus / Loki)

### E1/E2 — requisições por rota e status (janela 10 min)

| Rota | Status | Valor (increase) |
|---|---|---|
| `/todos` | 201 | 86,90 |
| `/todos` | 200 | 45,13 |
| `/todos` | 400 | 5,65 |
| `/todos/:id` | 404 | 1,15 |
| `/health` | 200 | 67,69 |
| `/health/ready` | 200 | 27,69 |

### E1 — operações de negócio (10 min)

| Operação | Resultado | Valor |
|---|---|---|
| `create` | success | 86,96 |
| `list` | success | 45,13 |
| `create` | invalid | 5,66 |
| `toggle` | not_found | 1,15 |

### E1/E4 — operações no MongoDB (10 min)

| Operação | Resultado | Valor |
|---|---|---|
| `insert` | success | 87,02 |
| `find` | success | 45,13 |
| `ping` | success | 27,69 |
| `find` | **failure** | **1** (durante o E4) |

### E2 — latência por rota (após o fix dos buckets, janela 3 min)

| Rota | p50 | p95 |
|---|---|---|
| `/health` | 2,62 ms | 4,98 ms |
| `/health/ready` | 6,05 ms | 10,00 ms |
| `/todos` | 8,95 ms | 154,19 ms |

> Antes do fix dos buckets o painel mostrava **p50 = 2,5 s** e **p95 = 4,75 s** para *todas* as
> rotas — o SDK usa limites de bucket em milissegundos por padrão, então todas as amostras (em
> segundos) caíam no primeiro bucket e os quantis ficavam presos no limite. Corrigido com
> `explicitBucketBoundaries` em segundos (ver PR no repositório da aplicação).

### E4 — erro de banco por etapa

| Momento | `GET /api/todos` | `/api/health/ready` | `/api/health` | Painel 7 | Disponibilidade (2 min) |
|---|---|---|---|---|---|
| Antes | 200 | 200 | 200 | **0,0 %** | 100 % |
| MongoDB parado | **500** | **503** | **200** | **1,44 %** | **66,7 %** |
| Após restaurar | 200 | 200 | 200 | 0 % | volta a 100 % |

O `liveness` (`/health`) continuar **200** enquanto o `readiness` (`/health/ready`) vai para
**503** comprova a separação correta entre "processo no ar" e "aplicação pronta para atender".

### E3/E4 — logs estruturados no Loki (LogQL)

```logql
{service_name="equipe-sudo-backend"} | json | level=~`error|warn`
```

| Evento | Ocorrências | Origem |
|---|---|---|
| `todos.create.invalid` | 10 | `POST /todos` sem `text` (HTTP 400) |
| `todos.list.failed` | 1 | MongoDB indisponível (HTTP 500) |
| `todos.toggle.failed` | 1 | id inválido (execução de teste) |

**Exemplo real de registro** (recuperado do Loki):

```json
{"ts":"2026-09-15T15:11:31.502Z","level":"warn","service":"equipe-sudo-backend","environment":"dev","event":"todos.create.invalid","request_id":"2482c5e3-1598-42d1-a0c6-53d325adc2bc","reason":"missing_text"}
```

### Caminho evento → log → painel

1. Um `POST /api/todos` sem o campo `text` **ocorre** na aplicação.
2. O back-end responde **400** e o `logger.js` emite o evento `todos.create.invalid` (JSON no
   stdout **e** `LogRecord` via OTLP).
3. O OTel Collector recebe por OTLP e envia ao **Loki**; o Prometheus recebe o contador
   `app_http_requests_total{http_response_status_code="400"}`.
4. **Painel 8** exibe a linha com o `request_id`; **painel 4** mostra a taxa de 4xx na rota.

> Para a prova ponta a ponta: copie o `request_id` de uma linha no painel 8 e busque o mesmo valor
> em `docker logs todo-backend` na VM — o evento aparece nos dois lugares.

---

## E6 — Correspondência entre o ambiente e o diagrama

**Containers na VM da aplicação** (`vm-equipe-sudo-dev`, `10.0.1.32`):

```
todo-backend   Up (healthy)   ghcr.io/equipe-sudo/equipe-sudo-backend:latest
todo-frontend  Up             ghcr.io/equipe-sudo/equipe-sudo-frontend:latest
todo-mongo     Up (healthy)   mongo:7
todo-tunnel    Up             cloudflare/cloudflared:latest
```

**Containers na VM de observabilidade** (`vm-equipe-sudo-obs-dev`):

```
obs-otel-collector   obs-prometheus   obs-loki   obs-grafana   obs-tunnel
```

**Security List `sl-equipe-sudo-obs-dev`** (isola a observabilidade):

| Direção | Origem | Porta | Descrição |
|---|---|---|---|
| IN | `10.0.1.0/24` | 4317 | OTLP gRPC enviado pela aplicação |
| IN | `10.0.1.0/24` | 4318 | OTLP HTTP enviado pela aplicação |
| IN | `0.0.0.0/0` | 22 | SSH administrativo |
| IN | `10.0.0.0/16` | ICMP | ping / path MTU (intra-VCN) |
| OUT | `0.0.0.0/0` | all | Egress |

> Nenhuma porta de Grafana/Prometheus/Loki é aceita da aplicação — **apenas** a telemetria OTLP,
> exatamente como o diagrama representa.

**DNS na edge** (Cloudflare):

| Nome | Destino |
|---|---|
| `equipe-sudo.kolpzs.com` | `equipe-sudo-frontend.pages.dev` (Cloudflare Pages) |
| `api-equipe-sudo.kolpzs.com` | `<túnel sudo>.cfargotunnel.com` (origem da API, protegida por Access) |
| `grafana-equipe-sudo.kolpzs.com` | `<túnel observabilidade>.cfargotunnel.com` |

---

## Capturas de tela sugeridas

As capturas devem mostrar **data/hora** e o **período selecionado** no canto superior. Sugestão de
arquivos (salvar nesta pasta):

| Arquivo | Conteúdo |
|---|---|
| `E1-painel3-latencia.png` | Painel 3 — latência p50/p95 por rota (esperado: milissegundos) |
| `E1-painel5-uso.png` | Painel 5 — requisições e operações de negócio |
| `E1-painel6-banco.png` | Painel 6 — duração das operações no MongoDB |
| `E2-painel4-volume.png` | Painel 4 — taxa de erro no período do volume |
| `E3-painel4-4xx.png` | Painel 4 — 4xx em `/todos` (falha controlada de aplicação) |
| `E3-painel8-logs.png` | Painel 8 — log `todos.create.invalid` com o `request_id` |
| `E4-painel7-falhas.png` | Painel 7 — falhas de banco (0 % → 1,44 %) |
| `E4-painel1-disponibilidade.png` | Painel 1 — disponibilidade caindo para 66,7 % |
| `E4-painel8-erro-banco.png` | Painel 8 — log `todos.list.failed` |
| `E5-paineis-1-2.png` | Painéis 1 e 2 — 100 % e barras verdes após a recuperação |
| `E6-docker-ps.png` | `docker compose ps` nas duas VMs |
| `E6-security-list.png` | Security List da observabilidade no console OCI |

> **Limitação declarada:** o back-end e o banco continuam em **origem única** (a VM). A redundância
> do front-end é a distribuição da edge (Cloudflare Pages); não há réplica de API/banco nesta
> entrega, e o diagrama não desenha réplicas inexistentes.
