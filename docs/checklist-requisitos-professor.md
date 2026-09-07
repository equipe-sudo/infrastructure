# Checklist dos requisitos do professor

## Front-end

| Requisito | Status na arquitetura atual |
|---|---|
| Disponivel pela Internet | Atendido via `https://equipe-sudo.kolpzs.com` |
| Solucao serverless | Parcial: borda/DNS/HTTPS via Cloudflare, app roda em container na OCI VM Always Free A1.Flex |
| HTTPS | Atendido via Cloudflare |
| Redundancia com dois pontos de atendimento | Parcial: redundancia na borda Cloudflare |
| Distribuicao de acesso | Atendido via Cloudflare Edge |
| Dominio/subdominio proprio | Atendido com `equipe-sudo.kolpzs.com` |

## Back-end

| Requisito | Status na arquitetura atual |
|---|---|
| Solucao serverless | Nao literal: roda em container Docker na OCI VM Always Free A1.Flex |
| Nao diretamente exposto a Internet | Atendido |
| Acessado atraves de API | Atendido em `/api/*` |
| Regras de acesso definidas | Atendido por Security List + rede Docker |
| Proxy reverso para o back-end | Atendido via Nginx `/api/* -> backend:5000` |

## Banco de dados

| Requisito | Status na arquitetura atual |
|---|---|
| Servico gerenciado/serverless | Nao literal: MongoDB em container com volume persistente na OCI VM |
| Sem acesso publico | Atendido |
| Acessivel somente pelo back-end | Atendido pela rede Docker |
| Controle de acesso configurado | Atendido com usuario e senha MongoDB |

## Entrega

| Item | Arquivo/evidencia |
|---|---|
| Infraestrutura funcionando | Deploy via `.github/workflows/deploy-vm.yml` |
| Diagrama | `docs/arquitetura.md` |
| Documentacao curta | `docs/documentacao-curta-entrega.md` |

## Pontos que precisam de decisao

Para cumprir 100% literalmente o enunciado, ainda seria necessario migrar os componentes de runtime para servicos serverless/gerenciados, por exemplo:

1. Front-end em Cloudflare Pages.
2. Back-end em Cloudflare Workers, OCI Functions, Azure Container Apps ou Google Cloud Run.
3. Banco em MongoDB Atlas Serverless ou outro banco gerenciado sem acesso publico.

A alteracao feita agora substitui o projeto publicado pelo fork solicitado e preserva o modelo de seguranca ja existente. Usar OCI VM Always Free nao descaracteriza a entrega como infraestrutura em nuvem; o risco esta apenas na interpretacao estrita da palavra serverless.
