# Entrega Final 02 — Diagrama técnico + Observabilidade

> **Atividade:** Evolução da Entrega 01 — diagrama fiel à infraestrutura em funcionamento e
> observabilidade da aplicação com, no mínimo, quatro painéis fundamentados.
> **Prazo:** dia 18.

---

## 1. Identificação

| Item | Informação |
|---|---|
| Grupo | **Equipe SUDO** |
| Integrantes | João Pedro (Scrum Master / DevOps), Allan Marcos (dev), Josiane Cristina (dev), Fernanda Chini (P.O.), Thiago Andre (apoio) |
| Aplicação | Todo App (React + Node/Express + MongoDB) fornecida pelo professor |
| Repositório da aplicação | https://github.com/equipe-sudo/aula-uniamerica-infraestrutura-cloud |
| Repositório de infraestrutura | https://github.com/equipe-sudo/infrastructure |
| Provedor de nuvem | Oracle Cloud Infrastructure (OCI) — região `sa-saopaulo-1` (Always Free) |
| Domínio da aplicação | https://equipe-sudo.kolpzs.com (protegido por Cloudflare Access) |
| Domínio do Grafana | https://grafana-equipe-sudo.kolpzs.com (protegido por Cloudflare Access) |
| Board do time | https://trello.com/b/GrZTNYh8/equipe-sudo |

---

## 2. O que mudou desde a Entrega 01

A aplicação e o domínio são os mesmos. As mudanças são **adaptações para a observabilidade**
e **correções necessárias** encontradas ao evoluir a infraestrutura:

| # | Mudança | Motivo |
|---|---|---|
| 1 | Nova VM dedicada à observabilidade (`vm-equipe-sudo-obs-dev`) em subnet própria (`10.0.2.0/24`) | Não sobrecarregar a VM da aplicação (1 GB RAM) e isolar a stack |
| 2 | Security List `sl-equipe-sudo-obs-dev` que aceita **apenas** OTLP (4317/4318) da subnet da aplicação | Isolamento real entre as VMs |
| 3 | Instrumentação do backend com **OpenTelemetry** (métricas + logs) e logs em JSON | Gerar dados reais para os painéis |
| 4 | Túnel Cloudflare dedicado (`grafana-equipe-sudo.kolpzs.com`) | Acesso remoto/autenticado ao Grafana sem expor portas |
| 5 | Correção: `variables.tf` só aceitava `VM.Standard.A1.Flex`, mas a VM real é `E2.1.Micro` — o `terraform plan` falhava | Infra precisava voltar a ser aplicável |
| 6 | Correção: recursos legados de **OCIR** (`oci_artifacts_container_repository`) removidos do Terraform | A tenancy é Free Tier e a API retorna `403 FREE_TIER_NOT_SUPPORTED`, quebrando o refresh |
| 7 | Correção: o `terraform plan` tentava alterar `shape_config` (1→2 OCPU / 1→12 GB) e trocar a imagem de boot da VM em execução | Risco de recriar a VM e **perder o volume do MongoDB** |
| 8 | Correção: workflows do repo da aplicação buildavam `linux/arm64`, incompatível com a VM AMD | As imagens publicadas precisam ser `linux/amd64` |

O diagrama foi atualizado para representar o ambiente final (seção 4).

---

## 3. Ferramentas e serviços utilizados — e por quê

| Componente | Papel | Justificativa |
|---|---|---|
| **OpenTelemetry Collector (contrib) 0.160.0** | Recebe telemetria (OTLP) e roteia para métricas e logs | Padrão aberto, vendor-neutral; evita instrumentar o app contra um backend específico. Também executa a verificação sintética de disponibilidade (`http_check`), evitando um container extra em uma VM de 1 GB |
| **Prometheus 2.54.1** | Armazenamento de métricas (15 dias) | Recebe `remote_write` do Collector; PromQL é a linguagem de consulta usada nos painéis |
| **Loki 3.1.1** | Armazenamento de logs (30 dias) | Recebe logs por OTLP; LogQL permite filtrar pelos campos JSON dos logs estruturados |
| **Grafana 11.2.0** | Visualização (dashboards) e controle de acesso | Um único ponto de consulta para métricas e logs; datasources e dashboards versionados como código (provisioning) |
| **Cloudflare Tunnel** | Entrada HTTPS e proxy reverso | Publica o domínio sem abrir portas na VM; TLS termina na edge |
| **Cloudflare Access** | Controle de acesso | Somente e-mails autorizados consultam a aplicação e o Grafana |
| **OCI Compute (Always Free)** | Execução dos containers | 2 instâncias `VM.Standard.E2.1.Micro` estão no Free Tier — **custo zero** |
| **Docker Compose** | Orquestração | Simples, reproduzível e suficiente para o escopo |

**Por que o OpenTelemetry:** a aplicação gera métricas e logs via SDK OpenTelemetry e os envia
por OTLP ao Collector. Isso mantém o código desacoplado da ferramenta: se o backend de
observabilidade mudar, apenas a configuração do Collector muda.

---

## 4. Arquitetura implementada

