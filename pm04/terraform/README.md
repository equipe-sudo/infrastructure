# PM-04 — Smart Construction (Terraform / OCI Always Free)

Provisiona a infraestrutura da aplicação **Smart Construction** (Next.js + FastAPI +
PostgreSQL 17 + 2× SeaweedFS) na OCI Always Free.

## O que é criado

| Recurso | Descrição |
| --- | --- |
| VCN `vcn-smart-construction-<env>` | Rede `10.10.0.0/16` |
| Subnet pública `sn-...-public-<env>` | `10.10.1.0/24` — VM de aplicação |
| Subnet privada `sn-...-private-<env>` | `10.10.2.0/24` — VM de banco (sem IP público) |
| Internet Gateway | Egress da subnet pública |
| NAT Gateway + route table dedicada | Egress da subnet privada (OS updates/pacotes) |
| VM `vm-sc-app-<env>` | Aplicação, subnet pública, IP público |
| VM `vm-sc-db-<env>` | Banco, subnet privada, **sem IP público** |

## Proteção da porta 5432

A VM de banco fica em subnet **privada** (`prohibit_public_ip_on_vnic = true`), sem
IP público e sem rota de entrada pela internet. A security list da subnet privada só
aceita ingress TCP/5432 originado da **subnet pública da aplicação**
(`var.app_subnet_cidr`). Não há regra com `source = 0.0.0.0/0` para o 5432 — o banco é
inalcançável pela internet e só a aplicação conversa com ele pela rede privada.

## Pré-requisitos

1. Credenciais OCI (API key) em `~/.oci/config` e `~/.oci/oci_api_key.pem`.
2. Bucket de state `equipe-sudo-tfstate` (namespace `grhkdi3glvat`) já existente.
3. Terraform >= 1.12 e provider `oracle/oci` >= 5.0.

## Uso

```bash
cd pm04/terraform
cp terraform.tfvars.example terraform.tfvars   # preencha os placeholders
terraform init                                 # gera .terraform.lock.hcl
terraform plan
terraform apply                                # requer aprovação explícita
```

> Estado remoto: backend nativo OCI, chave `pm04/terraform.tfstate`. Nunca rode
> `init/apply/destroy` sem aprovação explícita do responsável.

## Variáveis principais

| Variável | Default | Valores |
| --- | --- | --- |
| `environment` | `dev` | `dev`, `homolog`, `prod` |
| `instance_name` | `smart-construction` | — |
| `vm_shape` | `VM.Standard.E2.1.Micro` | `VM.Standard.E2.1.Micro`, `VM.Standard.A1.Flex` |
| `vm_ocpus` / `vm_memory_gb` | `2` / `12` | 1–4 / 1–24 (A1.Flex) |
| `vcn_cidr` / `app_subnet_cidr` / `db_subnet_cidr` | `10.10.0.0/16` / `10.10.1.0/24` / `10.10.2.0/24` | — |

## Outputs

`app_vm_public_ip`, `app_vm_private_ip`, `db_vm_private_ip`, `db_vm_public_ip`,
`vcn_id`, `app_subnet_id`, `db_subnet_id`, `ssh_command_app`.
