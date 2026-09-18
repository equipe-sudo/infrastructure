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
| 9 | Estado do Terraform migrado para o **OCI Object Storage** (backend nativo `oci`, com locking) | Permitir `terraform apply` no GitHub Actions, sem depender do estado local de uma máquina |
| 10 | Front-end migrado para o **Cloudflare Pages** (SPA na edge) — serverless e distribuído | Atender os requisitos de **serviços serverless** e **redundância do front-end** herdados da Entrega 01 |
| 11 | **Pages Function** em `/api/*` + hostname de origem `api-equipe-sudo.kolpzs.com` protegido por **Access (Service Token)** | O back-end continua na OCI e protegido; a edge passa a ser a entrada do front-end |

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
| Front-end na edge | **Cloudflare Pages** (projeto `equipe-sudo-frontend`) — SPA React em múltiplos PoPs |
| Proxy da API na edge | **Pages Function** `functions/api/[[path]].js` |
| Origem da API (privada ao navegador) | `api-equipe-sudo.kolpzs.com` → túnel `sudo` → `http://frontend:80` |
| Credencial da Function para a origem | **Service Token** do Cloudflare Access (`pages-api-origin`) |
| Containers da observabilidade | `obs-tunnel`, `obs-otel-collector`, `obs-prometheus`, `obs-loki`, `obs-grafana` (rede `obs-net`) |
| Origem das chamadas à API | **Navegador do usuário** → `/api/*` no mesmo domínio (não há chamada server-side do front-end) |

### 4.3 Portas, protocolos e terminação TLS

| Caminho | Protocolo / porta | Terminação TLS |
|---|---|---|
| Usuário → Cloudflare (SPA) | HTTPS 443 | **Cloudflare edge** (Pages) |
| Usuário → Cloudflare (`/api/*`) | HTTPS 443 | **Cloudflare edge** (Pages Function) |
| Pages Function → origem da API | HTTPS 443 + Service Token | **Cloudflare edge** |
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
| Disponibilidade pelo domínio | **OTel Collector** (receiver `http_check`, a cada 30 s) | Collector → `https://equipe-sudo.kolpzs.com/api/health` (**edge/Pages Function**) → origem da API → backend; resultado por `remote_write` | **Prometheus** | Painéis **1 e 2** |

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

### Painel 1 — Disponibilidade: sucesso das verificações pelo domínio

- **Pergunta operacional:** a aplicação está acessível **pelo domínio configurado**?
- **Motivo da escolha:** é o risco mais crítico e a pergunta mais direta do negócio. Um erro de TLS,
  de túnel, de nginx ou de backend derruba o acesso do usuário mesmo com todos os containers "no ar".
  Este painel é o semáforo do serviço.
- **Origem dos dados:** receiver `http_check` do **OTel Collector**. A cada 30 s ele faz
  `GET https://equipe-sudo.kolpzs.com/api/health` (liveness: nginx → backend) e
  `GET .../api/health/ready` (readiness: nginx → backend → MongoDB). Para cada alvo publica
  `httpcheck.status`: uma série por **classe de resposta** (1xx…5xx) valendo **1** quando a resposta
  pertence à classe e **0** caso contrário. Também valida o **conteúdo** (JSON `status: ok` /
  `ready`) e publica `httpcheck.validation.failed` quando o corpo não é o esperado. Tudo chega ao
  Prometheus por `remote_write`.
- **Consulta e cálculo:**
  ```promql
  100 * avg(avg_over_time(httpcheck_status{http_status_class="2xx"}[15m]))
  ```
  Para cada alvo, `avg_over_time` calcula a **fração de verificações da janela que responderam na
  classe 2xx**; o `avg` externo agrega os dois alvos. **Numerador:** amostras com
  `httpcheck_status{http_status_class="2xx"} == 1`. **Denominador:** todas as amostras do período.
  Unidade: **%**.
- **Recorte temporal:** janela de **15 min**; probe a cada 30 s; atualização a cada 30 s; UTC →
  convertido para o fuso do navegador.
- **Forma de visualização:** `stat` com cor de fundo — leitura imediata por quem está de plantão.
- **Interpretação:** **100 %** = todas as verificações da janela responderam 2xx. Valores menores
  indicam janelas de indisponibilidade; depois de uma recuperação, o indicador leva ~15 min para
  voltar a 100 % (as amostras antigas continuam na janela) — isso é esperado e evita "mascarar" a
  falha recente.
- **Critérios de atenção:** `< 99 %` (amarelo) merece investigação; `< 95 %` (vermelho) é incidente.
  O limite de 99 % tolera uma falha isolada em ~30 verificações.
- **Ação decorrente:** abrir o painel 2 para localizar a janela de falha, conferir o painel 8 (logs)
  e o estado dos containers (`docker compose ps`). Se a falha for de conexão, checar o túnel
  Cloudflare; se for de conteúdo, checar o back-end/MongoDB.
- **Validação e limitações:** validado **no ambiente real**: com a exceção (bypass) do Cloudflare
  Access aplicada, os dois alvos respondem **2xx** e a janela de 2 min mostra **100 %**. Logo após o
  deploy, a janela de 15 min mostrou **50 %** porque ainda continha amostras de quando
  `/api/health/ready` não existia (HTTP 404 no app antigo) — comportamento esperado.
  **Semântica importante do dado:** o receiver publica a métrica **por verificação** (não é um
  contador acumulativo) e **não emite zeros ausentes**; por isso **não se usa `increase()`/`rate()`
  nessas séries**. O `httpcheck.status` é um *gauge* 1/0 por classe, sempre presente, o que o torna
  robusto para calcular disponibilidade. A validação de conteúdo é usada como **sinal complementar**
  (painel 2). **Limitação:** o probe comprova a **rota de health** pelo domínio; não exercita as
  rotas de negócio (cobertas pelos painéis 3–6).

