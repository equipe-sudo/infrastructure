# PM-04 — Ansible: Smart Construction em 2 VMs AWS

Provisiona duas VMs **Amazon Linux 2023** provisionadas pelo Terraform e sobe o
aplicativo **Smart Construction**:

| VM | Subnet | IP | Papel |
|----|--------|----|-------|
| `app` | pública | público | gateway (nginx), web (Next.js), api (FastAPI), migrations, SeaweedFS editorial + privado |
| `db`  | privada | privado (sem IP público) | somente PostgreSQL 17 |

A VM `db` é acessível apenas via SSH bastion (ProxyCommand pela `app`) e pela
porta **5432** vinda da `app` (regra de Security Group aplicada no Terraform).

## Estrutura

```
pm04/ansible/
├── ansible.cfg                    # defaults, pipelining, sudo
├── inventory.yml                  # grupos app e db (placeholders de IP)
├── playbook.yml                   # play mestre (ordem: os_updates+docker → db → app)
├── group_vars/all.yml             # defaults das variáveis da pipeline
└── roles/
    ├── os_updates/tasks/main.yml
    ├── docker/tasks/main.yml
    ├── postgres/
    │   ├── tasks/main.yml
    │   └── files/{docker-compose.db.yml, init-db.sh}
    └── smartapp/
        ├── tasks/main.yml
        ├── files/{docker-compose.app.yml, private-storage.sh, generate_identities.py}
        ├── files/nginx/default.conf
        ├── files/storage/{start.sh, init.sh, cli.sh}
        └── templates/.env.j2
```

## Variáveis da pipeline

Repassadas ao playbook via `-e` (o workflow de CI as injeta):

| Variável | Default | Uso |
|----------|---------|-----|
| `update_os` | `false` | `dnf update` no SO (role `os_updates`) |
| `extra_packages` | `""` | pacotes extras via dnf (separados por vírgula) |
| `docker_tag` | `latest` | tag das imagens `ghcr.io/equipe-sudo/smart-construction-{web,api}` |
| `environment` | `production` | `SMART_API_ENVIRONMENT` (`production` → cookie Secure + HTTPS) |
| `db_private_ip` | `<DB_PRIVATE_IP>` | IP privado do banco (output do Terraform) |

## Roles

### `os_updates`
Aplica `dnf name="*" state=latest` **somente** quando `update_os: true`.
Com `false` (padrão) não faz nada. Idempotente: o módulo `dnf` só reporta
`changed` quando há pacotes para atualizar.

### `docker`
Instala Docker CE (repo oficial `download.docker.com`), `docker-ce-cli`,
`containerd.io`, `docker-buildx-plugin` e `docker-compose-plugin`; inicia e
habilita o daemon; adiciona `ec2-user` ao grupo `docker`; instala `extra_packages`.
Como o AL2023 resolve `$releasever` como `2023` (inexistente no repo CentOS), a
role fixa `$releasever=9` (via `replace`) após baixar o `docker-ce.repo`.
Todos os módulos (`dnf`, `get_url`, `replace`, `systemd`, `user`) são idempotentes.

### `postgres` (hosts `db`)
Gera os segredos `migration-password` e `api-password` em
`/opt/smart-construction/.secrets/backend/` (modo `0600`, só se ausentes) e
sobe `postgres:17-bookworm` com volume nomeado persistente (`db-data`).
- `POSTGRES_DB=smart_construction`, `POSTGRES_USER=smart_migrator`.
- A senha do migrador entra por `POSTGRES_PASSWORD_FILE` (bind mount do secret).
- O `init-db.sh` cria o role de runtime `smart_api` (idempotente) e fecha o
  schema `public`; o schema `smart` e as permissões são criados pelo Alembic.
- Healthcheck `pg_isready`; `wait_for` na 5432 garante que o banco está pronto
  antes da aplicação.

### `smartapp` (hosts `app`)
1. Gera os segredos locais (`storage/*`, `backend/s3-*`) no host.
2. Gera o `s3-identities.json` do SeaweedFS privado (script idempotente).
3. Copia os segredos do banco a partir da VM `db` (`slurp` + `copy`), para a
   API e a migração usarem a **mesma** senha gerada na VM db.
