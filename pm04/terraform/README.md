# PM-04 — Smart Construction (Terraform / AWS Free Tier)

Provisiona a infraestrutura da aplicação **Smart Construction** (Next.js + FastAPI +
PostgreSQL 17 + 2× SeaweedFS) na AWS (Free Tier, `t3.micro`).

## O que é criado

| Recurso | Descrição |
| --- | --- |
| VPC `vpc-smart-construction-<env>` | Rede `10.10.0.0/16` |
| Subnet pública `sn-sc-public-<env>` | `10.10.1.0/24` — VM de aplicação |
| Subnet privada `sn-sc-private-<env>` | `10.10.2.0/24` — VM de banco (sem IP público) |
| Internet Gateway | Egress da subnet pública |
| Route table privada → ENI da VM app | Egress do banco via NAT (masquerade na app) |
| Key Pair | Chave pública SSH (`var.ssh_public_key_path`) |
| VM `vm-sc-app-<env>` | Aplicação, subnet pública, IP público, `source_dest_check = false` |
| VM `vm-sc-db-<env>` | Banco, subnet privada, **sem IP público** |

## Proteção da porta 5432

A VM de banco fica em subnet **privada** (`map_public_ip_on_launch = false`), sem
IP público e sem rota de entrada pela internet. O security group da subnet privada
(`sg-sc-db-<env>`) só aceita ingress TCP/5432 originado da **subnet pública da
aplicação** (`var.app_subnet_cidr`). Não há regra com `cidr_blocks = ["0.0.0.0/0"]`
para o 5432 — o banco é inalcançável pela internet e só a aplicação conversa com
ele pela rede privada.

## Como o NAT via app funciona

Não usamos NAT Gateway gerenciado (custo ~US$32/mês). A VM app faz **MASQUERADE**
(configurada pela role Ansible `nat`) e a route table da subnet privada aponta
`0.0.0.0/0` para a ENI primária da VM app (`aws_route` com
`instance_id = aws_instance.app.id`). Para a AWS encaminhar o tráfego de terceiros
pela instância, a app tem `source_dest_check = false`. Assim o banco baixa pacotes
e atualizações de SO sem nunca ter IP público.

## Pré-requisitos

1. Credenciais AWS (via `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`, `~/.aws/credentials` ou `AWS_PROFILE`).
2. Bucket S3 de state `equipe-sudo-tfstate` já existente (na região do backend, default `us-east-1`).
3. Terraform >= 1.5 e provider `hashicorp/aws` ~> 5.0.

## Uso

```bash
cd pm04/terraform
cp terraform.tfvars.example terraform.tfvars   # preencha os placeholders
terraform init                                 # gera .terraform.lock.hcl (aws)
terraform plan
terraform apply                                # requer aprovação explícita
```

> Estado remoto: backend S3, chave `pm04/terraform.tfstate`. Nunca rode
> `init/apply/destroy` sem aprovação explícita do responsável.

## Variáveis principais

| Variável | Default | Valores |
| --- | --- | --- |
| `environment` | `dev` | `dev`, `homolog`, `prod` |
| `instance_name` | `smart-construction` | — |
| `instance_type` | `t3.micro` | `t3.micro`, `t3.small` |
| `aws_region` | `us-east-1` | — |
| `vpc_cidr` / `app_subnet_cidr` / `db_subnet_cidr` | `10.10.0.0/16` / `10.10.1.0/24` / `10.10.2.0/24` | — |
| `ssh_public_key_path` | `~/.ssh/id_rsa.pub` | — |

## Outputs

`app_vm_public_ip`, `app_vm_private_ip`, `db_vm_private_ip`, `db_vm_public_ip`,
`vpc_id`, `ssh_command_app`.