Diagrama: **[`diagrama-entrega-final-02.png`](diagrama-entrega-final-02.png)**
Fonte editável: **[`diagrama.mmd`](diagrama.mmd)** (Mermaid — abre em qualquer editor de texto,
VS Code com extensão Mermaid ou <https://mermaid.live>) e **`diagrama-entrega-final-02.svg`**.

### 4.1 Legenda do diagrama

| Estilo | Significado |
|---|---|
| Linha cheia azul | Fluxo da aplicação (requisições do usuário) |
| Linha tracejada roxa | Fluxo de observabilidade (telemetria) |
| Linha pontilhada vermelha com ❌ | Acesso bloqueado (e onde ocorre o bloqueio) |
| Linha pontilhada cinza | Resolução DNS |

### 4.2 Elementos representados (nomes reais dos recursos)

| Elemento | Recurso / valor real |
|---|---|
| Provedor | OCI — `sa-saopaulo-1` |
| VCN | `vcn-equipe-sudo-dev` — `10.0.0.0/16` |
| Subnet da aplicação | `sn-equipe-sudo-public-dev` — `10.0.1.0/24` |
| Subnet da observabilidade | `sn-equipe-sudo-obs-dev` — `10.0.2.0/24` |
| Security List da observabilidade | `sl-equipe-sudo-obs-dev` |
| Internet Gateway | `igw-equipe-sudo-dev` (rota `0.0.0.0/0`) |
| VM da aplicação | `vm-equipe-sudo-dev` — `VM.Standard.E2.1.Micro`, IP privado `10.0.1.32` |
| VM da observabilidade | `vm-equipe-sudo-obs-dev` — `VM.Standard.E2.1.Micro` |
| Domínio do front-end/API | `equipe-sudo.kolpzs.com` |
| Domínio do Grafana | `grafana-equipe-sudo.kolpzs.com` |
| Containers da aplicação | `todo-tunnel`, `todo-frontend`, `todo-backend`, `todo-mongo` (rede `todo-app-net`) |
| Containers da observabilidade | `obs-tunnel`, `obs-otel-collector`, `obs-prometheus`, `obs-loki`, `obs-grafana` (rede `obs-net`) |
| Origem das chamadas à API | **Navegador do usuário** → `/api/*` no mesmo domínio (não há chamada server-side do front-end) |

### 4.3 Portas, protocolos e terminação TLS

| Caminho | Protocolo / porta | Terminação TLS |
|---|---|---|
| Usuário → Cloudflare | HTTPS 443 | **Cloudflare edge** |
| Cloudflare → `cloudflared` | QUIC (conexão de **saída** da VM) | Cloudflare |
| `cloudflared` → `nginx` | HTTP 80 (rede Docker) | não aplicável (rede interna) |
| `nginx` → backend | HTTP 5000 (rede Docker) | não aplicável |
| backend → MongoDB | TCP 27017 (rede Docker) | não aplicável |
| backend → Collector da observabilidade | OTLP/HTTP **4318** (entre subnets) | não aplicável (rede privada OCI) |
| Grafana → usuário | HTTPS 443 | Cloudflare edge |
| Administração | SSH 22 nas duas VMs | — |

> **HTTPS termina na edge do Cloudflare.** Entre a edge e a VM os dados trafegam pelo túnel
> (QUIC criptografado). Dentro da VCN o tráfego é privado e não usa TLS.

### 4.4 Comunicações permitidas e bloqueadas

**Permitidas**

| Origem | Destino | Porta | Controle |
|---|---|---|---|
| Usuário | Cloudflare | 443 | DNS + Cloudflare Access |
| Cloudflare Tunnel | front-end | 80 (interna) | Configuração do túnel |
| front-end | back-end | 5000 (interna) | `proxy_pass` do nginx |
| back-end | MongoDB | 27017 (interna) | Rede Docker `todo-app-net` |
| back-end | Collector | 4318 | **Security List `sl-equipe-sudo-obs-dev`: aceita `10.0.1.0/24`** |
| Operador | VM da aplicação / da observabilidade | 22 | Security List |

**Bloqueadas**

| Origem | Destino | Porta | Onde ocorre o bloqueio |
|---|---|---|---|
| Internet | front-end / back-end / MongoDB pelo IP | 80 / 5000 / 27017 | Portas não publicadas no host + Security List |
| Internet | Grafana / Prometheus / Loki pelo IP | 3000 / 9090 / 3100 | Publicadas apenas em `127.0.0.1` + Security List |
| **VM da aplicação → Grafana / Prometheus / Loki** | 3000 / 9090 / 3100 | Security List `sl-equipe-sudo-obs-dev` (não aceita essas portas) |
| **VM da observabilidade → aplicação** | qualquer | A observabilidade nunca inicia conexão para a aplicação |
| Internet | back-end diretamente | 5000 | O back-end só é alcançável via `/api/*` pelo nginx |

> **Isolamento:** o único tráfego entre as duas VMs é a **telemetria OTLP** partindo da aplicação
> para o Collector. Isso está codificado no Terraform (`oci_core_security_list.obs`), não apenas
> na documentação.

### 4.5 Detalhe administrado pelo provedor (não visível)

A distribuição de tráfego da edge do Cloudflare (anycast), o balanceamento interno do túnel e a
infraestrutura do Cloudflare Access são gerenciados pelo provedor e **não são representados como
recursos próprios** no diagrama. O diagrama mostra apenas o que configuramos: hostnames, o túnel
e a policy de acesso.

---

## 5. Fluxo dos dados de observabilidade

Caminho completo, conforme exigido (componente → coleta → armazenamento → painel):

| Sinal | Gera o dado | Coleta / encaminhamento | Armazenamento / consulta | Painel |
|---|---|---|---|---|
| Requisições, latência, erros, operações de negócio e de banco | **Backend** (SDK OpenTelemetry em `instrumentation.js` + `index.js`) | OTLP/HTTP → `obs-otel-collector:4318` → `remote_write` | **Prometheus** (15 dias) — PromQL | Painéis **3, 4, 5, 6, 7** |
| Logs de aplicação | **Backend** (`logger.js`, JSON em stdout e LogRecord OTLP) | OTLP/HTTP → `obs-otel-collector:4318` → OTLP para Loki | **Loki** (30 dias) — LogQL | Painel **8** |
| Disponibilidade pelo domínio | **OTel Collector** (receiver `http_check`, a cada 30 s) | interno ao Collector → `remote_write` | **Prometheus** | Painéis **1 e 2** |

**Serviço gerenciado que acumula funções:** o **OTel Collector** reúne coleta, transformação
(processors `memory_limiter`, `batch`, `resource`) e **duas** verificações ativas de
disponibilidade. Ele não armazena — armazenamento é do Prometheus/Loki.
O **Grafana** reúne consulta e visualização.

```
backend (OTel SDK) ──OTLP 4318──► otel-collector ──remote_write──► prometheus ──┐
                                        │                                        ├──► grafana ──HTTPS──► operador
                                        └──OTLP /otlp/v1/logs──► loki ───────────┘
otel-collector (http_check 30s) ──► prometheus
```

---

## 6. Instrumentação da aplicação (adaptações da Entrega 02)

Os logs existentes **não eram suficientes** (apenas `console.log`/`console.error` em texto livre,
sem coleta). Foram adicionadas adaptações no back-end:

| Arquivo (repo da aplicação) | O que faz |
|---|---|
| `backend/instrumentation.js` | Inicializa o SDK OpenTelemetry (métricas e logs via OTLP). Só ativa se `OTEL_EXPORTER_OTLP_ENDPOINT` existir |
| `backend/logger.js` | Logger estruturado JSON: escreve no stdout **e** emite `LogRecord` OTLP |
| `backend/index.js` | Instrumentação HTTP (métricas por rota/status + log de acesso), contadores de negócio, wrapper `dbCall` que mede as operações no MongoDB e os endpoints `/health` e `/health/ready` |
| `backend/Dockerfile` | Carrega a instrumentação com `node --require ./instrumentation.js` e define `HEALTHCHECK` |

### 6.1 Formato dos logs (JSON, campos consistentes)

Campos fixos e o motivo de cada um:

| Campo | Exemplo | Para que serve |
|---|---|---|
| `ts` | `2026-09-15T15:11:31.502Z` | Data/hora em **UTC** (ISO-8601) |
| `level` | `error` / `warn` / `info` | Nível do registro |
| `service` | `equipe-sudo-backend` | Serviço de origem |
| `environment` | `dev` | Ambiente |
| `event` | `todos.create.failed` | Nome do evento (consistente, permite agrupar) |
| `request_id` | `2482c5e3-...` | Correlação entre todos os registros da mesma requisição |
| `method` / `route` / `path` | `POST` `/todos` `/todos` | Contexto HTTP |
| `status_code` | `400` | Resultado da operação |
| `duration_ms` | `12.4` | Duração **em milissegundos** |
| `error_type` / `error_message` | `MongooseError` / `...` | Diagnóstico da falha |

**Exemplo real de registro** (coletado no Loki durante a validação):

```json
{"ts":"2026-09-15T15:11:31.502Z","level":"warn","service":"equipe-sudo-backend","environment":"dev","event":"todos.create.invalid","request_id":"2482c5e3-1598-42d1-a0c6-53d325adc2bc","reason":"missing_text"}
```

**Relação com a consulta de um painel** — este registro é exatamente o que o **painel 8** exibe:

```logql
{service_name="equipe-sudo-backend"} | json | level=~`error|warn`
```

> **Não são registrados** senhas, tokens, credenciais, strings de conexão ou dados pessoais.
> O `MONGO_URI` **não** é logado; apenas o nome do banco.

### 6.2 Métricas emitidas pelo back-end

| Métrica (OTel) | Tipo | Labels | Painel |
|---|---|---|---|
| `app_http_requests_total` | contador | `http_route`, `http_request_method`, `http_response_status_code` | 4, 5 |
| `app_http_request_duration_seconds` | histograma | idem | 3 |
| `app_todos_operations_total` | contador | `operation`, `outcome` | 5 |
| `app_db_operations_total` | contador | `operation`, `outcome` | 7 |
| `app_db_operation_duration_seconds` | histograma | `operation`, `outcome` | 6 |

### 6.3 Onde os registros são gerados, coletados, armazenados e consultados

| Pergunta | Resposta |
|---|---|
| Onde são gerados? | No container `todo-backend`, pelo `logger.js` (stdout) e pelo SDK OpenTelemetry (OTLP) |
| Como são coletados? | O SDK envia por OTLP/HTTP para o `obs-otel-collector` (porta 4318) |
| Onde ficam armazenados? | **Loki** (volume `obs-loki-data`) — 30 dias de retenção |
| Como são consultados? | LogQL no Grafana (data source Loki) ou na aba *Explore* |
| Retenção | Logs: 30 dias (Loki `retention_period: 720h`). Métricas: 15 dias (Prometheus) |
| Também no console? | Sim — as mesmas linhas JSON aparecem em `docker logs todo-backend` |

---

## 7. Painéis — fundamentação completa

Dashboard: **`observability/grafana/dashboards/entrega-final-02.json`** (provisionado
automaticamente no Grafana; 8 painéis, 6 temas distintos).
Fuso horário: **`browser`** (o dado é armazenado em UTC; o Grafana converte para o fuso de quem
consulta). Atualização automática: **30 s**.

> **Como interpretar períodos sem dados:** *ausência de dados não é o mesmo que ausência de erro.*
> Se uma linha não aparece, significa que **não houve requisição** naquele intervalo (ou a coleta
> estava parada) — nunca que "está tudo certo". Por isso os painéis 1 e 2 usam um **probe ativo**:
> eles produzem um ponto a cada 30 s mesmo sem usuários, e assim distinguem "sem tráfego" de
> "sem coleta". Nos painéis de taxa (4 e 7), séries ausentes significam apenas que não houve
> requisições no período.

### Painel 1 — Disponibilidade: validação de conteúdo pelo domínio

- **Pergunta operacional:** a aplicação responde corretamente **pelo domínio configurado**?
- **Motivo da escolha:** é o risco mais crítico e a pergunta mais direta do negócio. Um erro de
  TLS, de túnel, de nginx ou de backend derruba o acesso do usuário mesmo com todos os containers
  "no ar". Este painel é o semáforo do serviço.
- **Origem dos dados:** receiver `http_check` do **OTel Collector**. A cada 30 s ele faz
  `GET https://equipe-sudo.kolpzs.com/api/health` (espera `{"status":"ok"}`) e
  `GET .../api/health/ready` (espera `{"status":"ready"}`; o readiness consulta o MongoDB).
  Gera `httpcheck_validation_passed` / `httpcheck_validation_failed` / `httpcheck_error`, enviados
  por `remote_write` ao Prometheus.
- **Consulta e cálculo:**
  ```promql
  100 * (sum(increase(httpcheck_validation_passed[15m])) or vector(0))
      / clamp_min(
          (sum(increase(httpcheck_validation_passed[15m])) or vector(0))
        + (sum(increase(httpcheck_validation_failed[15m])) or vector(0)), 0.000001)
  ```
  **Numerador:** verificações que passaram na validação de conteúdo. **Denominador:** todas as
  verificações (passou + falhou). Unidade: **%**. O `clamp_min` evita divisão por zero e o
  `or vector(0)` garante que o painel mostre **0 %** em vez de "sem dados" quando nada passou.
- **Recorte temporal:** últimos 15 min; agregação `increase[15m]`; atualização a cada 30 s; UTC→local.
- **Forma de visualização:** `stat` com cor de fundo — leitura imediata por quem está de plantão.
- **Interpretação:** **100 %** = a aplicação respondeu o conteúdo esperado em todas as
  verificações. **0 %** = o domínio respondeu algo que não é a aplicação (página de erro, login do
  Access) ou não respondeu. Valores intermediários = indisponibilidade intermitente.
- **Critérios de atenção:** `< 99 %` (amarelo) merece investigação; `< 95 %` (vermelho) é
  incidente. O critério parte do princípio de que o serviço deve ficar disponível; o limite de 99 %
  tolera uma falha isolada em ~150 verificações por hora.
- **Ação decorrente:** abrir o painel 2 para localizar a janela de falha, verificar o painel 8
  (logs de erro) e o estado dos containers (`docker compose ps`). Se a falha for de conexão,
  checar o túnel Cloudflare; se for de conteúdo, checar o back-end/MongoDB.
- **Validação e limitações:** validado localmente subindo a stack e confirmando que o probe
  **falha** corretamente quando o conteúdo não é a aplicação (no ambiente real, o domínio está
  atrás do **Cloudflare Access** e o probe recebe a página de login → `validation_failed`, o que é o
  comportamento esperado). **Ação necessária:** criar uma exceção (*bypass*) no Cloudflare Access
  para `/api/health` e `/api/health/ready` (seção 9) para que o check seja ponta a ponta e o painel
  marque 100 %. **Limitação:** o check prova que **a rota de health** responde pelo domínio; ele não
  exercita as rotas de negócio (isso é coberto pelos painéis 3–6).

### Painel 2 — Disponibilidade: linha do tempo das verificações

- **Pergunta operacional:** **quando** a aplicação ficou indisponível e por quanto tempo?
- **Motivo da escolha:** o painel 1 diz *quanto*, mas não *quando*. Para responder ao usuário ou
  abrir um incidente é preciso a janela exata.
- **Origem dos dados:** mesma origem do painel 1 (`http_check`), agora em contadores separados.
- **Consulta e cálculo:**
  ```promql
  increase(httpcheck_validation_passed[5m])   # sucesso   {{http_url}}
  increase(httpcheck_validation_failed[5m])   # falha     {{http_url}}
  increase(httpcheck_error[5m])               # erro de conexão
  ```
  Contagem de ocorrências por intervalo de 5 min (não é taxa — é quantidade).
- **Recorte temporal:** janela padrão de 6 h; barras de 5 min; atualização 30 s.
- **Forma de visualização:** `timeseries` em **barras empilhadas** verdes (sucesso) / vermelhas
  (falha) / laranja (erro). A cor e o empilhamento mostram volume e proporção ao mesmo tempo.
- **Interpretação:** barras verdes contínuas = operação normal. Vermelho/laranja aparecendo =
  janela de indisponibilidade exatamente naquele horário.
- **Critérios de atenção:** **qualquer** barra de falha ou de erro merece investigação; o volume
  define a urgência.
- **Ação decorrente:** cruzar o horário da barra vermelha com logs (painel 8) e com o histórico de
  deploys (workflows do GitHub Actions).
- **Validação e limitações:** validado localmente (as séries de falha aparecem no horário exato do
  teste). **Limitação:** o `http_check` reporta apenas o resultado da última verificação por
  intervalo; rajadas mais curtas que 30 s podem não aparecer.

### Painel 3 — Desempenho: latência por rota (p50 / p95)

- **Pergunta operacional:** quais operações estão demorando mais e em quais períodos?
- **Motivo da escolha:** lentidão é a degradação que o usuário percebe antes do erro. Separar por
  rota aponta **onde** otimizar.
- **Origem dos dados:** histograma `app_http_request_duration_seconds`, emitido pelo back-end
  (middleware HTTP em `index.js`), labels `http_route` e `http_response_status_code`.
- **Consulta e cálculo:**
  ```promql
  histogram_quantile(0.95, sum by (le, http_route) (rate(app_http_request_duration_seconds_bucket{service_name="equipe-sudo-backend"}[5m])))
  histogram_quantile(0.50, sum by (le, http_route) (rate(app_http_request_duration_seconds_bucket{service_name="equipe-sudo-backend"}[5m])))
  ```
  Quantis calculados a partir dos buckets do histograma; unidade **segundos**.
- **Recorte temporal:** 6 h; `rate[5m]`; atualização 30 s.
- **Forma de visualização:** linhas p50 e p95 por rota — a mediana mostra o caso típico e o p95
  mostra a cauda (poucos usuários muito lentos). Barras de erro não serviriam aqui.
- **Interpretação:** as rotas `/todos` (lista) e `/todos/:id` (toggle/delete) devem ficar na casa
  dos **milissegundos**. p95 próximo de p50 = latência estável. p95 muito acima do p50 = cauda
  longa (usuários lentos).
- **Critérios de atenção:** como a aplicação é simples e o banco é local, o limite inicial é
  **p95 > 0,5 s** ou **p95 > 5× o p50**. Esses limites são **hipóteses iniciais** (não há histórico
  suficiente em produção para uma referência definitiva) e devem ser revistos com dados reais.
- **Ação decorrente:** abrir o painel 6 para ver se a lentidão vem do MongoDB; se não vier, olhar
  CPU/memória da VM e volume de requisições (painel 5).
- **Validação e limitações:** validado localmente — os quantis retornaram valores coerentes
  (ex.: p95 de `/todos` ≈ 4,75 s em um teste que incluiu timeouts de conexão; os valores normais
  ficam na casa de milissegundos). **Limitação:** `NaN` aparece para rotas sem amostras na janela —
  é ausência de tráfego, não erro.

### Painel 4 — Erros: taxa de falhas por rota (4xx / 5xx)

- **Pergunta operacional:** quais falhas estão ocorrendo e **qual parcela** das requisições elas
  representam?
- **Motivo da escolha:** separar 4xx (erro do usuário) de 5xx (erro do sistema) evita alarme falso
  e mostra a real saúde do back-end.
- **Origem dos dados:** `app_http_requests_total` com o label `http_response_status_code`.
- **Consulta e cálculo:**
  ```promql
  100 * sum by (http_route) (rate(app_http_requests_total{service_name="equipe-sudo-backend", http_response_status_code=~"5.."}[5m]))
      / clamp_min(sum by (http_route) (rate(app_http_requests_total{service_name="equipe-sudo-backend"}[5m])), 0.000001)
  # idem para "4.."
  ```
  **Numerador:** requisições com status da classe (5xx ou 4xx). **Denominador:** todas as
  requisições da mesma rota. Unidade **%**.
- **Recorte temporal:** 6 h; `rate[5m]`; atualização 30 s.
- **Forma de visualização:** linhas por rota, uma para 4xx e outra para 5xx — mostra tendência e
  permite comparar a proporção entre rotas.
- **Interpretação:** 5xx próximo de 0 % = back-end saudável. 4xx concentrado em `POST /todos`
  (ex.: `400` de campo faltando) é comportamento esperado de validação, não incidente.
- **Critérios de atenção:** **5xx > 0 %** é investigação imediata (falha do servidor). **4xx** só
  preocupa se subir de forma sustentada (pode indicar mudança de contrato ou uso indevido).
- **Ação decorrente:** 5xx → painel 8 (logs) e painel 7 (banco). 4xx crescente → revisar contrato
  da API e a aplicação cliente.
- **Validação e limitações:** validado localmente — um `POST /todos` sem o campo `text` produziu
  **400**, e o painel mostrou **33,3 %** de 4xx na rota `/todos` (1 erro em 3 requisições), exatamente
  o esperado. **Limitação:** rotas que não tiveram erro não aparecem como 0 % — a ausência de linha
  significa 0 % na prática.

### Painel 5 — Uso: requisições e operações de negócio

- **Pergunta operacional:** quais funcionalidades são utilizadas e como o volume varia?
- **Motivo da escolha:** dimensionar a infraestrutura e perceber anomalias de uso (queda súbita =
  possível indisponibilidade no cliente; pico = carga inesperada).
- **Origem dos dados:** `app_http_requests_total` (rotas) e `app_todos_operations_total`
  (operações de negócio `list` / `create` / `toggle` / `delete`).
- **Consulta e cálculo:**
  ```promql
  sum by (http_route) (rate(app_http_requests_total{service_name="equipe-sudo-backend", http_route!~"/health.*"}[5m]))
  sum by (operation) (rate(app_todos_operations_total{service_name="equipe-sudo-backend"}[5m]))
  ```
  Unidade: **requisições por segundo** (média em 5 min). As rotas de health são **excluídas** por
  serem do probe, não do usuário.
- **Recorte temporal:** 6 h; `rate[5m]`; atualização 30 s.
- **Forma de visualização:** linhas separadas por rota e por operação de negócio — permite ver qual
  funcionalidade puxa o volume.
- **Interpretação:** `list` deve dominar (a tela carrega a lista); `create`/`toggle`/`delete`
  aparecem em rajadas conforme o usuário interage. Volume constante no horário comercial é o
  padrão esperado para esta aplicação.
- **Critérios de atenção:** não há limite rígido. O sinal útil é a **variação**: queda a zero fora
  do horário de uso é normal; queda a zero no horário de pico motiva investigação.
- **Ação decorrente:** volume acima do previsto → avaliar recursos da VM (1 GB RAM); volume zerado
  → checar disponibilidade (painel 1).
- **Validação e limitações:** validado localmente (as taxas de `create` e `list` apareceram
  coerentes com o tráfego gerado). **Limitação:** mede apenas o que chega ao back-end; acessos que
  param no nginx (ex.: asset estático servido do cache) não aparecem, exceto pelo probe.

### Painel 6 — Banco de dados: duração das operações MongoDB (p50 / p95)

- **Pergunta operacional:** as operações do back-end com o banco estão funcionando e com qual
  duração?
- **Motivo da escolha:** o banco é o último elo da cadeia; lentidão ou falha nele se propaga para
  todos os painéis. Medir no back-end mostra **a experiência real da aplicação** com o banco.
- **Origem dos dados:** histograma `app_db_operation_duration_seconds`, medido no wrapper `dbCall`
  do back-end, com label `operation` (`find`, `insert`, `save`, `findById`, `findByIdAndDelete`,
  `ping`).
- **Consulta e cálculo:**
  ```promql
  histogram_quantile(0.95, sum by (le, operation) (rate(app_db_operation_duration_seconds_bucket{service_name="equipe-sudo-backend"}[5m])))
  histogram_quantile(0.50, sum by (le, operation) (rate(app_db_operation_duration_seconds_bucket{service_name="equipe-sudo-backend"}[5m])))
  ```
  Unidade **segundos**.
- **Recorte temporal:** 6 h; `rate[5m]`; atualização 30 s.
- **Forma de visualização:** linhas p50/p95 por operação — mostra qual **tipo** de operação é o
  gargalo.
- **Interpretação:** com o MongoDB na rede Docker local, o esperado é **poucos milissegundos**. O
  `ping` do readiness também aparece — ele é o termômetro da conexão.
- **Critérios de atenção:** **p95 > 100 ms** para operações locais é sinal de alerta; valores
  **subindo ao longo do tempo** indicam volume ou índice inadequado.
- **Ação decorrente:** investigar volume (painel 5), índices da coleção `todos` e memória da VM.
- **Validação e limitações:** validado localmente (p95 de `find`/`insert` na casa dos milissegundos
  com o MongoDB saudável). **Limitação:** mede o tempo **visto pelo back-end**; o tempo **interno**
  do MongoDB (ex.: lock, compaction) não é instrumentado — não há exporter do MongoDB nesta versão.

### Painel 7 — Banco de dados: falhas nas operações (%)

- **Pergunta operacional:** qual a proporção de operações de banco que estão falhando?
- **Motivo da escolha:** o painel 6 mostra duração, não sucesso. Uma operação pode falhar
  rapidamente (ex.: conexão recusada) e não aparecer como lentidão. Este painel fecha essa lacuna.
- **Origem dos dados:** contador `app_db_operations_total` com label `outcome`
  (`success` / `failure`), incrementado no wrapper `dbCall` também no caminho de exceção.
- **Consulta e cálculo:**
  ```promql
  100 * (sum(increase(app_db_operations_total{service_name="equipe-sudo-backend", outcome="failure"}[15m])) or vector(0))
      / clamp_min(sum(increase(app_db_operations_total{service_name="equipe-sudo-backend"}[15m])), 0.000001)
  ```
  **Numerador:** operações com falha. **Denominador:** todas as operações. Unidade **%**.
- **Recorte temporal:** últimos 15 min; atualização 30 s.
- **Forma de visualização:** `stat` com cor de fundo — resposta binária e rápida para plantão.
- **Interpretação:** **0 %** = todas as operações concluíram. Qualquer valor acima de 0 % indica
  problema de conexão/consulta com o MongoDB.
- **Critérios de atenção:** verde em 0 %; **laranja ≥ 1 %**; **vermelho ≥ 5 %**. Como o banco é
  local e deveria ser sempre acessível, tolera-se pouco erro.
- **Ação decorrente:** 8 (logs, procurando `error_type`/`error_message`) e estado do container
  `todo-mongo`; verificar o volume `todo-mongo-data` e a memória da VM (o MongoDB pode ser
  encerrado pelo OOM killer em 1 GB).
- **Validação e limitações:** validado localmente (0 % com o MongoDB saudável). **Limitação:** o
  painel mede o que **o back-end** vê; um erro que impeça o back-end de sequer tentar a operação
  não é contado aqui (apareceria no painel 4, como 5xx).

### Painel 8 — Logs: erros e avisos registrados pelo back-end

- **Pergunta operacional:** quais erros o back-end registrou, com qual contexto e em que horário?
- **Motivo da escolha:** métricas dizem *que* algo falhou; os logs dizem *por quê*. É o painel de
  diagnóstico e o que prova a coleta estruturada exigida na atividade.
- **Origem dos dados:** `logger.js` no back-end, que escreve JSON no stdout **e** emite
  `LogRecord` OTLP. O Collector encaminha por OTLP/HTTP para o **Loki**
  (`/otlp/v1/logs`), que armazena com o label de recurso `service_name`.
- **Consulta e cálculo:**
  ```logql
  {service_name="equipe-sudo-backend"} | json | level=~`error|warn`
  ```
  Seleciona o serviço, faz o *parse* do JSON da linha e filtra `level` `error` ou `warn`.
  Não há agregação: mostra as linhas.
- **Recorte temporal:** janela do dashboard (6 h por padrão); atualização 30 s; timestamps em UTC.
- **Forma de visualização:** painel de **logs** com o JSON formatado e o horário de cada linha —
  nenhum gráfico substitui a mensagem de erro.
- **Interpretação:** cada linha traz `ts`, `event`, `request_id`, `route`, `status_code`,
  `error_type` e `error_message`. O `request_id` permite reconstruir uma requisição inteira,
  cruzando os logs de entrada, negócio e banco com o mesmo identificador.
- **Critérios de atenção:** qualquer `level=error` é investigação. `level=warn` recorrente (ex.:
  `todos.create.invalid`) indica uso incorreto da API, não falha do sistema.
- **Ação decorrente:** usar o `request_id` para correlacionar com o horário do erro nos painéis 3,
  4 e 7 e identificar a causa raiz.
- **Validação e limitações:** validado localmente de ponta a ponta — um `POST /todos` inválido gerou
  o evento `todos.create.invalid`, que foi **efetivamente recuperado do Loki** com a consulta acima
  (registro reproduzido na seção 6.1). **Limitação:** os logs do **nginx** (front-end) não são
  coletados nesta versão; apenas os do back-end. Por isso o painel não mostra erros ocorridos antes
  de chegar ao Express.

---

## 8. Segurança e controle de acesso à observabilidade

| Pergunta | Resposta |
|---|---|
| Quem pode consultar os dados? | Somente as pessoas autenticadas na aplicação **Cloudflare Access** (`grafana-equipe-sudo.kolpzs.com`) — a policy atual é por **e-mail autorizado** |
| Qual mecanismo controla esse acesso? | **Cloudflare Access** (autenticação na edge, antes de chegar ao túnel) + login local do Grafana (`admin` / senha em secret). O Grafana tem `allow_sign_up = false` e `auth.anonymous.enabled = false` |
| Como o Grafana é publicado? | Túnel Cloudflare **dedicado** (`obs-tunnel`), separado do túnel da aplicação. A VM da aplicação **não** alcança o Grafana |
| As portas do Grafana/Prometheus/Loki estão expostas? | Não. Estão publicadas apenas em `127.0.0.1` da VM de observabilidade e a Security List não as libera para a internet |
| Como os dados chegam sem expor o Collector? | Somente a porta **4318** é aceita, e **apenas** com origem na subnet `10.0.1.0/24` |
| Há credenciais no repositório? | Não. Senhas e tokens vêm de **GitHub Secrets** e são injetados em um `.env` gerado no runner. O `.env` está no `.gitignore` |

---

## 9. Ações necessárias antes de subir a stack

### 9.1 Cloudflare (manual, uma vez)

1. **Túnel da observabilidade** — criar um túnel dedicado (Zero Trust → Networks → Tunnels) e
   anotar o token. O token vai para o secret `GRAFANA_TUNNEL_TOKEN`.
2. **Public hostname** do túnel: `grafana-equipe-sudo.kolpzs.com` → `HTTP` → `grafana:3000`.
3. **Cloudflare Access**: adicionar uma aplicação (*Self-hosted*) para
   `grafana-equipe-sudo.kolpzs.com` com policy de **e-mail autorizado** (somente o grupo).
4. **Exceção para o probe de disponibilidade** — na aplicação de Access do
   `equipe-sudo.kolpzs.com`, criar uma policy de **`Bypass`** para os caminhos
   `/api/health` e `/api/health/ready`.
   *Por quê:* o check sintético precisa receber a resposta real da aplicação. Sem a exceção, o
   Cloudflare Access devolve a página de login (HTTP 200) e o painel 1 corretamente reporta
   indisponível (validação de conteúdo falha).

### 9.2 GitHub Secrets (repositório `equipe-sudo/infrastructure`)

| Secret | Para que serve |
|---|---|
| `OBS_VM_PUBLIC_IP` | IP público da VM de observabilidade (output `obs_vm_public_ip`) |
| `GRAFANA_ADMIN_PASSWORD` | Senha do usuário `admin` do Grafana |
| `GRAFANA_TUNNEL_TOKEN` | Token do túnel dedicado ao Grafana |
| `PUBLIC_HEALTH_URL` | `https://equipe-sudo.kolpzs.com/api/health` |
| `PUBLIC_READY_URL` | `https://equipe-sudo.kolpzs.com/api/health/ready` |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `http://<obs_vm_private_ip>:4318` (output `otel_exporter_otlp_endpoint`) |

> Já existentes e reaproveitados: `SSH_PRIVATE_KEY`, `VM_PUBLIC_IP`, `CLOUDFLARE_TUNNEL_TOKEN`,
> `GHCR_USERNAME`, `GHCR_TOKEN`, `CI_PAT` e os de OCI.

---

## 10. Runbook de deploy

Ordem exata, para não quebrar o ambiente:

```text
1. MERGE do PR do repositório da aplicação (instrumentação OTel)
        └─ o workflow de build publica a imagem amd64 no GHCR
           (roda automaticamente no push da main ou via workflow_dispatch
            "Build & Push Backend" no repo infrastructure)

2. MERGE do PR do repositório infrastructure

3. TERRAFORM — uma única vez, remover os recursos legados de OCIR do estado
   (sem isso o refresh falha com 403 FREE_TIER_NOT_SUPPORTED):
        cd terraform
        terraform state rm \
          'oci_artifacts_container_repository.repos["backend"]' \
          'oci_artifacts_container_repository.repos["frontend"]'

4. TERRAFORM APPLY
        # IMPORTANTE: o estado do Terraform é LOCAL (backend remoto está comentado).
        # O apply deve ser executado na máquina que possui o terraform.tfstate.
        terraform plan -var-file=terraform.tfvars   # confira: deve ser "3 to add, 0 to change, 0 to destroy"
        terraform apply -var-file=terraform.tfvars
        # anote os outputs: obs_vm_public_ip, obs_vm_private_ip, otel_exporter_otlp_endpoint

5. ANSIBLE na VM de observabilidade (instala Docker + swap)
        ansible-playbook -i inventory.yml playbook-observability.yml

6. CLOUDFLARE (seção 9.1) e GITHUB SECRETS (seção 9.2)

7. DEPLOY DA OBSERVABILIDADE
        GitHub Actions → "Deploy Observability Stack" (workflow_dispatch)

8. DEPLOY DA APLICAÇÃO (com a nova imagem instrumentada)
        GitHub Actions → "Deploy to VM" (workflow_dispatch)

9. VALIDAÇÃO
        curl -s https://equipe-sudo.kolpzs.com/api/health/ready
        abrir https://grafana-equipe-sudo.kolpzs.com e conferir os painéis
```

> ⚠️ **Risco conhecido (importante):** o backend do Terraform está **comentado** (`main.tf`), ou seja,
> o `terraform.tfstate` é **local**. O job `terraform-apply` do workflow `terraform-ci.yml` roda em um
> runner do GitHub **sem esse estado** e, por isso, **não deve ser usado** — ele planejaria recriar
> toda a infraestrutura. Enquanto o backend remoto (OCI Object Storage S3-compatível, já esboçado em
> `main.tf`) não for habilitado, **o apply deve ser feito localmente**. Este PR não habilita o backend
> remoto para não alterar o fluxo do grupo sem validação; recomenda-se habilitá-lo em seguida.
>
> 🛡️ **Trava adicionada:** o job `terraform-apply` agora **aborta** se o estado estiver vazio
> (verificação `terraform state list`), evitando criar recursos por engano e gerar custo.
> Pelo mesmo motivo, o `terraform plan` do CI exibe "N to add" (estado vazio no runner) — não é uma
> regressão.

---

## 11. Testes e evidências

Os cenários abaixo devem ser executados **no ambiente real** e as capturas salvas em
`docs/entrega-final-02/evidencias/`. Cada evidência deve informar **cenário, data/hora, período
selecionado no painel e conclusão**.

| # | Cenário | Painéis | Resultado esperado | Resultado observado |
|---|---|---|---|---|
| E1 | Uso normal pelo domínio: criar, listar, concluir e excluir uma tarefa em `https://equipe-sudo.kolpzs.com` (operação que percorre back-end **e** MongoDB) | 3, 5, 6 | Aparecem requisições nas rotas, `create/toggle/delete` no painel 5 e operações `insert/save/find/findByIdAndDelete` no painel 6 | _a preencher_ |
| E2 | **Volume**: gerar ~50 requisições (ex.: `for i in $(seq 1 50); do curl -s -X POST .../api/todos -d "{\"text\":\"teste $i\"}"; done`) | 4, 5 | As taxas e o volume sobem de forma visível em 5 min | _a preencher_ |
| E3 | **Falha controlada de aplicação**: `POST /api/todos` sem o campo `text` (espera HTTP 400) | 4, 8 | Taxa de 4xx > 0 % em `/todos` **e** o log `todos.create.invalid` aparece no painel 8 | _a preencher_ |
| E4 | **Falha controlada de banco**: parar o MongoDB (`docker compose stop mongo`) e tentar `GET /api/todos` | 6, 7, 8, 1 | Painel 7 > 0 % de falhas; erro no painel 8; `/health/ready` falha e o painel 1 cai | _a preencher_ |
| E5 | **Disponibilidade**: abrir o painel 1 e confirmar `100 %` com o Access bypass aplicado | 1, 2 | 100 % e barras verdes contínuas | _a preencher_ |
| E6 | **Correspondência diagrama ↔ ambiente**: `docker compose ps` nas duas VMs + Security List no console OCI | — | Nomes dos containers, portas e regras iguais aos do diagrama | _a preencher_ |

**Como capturar cada evidência**

```bash
# Estado dos containers (evidência E6)
ssh opc@<VM_APP_IP> "cd /home/opc/slots && docker compose ps"
ssh opc@<OBS_VM_IP> "cd /home/opc/observability && docker compose ps"

# Tráfego normal (E1/E2)
curl -s   https://equipe-sudo.kolpzs.com/api/todos
curl -s -X POST https://equipe-sudo.kolpzs.com/api/todos -H 'Content-Type: application/json' -d '{"text":"evidencia"}'

# Falha de aplicação (E3)
curl -si -X POST https://equipe-sudo.kolpzs.com/api/todos -H 'Content-Type: application/json' -d '{}'

# Falha de banco (E4) — lembre-se de restaurar depois
ssh opc@<VM_APP_IP> "cd /home/opc/slots && docker compose stop mongo && curl -s -o /dev/null -w '%{http_code}\n' http://localhost:5001/todos || true"
```

**Restaurar o ambiente após os testes:** `docker compose start mongo` (ou `up -d`) na VM da
aplicação.

**Evidência do caminho evento → log → painel:** no painel 8, clique em uma linha de erro e copie o
`request_id`; busque o mesmo `request_id` em `docker logs todo-backend` na VM — o mesmo evento
aparece nos dois lugares, provando o caminho *geração → coleta → armazenamento → painel*.

### 11.1 Validações de configuração já executadas (fora do ambiente de produção)

Antes de abrir o PR, a configuração foi validada localmente (a execução real na VM é feita pelo
grupo, após o merge):

| Validação | Comando | Resultado |
|---|---|---|
| Terraform | `terraform validate` / `terraform plan` | Válido; plano **3 to add, 0 to change, 0 to destroy** |
| Compose (app e observabilidade) | `docker compose config -q` | Válidos |
| Config do OTel Collector | `otelcol-contrib validate` | Válido (receiver `http_check`, `validations`, exporters) |
| Config do Prometheus | `promtool check config` | `SUCCESS` |
| Config do Loki | `loki -verify-config` | Válido |
| Dashboard | `python -m json.tool` + API do Grafana | Provisionado, com os 8 painéis |
| Instrumentação do back-end | execução local + collector falso | `/v1/metrics` e `/v1/logs` recebidos |
| Pipeline ponta a ponta (local) | app + collector + Prometheus + Loki + Grafana | Métricas em Prometheus e log recuperado do Loki; **as 8 consultas dos painéis retornaram dados** |

---

## 12. Limitações declaradas (transparência)

1. **Redundância de origem do front-end:** há **um** ponto de origem (nginx na VM da aplicação). A
   redundância existe apenas na **edge do Cloudflare** (anycast). O requisito de redundância de
   pontos de atendimento **não está implementado** nesta entrega; a evolução proposta é publicar o
   front-end no **Cloudflare Pages** (múltiplas origens + failover). O diagrama não desenha réplicas
   que não existem, conforme pede o enunciado.
2. **Logs do nginx não coletados:** apenas os logs do back-end chegam ao Loki. Erros ocorridos
   antes do Express (ex.: 502 do túnel) não aparecem no painel 8.
3. **Sem traces:** o SDK está configurado com `OTEL_TRACES_EXPORTER=none` e não há backend de
   traces (Tempo) para não sobrecarregar a VM de 1 GB. A correlação é feita por `request_id`.
4. **Sem métricas do host e do MongoDB:** não há `node_exporter` nem exporter do MongoDB. O painel 6
   reflete o que o back-end vê, não o interior do MongoDB.
5. **Retenção limitada pela VM:** métricas 15 dias e logs 30 dias, em disco local da VM (sem
   replicação). Se a VM for perdida, os dados de observabilidade são perdidos.
6. **Estado do Terraform é local** (item do runbook) — o apply via CI não deve ser usado enquanto o
   backend remoto não for habilitado.
7. **Detalhes internos do Cloudflare** (balanceamento do túnel, anycast) são administrados pelo
   provedor e não são visíveis nem representados.

---

## 13. Arquivos desta entrega

**Repositório `infrastructure`**

| Caminho | Conteúdo |
|---|---|
| `terraform/variables.tf` | Correção da validação de shape + variáveis da observabilidade |
| `terraform/vcn.tf` | Subnet da observabilidade + Security List (isolamento OTLP) |
| `terraform/compute.tf` | VM da observabilidade + proteção contra recriação da VM em uso |
| `terraform/container-registry.tf` | Remoção do OCIR legado + nota de migração do estado |
| `terraform/outputs.tf` | Outputs da observabilidade e do endpoint OTLP |
| `observability/docker-compose.yml` | Stack Grafana + Prometheus + Loki + Collector + túnel |
| `observability/otel/config.yaml` | Pipelines de métricas/logs e o probe de disponibilidade |
| `observability/prometheus/prometheus.yml` | Prometheus com remote_write receiver |
| `observability/loki/loki-config.yaml` | Loki single-binary com retenção de 30 dias |
| `observability/grafana/` | Provisioning (datasources + dashboards) e o dashboard JSON |
| `docker/docker-compose.yml` | Aplicação com as variáveis de OpenTelemetry |
| `.github/workflows/deploy-observability.yml` | Deploy da stack na VM de observabilidade |
| `.github/workflows/deploy-vm.yml` | Deploy da aplicação com o endpoint OTLP |
| `ansible/playbook-observability.yml` / `inventory.yml` | Preparação da VM de observabilidade |
| `docs/entrega-final-02/` | Este documento, o diagrama e as evidências |

**Repositório `aula-uniamerica-infraestrutura-cloud`**

| Caminho | Conteúdo |
|---|---|
| `backend/instrumentation.js` | SDK OpenTelemetry (métricas e logs OTLP) |
| `backend/logger.js` | Logger estruturado JSON + emissão de LogRecord |
| `backend/index.js` | Instrumentação HTTP, contadores de negócio, `dbCall`, health/readiness |
| `backend/Dockerfile` | Carrega a instrumentação e define healthcheck |
| `.github/workflows/build-*.yml` | Correção da plataforma de build para `linux/amd64` |
