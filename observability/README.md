# Stack de observabilidade — Equipe SUDO

Grafana + Prometheus + Loki + OpenTelemetry Collector, executados na **VM de observabilidade**
(`vm-equipe-sudo-obs-dev`), isolada da VM da aplicação.

Documentação completa da entrega: [`../docs/entrega-final-02/README.md`](../docs/entrega-final-02/README.md)

## Arquitetura

```
[VM da aplicação]                                   [VM de observabilidade]
 todo-backend ──OTLP/HTTP :4318──┐
                                 ├──► obs-otel-collector ──remote_write──► obs-prometheus ──┐
 (o próprio Collector faz o      │           │                                              ├──► obs-grafana ──► Cloudflare ──► operador
  probe do domínio a cada 30s) ──┘           └──OTLP /otlp/v1/logs──► obs-loki ─────────────┘
```

O único tráfego aceito da aplicação é OTLP nas portas **4317/4318**, liberado pela Security List
`sl-equipe-sudo-obs-dev` apenas para a origem `10.0.1.0/24`.

## Estrutura

```
observability/
├── docker-compose.yml              # Grafana, Prometheus, Loki, Collector e túnel
├── .env.example                    # variáveis (copie para .env — não versionar)
├── otel/config.yaml                # pipelines + verificação sintética de disponibilidade
├── prometheus/prometheus.yml       # remote_write receiver
├── loki/loki-config.yaml           # single-binary, retenção 30 dias
└── grafana/
    ├── grafana.ini
    ├── provisioning/datasources/   # Prometheus e Loki
    ├── provisioning/dashboards/    # provider de dashboards
    └── dashboards/                 # dashboard "Entrega Final 02" (8 painéis)
```

## Operação

```bash
# preparar
cp .env.example .env   # preencher GRAFANA_ADMIN_PASSWORD e GRAFANA_TUNNEL_TOKEN

# subir / atualizar
docker compose --env-file .env pull
docker compose --env-file .env up -d

# status
docker compose --env-file .env ps

# logs
docker logs obs-otel-collector
docker logs obs-grafana

# validar a coleta
curl -s http://127.0.0.1:9090/-/ready          # Prometheus
curl -s http://127.0.0.1:3100/ready            # Loki
curl -s http://127.0.0.1:3000/api/health       # Grafana
```

## Validar a configuração do collector antes de subir

```bash
docker run --rm \
  -e PUBLIC_HEALTH_URL=https://equipe-sudo.kolpzs.com/api/health \
  -e PUBLIC_READY_URL=https://equipe-sudo.kolpzs.com/api/health/ready \
  -e DEPLOYMENT_ENVIRONMENT=dev \
  -v "$PWD/otel/config.yaml:/etc/otel/config.yaml:ro" \
  otel/opentelemetry-collector-contrib:0.160.0 validate --config=/etc/otel/config.yaml
```

## Consultas úteis (debug)

```promql
# métricas da aplicação chegaram?
count by (service_name) (app_http_requests_total)

# o probe está validando conteúdo?
httpcheck_validation_passed or httpcheck_validation_failed

# o instrumento está no ar?
up
```

```logql
{service_name="equipe-sudo-backend"} | json | level="error"
```

## Retenção

| Sinal | Onde | Tempo |
|---|---|---|
| Métricas | Prometheus (volume `obs-prometheus-data`) | 15 dias / 1500 MB |
| Logs | Loki (volume `obs-loki-data`) | 30 dias |

## Observações

- As imagens são públicas — o deploy **não** precisa de login no GHCR.
- As portas do Grafana/Prometheus/Loki são publicadas apenas em `127.0.0.1`; o acesso externo
  acontece exclusivamente pelo túnel Cloudflare dedicado.
- O `resource_to_telemetry_conversion` do `prometheus_remote_write` está marcado como *deprecated*
  na versão 0.160.0, mas continua funcional e é o que promove os atributos de recurso (ex.:
  `service_name`) a labels no Prometheus.
