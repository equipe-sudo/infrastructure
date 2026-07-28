# Guia de Contribuição — Infraestrutura

## ⚠️ Regra Especial
Apenas o **João Pedro (Scrum Master/DevOps)** pode aprovar alterações neste repositório.
Toda PR precisa de aprovação do João Pedro para ser mergeada.

## Git Flow
- Crie uma branch a partir da main: `feat/nome-da-feature`
- Nunca faça push direto na main
- Abra Pull Request com 2 aprovações obrigatórias
- PRs de infra precisam de aprovação do João Pedro

## Setup
1. `cp .env.example .env` e preencha com suas credenciais OCI
2. `terraform init`
3. `terraform plan` para validar antes de qualquer change

## Documentação
- Diagramas → salvar em `/docs/`
- Decisões técnicas → `/docs/decisoes/`
- Commits seguem Conventional Commits