4. Copia os arquivos estáticos (compose, nginx, scripts dos storages).
5. Gera `.env` (sem segredos) e o certificado HTTPS autoassinado (`openssl`).
6. Sobe os serviços via `docker compose` e aguarda o gateway HTTPS.

A API e a migração apontam para `db_private_ip:5432`; o gateway expõe 80/443
com HTTPS + HSTS + `proxy_cookie_secure`.

## Idempotência (critério de nota)

- `copy` com `force: false` só grava segredos ausentes (2ª execução = zero mudanças).
- `community.docker.docker_compose_v2` reconcilia o estado desejado
  (`pull: missing` só baixa imagens ausentes).
- `openssl` usa `creates:`; `dnf` usa `state: present/latest` (latest só quando `update_os`).
- `slurp` + `copy` só reescrevem quando o conteúdo difere.
- Nenhuma task usa `shell` destrutivo; nada é removido sem aprovação.

> **Nota sobre jobs one-shot.** Os serviços `api-migrate`, `storage-init` e
> `private-storage-init` reexecutam a cada `docker compose up` (são
> one-shot, `restart: 'no'`), mas são idempotentes por natureza: `alembic
> upgrade head` vira no-op com o banco já migrado, `s3 sync --no-overwrite`
> não sobrescreve e o bootstrap não altera bucket já existente. Os serviços
> de longa duração (`web`, `api`, `gateway`, `storage`, `private-storage`,
> `db`) usam `restart: unless-stopped` e não são recriados sem mudança de
> config — é onde a idempotência "zero mudanças" se aplica estritamente.

## Segredos

- **Nunca** vão para o repositório; são gerados no host em
  `/opt/smart-construction/.secrets/` (diretório `0700`).
- `backend/*` ficam com modo `0444` **porque** o container da API roda como
  usuário não-root (`uid 10001`) e precisa lê-los via bind mount; a proteção
  real no host vem do diretório `0700` (só o root lista/lê).
  Isso replica o padrão do `setup_secrets.py` do repositório de origem.
- `storage/*` ficam em `0600` (containers do SeaweedFS/aws-cli rodam como root).
- O certificado TLS é autoassinado e fica em `/opt/smart-construction/tls/`
  (chave `0600`), gerado com SAN para o IP público da VM app.

## Execução

```bash
# Validação de sintaxe (sem tocar nas VMs)
ansible-playbook -i inventory.yml playbook.yml --syntax-check

# Deploy real (substitua os placeholders / passe as variáveis)
ansible-playbook -i inventory.yml playbook.yml \
  -e update_os=false \
  -e docker_tag=v1.2.3 \
  -e db_private_ip=10.0.0.10
```

> Não rode contra VMs reais sem substituir `<APP_PUBLIC_IP>` e
> `<DB_PRIVATE_IP>` no inventário (ou via `-e`).

## Limitações / pendências documentadas

- **Imagens seed do catálogo editorial** (`public/images`, ~38 MB): não são
  versionadas aqui. Para subir com fotos, defina `seed_images_source` apontando
  para a pasta local com as imagens (ex.: `-e seed_images_source=/caminho/public/images`).
  Sem isso, o catálogo sobe sem as fotos (os dados JSON continuam funcionando).
- **Conta de administrador e carga das 25 profissões** são passos **manuais**
  (via `docker compose exec api python -m app.auth.cli create ...` e
  `python -m app.profissoes.cli --apply ...`), como no repositório de origem.
- **HTTPS** usa certificado autoassinado (browser exibe aviso). Para um domínio
  real, gere um certificado válido ou use Cloudflare Tunnel, ajustando
  `APP_PUBLIC_ORIGIN` no `.env` e a SAN do certificado.
- A **porta 5432** é liberada apenas para a origem da app pelo Security Group
  do Terraform (fora do escopo deste repositório Ansible).
- **NAT instance**: a VM `app` faz NAT (MASQUERADE) do egress do banco. No AWS,
  o Terraform precisa desabilitar o **Source/Destination Check** na ENI da `app`
  e apontar a rota `0.0.0.0/0` da subnet do banco para a `app`. O AL2023 não
  tem `firewalld` por padrão — a role `nat` instala `iptables-nft` e aplica
  `ip_forward` + `FORWARD ACCEPT` + `MASQUERADE` via `iptables`.
