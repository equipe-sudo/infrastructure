# Justificativas Técnicas — Equipe SUDO

## 1. OCI Always Free (Oracle Cloud)

**Escolha:** Oracle Cloud Infrastructure — tier Always Free  
**Justificativa:** A OCI oferece recursos gratuitos vitalícios sem cartão de crédito (no tier Always Free):
- Até 4 OCPUs e 24 GB RAM em VMs Ampere A1.Flex
- 200 GB de Object Storage
- Networking básico gratuito

**Alternativas consideradas:** AWS Free Tier (expira em 12 meses), GCP (menos recursos gratuitos), Azure (créditos temporários).

---

## 2. VM.Standard.A1.Flex (Ampere ARM)

**Escolha:** Shape Ampere A1.Flex com 2 OCPU + 12 GB RAM  
**Justificativa:**
- Arquitetura ARM64 eficiente para containers
- 2 OCPUs e 12 GB é overkill para um jogo de slots, mas é o que está disponível gratuitamente
- Oracle Linux 8 por ser a distribuição nativa da OCI com melhor compatibilidade

---

## 3. Docker + Docker Compose

**Escolha:** Containers Docker orquestrados com Docker Compose  
**Justificativa:**
- **Isolamento:** Backend, frontend e banco de dados em containers independentes
- **Reprodutibilidade:** Mesmo ambiente em dev local e na VM de produção
- **Persistência:** Volumes nomeados garantem que dados do PostgreSQL sobrevivam a restarts
- **Simplicidade:** Docker Compose é suficiente para um deploy single-node; Kubernetes seria desnecessário para este projeto

**Alternativas consideradas:** Kubernetes (OKE) — descartado por complexidade excessiva para 3 containers. Instalação direta na VM — descartada por falta de isolamento.

---

## 4. PostgreSQL (via Docker)

**Escolha:** PostgreSQL 16 Alpine  
**Justificativa:**
- Banco relacional maduro e robusto
- Suporte nativo a JSONB (grade_json do giro)
- Volume persistente nomeado `pgdata` garante dados intactos após `docker compose down`
- Alpine reduz tamanho da imagem (~100 MB vs ~400 MB da versão completa)

---

## 5. Nginx como Reverse Proxy

**Escolha:** Nginx servindo frontend + proxy para backend  
**Justificativa:**
- Serve arquivos estáticos de forma eficiente
- Roteia `/api/*` para o backend FastAPI
- Expõe apenas porta 80 para o mundo exterior
- Gzip e cache de assets configurados

---

## 6. Terraform (Infrastructure as Code)

**Escolha:** Terraform com provider OCI  
**Justificativa:**
- Infraestrutura versionada e reproduzível
- `terraform plan` permite validar mudanças antes de aplicar
- Destruir e recriar o ambiente com `terraform destroy && terraform apply`
- Padrão de mercado para IaC multi-cloud

---

## 7. Ansible (Configuration Management)

**Escolha:** Ansible para pós-provisionamento da VM  
**Justificativa:**
- Agentless — só precisa de SSH
- Playbook YAML simples e legível
- Instala Docker, Docker Compose e dependências de forma declarativa
- Idempotente: rodar múltiplas vezes é seguro

---

## 8. FastAPI (Backend)

**Escolha:** FastAPI (Python) para a API do jogo  
**Justificativa:**
- Performance comparável a Node.js/Go (assíncrono via asyncio)
- Documentação automática via Swagger/OpenAPI integrada
- Validação de dados com Pydantic
- Ecossistema Python rico para RNG e lógica de jogo

---

## Limitações Conhecidas

1. **Single point of failure:** Apenas 1 VM — se cair, tudo cai. Justificável pelo escopo acadêmico e tier gratuito.
2. **Banco no mesmo host:** PostgreSQL na mesma VM que a aplicação. Em produção, usaria um serviço gerenciado (RDS, Autonomous DB).
3. **Sem HTTPS:** Nginx expõe HTTP (porta 80). HTTPS exigiria domínio + certificado SSL (Let's Encrypt), fora do escopo.
4. **Sem backup automático:** Volume pgdata não tem backup. Para produção, agendar dump periódico para Object Storage.