### Painel 2 — Disponibilidade: linha do tempo das verificações

- **Pergunta operacional:** **quando** a aplicação ficou indisponível e qual foi a natureza da falha?
- **Motivo da escolha:** o painel 1 diz *quanto*, mas não *quando* nem *por quê*. Localizar a janela
  exata e distinguir "falha de servidor" de "resposta inesperada" acelera o diagnóstico.
- **Origem dos dados:** `httpcheck.status` (classes 2xx e 5xx) e `httpcheck.validation.failed`
  (respondeu 2xx, mas o conteúdo não era o da aplicação — ex.: página de login do Cloudflare Access),
  todos do mesmo receiver `http_check`.
- **Consulta e cálculo:**
  ```promql
  httpcheck_status{http_status_class="2xx"}   # sucesso
  httpcheck_status{http_status_class="5xx"}   # falha de servidor
  httpcheck_validation_failed                 # resposta OK, conteúdo inesperado
  ```
  Valores **1/0 por verificação**, sem agregação (o `legendFormat` separa os alvos `{{http_url}}`).
- **Recorte temporal:** janela padrão de 6 h; atualização 30 s; timestamps em UTC.
- **Forma de visualização:** `timeseries` em **barras empilhadas** — verde (sucesso), vermelho
  (5xx) e laranja (falha de conteúdo). O empilhamento mostra presença e proporção ao mesmo tempo.
- **Interpretação:** barras verdes contínuas = operação normal. Cada verificação gera um ponto a cada
  30 s, então **a presença da série comprova que a coleta está viva**. A linha de falha de conteúdo só
  aparece quando o corpo é inesperado — a **ausência dela significa "nenhuma falha de conteúdo"**, e
  não "sem coleta" (a série 2xx continua marcando cada verificação).
- **Critérios de atenção:** **qualquer** barra vermelha (5xx) ou linha laranja merece investigação.
- **Ação decorrente:** cruzar o horário da barra com os logs (painel 8) e com o histórico de deploys
  do GitHub Actions. Falha de conteúdo com 2xx geralmente indica intervenção de borda (Access/túnel),
  não do back-end.
- **Validação e limitações:** validado no ambiente real — após o bypass do Access, as barras ficaram
  verdes e a linha de falha de conteúdo desapareceu (as amostras antigas de falha expiraram da janela).
  **Limitação:** o probe reporta o resultado por verificação de 30 s; rajadas mais curtas que isso
  podem não aparecer.

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
- **Validação e limitações:** validado **no ambiente real**: com os buckets corrigidos, a janela de 3 min mostrou `/health` p50 **2,62 ms** / p95 **4,98 ms**, `/health/ready` p50 **6,05 ms** / p95 **10,00 ms** e `/todos` p50 **8,95 ms** / p95 **154,19 ms** (a cauda inclui as escritas de criação). Antes da correção o painel mostrava **2,5 s / 4,75 s** para todas as rotas, porque o SDK usa buckets em milissegundos por padrão e as amostras (em segundos) caíam no primeiro bucket — ver a correção de `explicitBucketBoundaries` na seção 6.2. **Limitação:** `NaN` aparece para rotas sem amostras na janela — é ausência de tráfego, não erro.

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
- **Validação e limitações:** validado **no ambiente real**: no cenário E3, `POST /todos` sem o campo `text` produziu **5× HTTP 400** (4xx visível em `/todos`); no cenário E4, com o MongoDB parado, a rota `/health/ready` apareceu com **32,79 %** de 5xx. **Limitação (corrigida):** um erro **isolado** podia não aparecer porque a série do contador nascia já com valor 1 e o `increase()` não tinha baseline 0 — resolvido pré-inicializando as séries com 0 (seção 6.2). Rotas sem erro não aparecem como 0 %: a ausência de linha significa 0 % na prática.

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
- **Validação e limitações:** validado **no ambiente real**: no cenário E2 (40 criações + 20 listagens) o painel registrou `create success = 86,96` e `list success = 45,13` na janela de 10 min, coerentes com o tráfego gerado. **Limitação:** mede apenas o que chega ao back-end — como o SPA passou a ser servido pela **edge (Pages)**, o carregamento de assets não passa mais pelo back-end e só as chamadas de `/api/*` aparecem.

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
- **Validação e limitações:** validado **no ambiente real**: com o MongoDB saudável as operações ficaram na casa dos milissegundos; no cenário E4, `find` registrou **1 falha** ao parar o banco. **Limitação:** mede o tempo **visto pelo back-end**; o tempo **interno** do MongoDB (ex.: lock, compaction) não é instrumentado — não há exporter do MongoDB nesta versão.

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
- **Validação e limitações:** **validado no ambiente real (cenário E4)**: com o MongoDB parado, `GET /todos` retornou **500** e o painel saiu de **0,0 %** para **1,44 %** de falhas; após restaurar o banco, voltou a 0 %. **Limitação:** mede o que **o back-end** vê; um erro que impeça o back-end de sequer tentar a operação não é contado aqui (apareceria no painel 4, como 5xx).

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
- **Validação e limitações:** validado **no ambiente real** de ponta a ponta: no cenário E3, o evento `todos.create.invalid` foi **recuperado do Loki** com a consulta acima (10 ocorrências); no cenário E4, `todos.list.failed` apareceu com a falha de banco. O `request_id` presente em cada linha permite correlacionar com `docker logs todo-backend`. **Limitação:** os logs do **nginx** não são coletados; erros ocorridos antes do Express (ex.: 502 da borda) não aparecem aqui.