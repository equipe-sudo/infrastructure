# Documentacao curta da entrega

## Aplicacao utilizada

A aplicacao entregue e o Todo App do fork solicitado pelo professor:

`https://github.com/equipe-sudo/aula-uniamerica-infraestrutura-cloud`

O projeto possui tres componentes:

| Componente | Implementacao |
|---|---|
| Front-end | React servido por Nginx |
| Back-end | Node.js + Express |
| Banco de dados | MongoDB |

## Servicos de nuvem utilizados

| Servico | Uso |
|---|---|
| Oracle Cloud Infrastructure | VM Always Free A1.Flex com 2 OCPU e 12 GB RAM, VCN, subnet, security list e container registry |
| Cloudflare DNS | Resolucao do dominio `equipe-sudo.kolpzs.com` |
| Cloudflare Tunnel | Entrada HTTPS e proxy reverso publico sem abrir portas web na VM |
| OCI Container Registry | Armazenamento das imagens Docker do front-end e back-end |

## Por que foram escolhidos

OCI Always Free foi mantida porque tem custo zero para a equipe e permite usar o shape Ampere A1.Flex. Na validacao do tenancy, havia disponibilidade de 2 OCPU e 12 GB RAM para A1.Flex, muito acima da VM E2.1.Micro anterior de 1 OCPU e 1 GB RAM. Esse tamanho e suficiente para executar front-end, back-end, MongoDB e cloudflared com folga para a aplicacao academica. Cloudflare foi usado para DNS, HTTPS e tunnel, reduzindo superficie de ataque porque a VM nao precisa expor HTTP, HTTPS, back-end ou banco diretamente para a Internet.

Usar OCI dessa maneira nao descaracteriza automaticamente a entrega: a infraestrutura continua sendo cloud, com DNS, HTTPS, proxy reverso, firewall, isolamento de componentes e controle de acesso. O unico cuidado e que, se o professor exigir serverless literal para runtime e banco, sera necessario justificar a escolha ou migrar esses componentes para servicos serverless/gerenciados.

## Como a seguranca foi implementada

| Camada | Controle |
|---|---|
| Internet para VM | Security List permite apenas SSH 22 inbound |
| Entrada web | Somente pelo Cloudflare Tunnel |
| Front-end | Acessivel pelo dominio HTTPS |
| Back-end | Sem porta publicada, acessivel apenas pela rede Docker via Nginx |
| Banco de dados | Sem porta publicada, acessivel apenas pelo back-end na rede Docker |
| Credenciais | Token do tunnel e acesso OCIR via GitHub Secrets |

Regra aplicada: tudo bloqueado, exceto o necessario para funcionamento e operacao.

## Como funciona a redundancia do front-end

O acesso publico passa pelo Cloudflare Edge, que possui multiplos pontos globais de atendimento para DNS, HTTPS e proxy. O container do front-end e servido internamente por Nginx na VM. Na arquitetura atual, a redundancia real esta na camada de borda Cloudflare, nao em multiplas instancias do container dentro da OCI.

## Como funciona o proxy reverso

Existem duas camadas de proxy:

| Proxy | Funcao |
|---|---|
| Cloudflare Tunnel | Recebe HTTPS no dominio e encaminha para o servico interno `frontend:80` |
| Nginx do front-end | Serve o React e encaminha `/api/*` para `backend:5000` |

Exemplo:

```text
GET https://equipe-sudo.kolpzs.com/api/todos
-> Cloudflare
-> cloudflared
-> frontend:80
-> Nginx proxy_pass
-> backend:5000/todos
```

## Como o dominio foi configurado

O dominio `equipe-sudo.kolpzs.com` aponta no Cloudflare para o tunnel configurado no Zero Trust. O tunnel encaminha o hostname publico para o servico HTTP interno do container `frontend` na porta 80.

## Acessos permitidos e bloqueados

| Fluxo | Status | Porta/protocolo |
|---|---|---|
| Usuario -> dominio | Permitido | HTTPS 443 |
| Cloudflare -> cloudflared | Permitido | Tunnel outbound |
| cloudflared -> front-end | Permitido | HTTP 80 interno |
| front-end -> back-end | Permitido | HTTP 5000 interno |
| back-end -> MongoDB | Permitido | TCP 27017 interno |
| Internet -> back-end direto | Bloqueado | TCP 5000 |
| Internet -> MongoDB direto | Bloqueado | TCP 27017 |
| Internet -> front-end direto por IP | Bloqueado | TCP 80/443 |

## Testes sugeridos para evidencia

```bash
curl -I https://equipe-sudo.kolpzs.com
curl https://equipe-sudo.kolpzs.com/api/health
curl https://equipe-sudo.kolpzs.com/api/todos
curl -X POST https://equipe-sudo.kolpzs.com/api/todos \
  -H "Content-Type: application/json" \
  -d '{"text":"Teste de entrega"}'
curl -m 5 http://129.148.50.233:5000/health
curl -m 5 http://129.148.50.233:27017
```

Os dois ultimos comandos devem falhar ou expirar, comprovando bloqueio de acesso direto ao back-end e ao banco.
