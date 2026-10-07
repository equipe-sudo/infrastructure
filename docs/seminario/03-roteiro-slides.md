# Roteiro + Prompt para geração dos slides

> Este arquivo serve para duas coisas:
> 1. **Roteiro** de cada slide (quem fala, o que diz, qual imagem/figura deve ter).
> 2. **Prompt pronto** (no fim) para colar em outro modelo e gerar os slides automaticamente.

---

## Roteiro de slides (slide a slide)

### Slide 1 — Capa
- **Título:** Redes e Isolamento na AWS
- **Subtítulo:** VPC, Subnets, Security Groups e NAT Gateway
- **Fala:** João (10s)
- **Visual:** logotipo AWS + nomes dos 4 integrantes (João, Fernanda, Allan, Thiago) + nome da disciplina/semestre.
- **Figura:** banner/ilustração de nuvem com uma rede (opcional, gerada ou stock).

### Slide 2 — Roteiro da apresentação
- **Título:** O que vamos ver
- **Fala:** João (15s)
- **Conteúdo:** as 5 perguntas listadas, com o responsável de cada uma.
- **Visual:** lista numerada com ícones simples.

### Slide 3 — Pergunta 1: O problema
- **Título:** Qual problema o VPC resolve?
- **Fala:** João (~2 min)
- **Conteúdo (bullets):**
  - Sem rede controlada → tudo exposto e acessível.
  - Banco e back-end viram alvo de ataque.
  - Não dá para saber quem fala com quem.
- **Figura:** desenho "antes" — máquinas e banco expostos à internet (sinal de alerta).

### Slide 4 — Pergunta 1: A solução
- **Título:** VPC: sua rede privada na nuvem
- **Fala:** João (continuação)
- **Conteúdo:**
  - Isolamento lógico (condomínio só seu).
  - Segmentação (subnets pública/privada).
  - Controle fino de acesso (Security Groups).
- **Figura:** desenho "depois" — recursos dentro de uma caixa fechada (VPC), internet do lado de fora.

### Slide 5 — Pergunta 1: Analogia do prédio
- **Título:** Analogia: um prédio com portaria
- **Fala:** João (fechamento da P1)
- **Figura:** ilustração do prédio (VPC) → apartamentos com varanda (subnet pública) e sem varanda (privada) → portaria (Security Group) → porteiro pedindo pizza (NAT Gateway).

### Slide 6 — Pergunta 2: Os 4 blocos
- **Título:** Como funciona? 4 peças
- **Fala:** Fernanda (~2 min)
- **Conteúdo (4 cards):**
  1. VPC — rede isolada (CIDR 10.0.0.0/16)
  2. Subnets — divisões da rede (pública / privada)
  3. Gateways — IGW (entrada/saída) e NAT (só saída)
  4. Firewalls — Security Group (stateful) e NACL (stateless)
- **Figura:** diagrama com 4 blocos destacados.

### Slide 7 — Pergunta 2: Fluxo de um pacote
- **Título:** Como um pacote é decidido
- **Fala:** Fernanda (continuação)
- **Conteúdo:** passo a passo 1→5 (rota → gateway → NACL → SG → destino).
- **Figura:** fluxograma vertical com setas.

### Slide 8 — Pergunta 2: Stateful vs Stateless
- **Título:** Firewall stateful vs stateless
- **Fala:** Fernanda (transição, 30s) — explica a diferença rapidamente.
- **Conteúdo:**
  - Security Group (stateful): libera a saída → resposta entra sozinha.
  - NACL (stateless): libera entrada E saída separado.
- **Visual:** tabela comparativa de 2 colunas.

### Slide 9 — Pergunta 3: Arquitetura 3 camadas
- **Título:** Arquitetura usando VPC
- **Fala:** Allan (~2 min)
- **Figura:** **diagrama de arquitetura** (o mermaid do arquivo de resposta, desenhado bonito):
  - Internet → ALB (subnet pública) → App (subnet privada) → Banco (subnet privada).
  - Setas vermelhas tracejadas "bloqueado" para app e banco.
  - IGW e NAT Gateway.

### Slide 10 — Pergunta 3: Regras de Security Group
- **Título:** Regras de segurança (quem acessa o quê)
- **Fala:** Allan (continuação)
- **Conteúdo:** tabela SG-ALB / SG-APP / SG-DB com porta e origem.
- **Figura:** tabela com cores (verde = permitido, vermelho = bloqueado).

### Slide 11 — Pergunta 3: Conexão com nosso projeto
- **Título:** É o que já fazemos na OCI
- **Fala:** Allan (fechamento da P3)
- **Conteúdo:** tabela AWS ↔ OCI (VPC↔VCN, SG↔Security List, IGW↔IGW).
- **Figura:** lado a lado AWS e OCI.

### Slide 12 — Pergunta 4: Vantagens
- **Título:** Vantagens
- **Fala:** Thiago (~1,5 min)
- **Conteúdo:** 6-8 bullets (isolamento, defesa em profundidade, controle granular, segmentação, NAT seguro, auditoria).
- **Visual:** lista com ícones de check.

### Slide 13 — Pergunta 4: Limitações
- **Título:** Limitações
- **Fala:** Thiago (~1,5 min)
- **Conteúdo:** bullets (curva de aprendizado, limite de VPCs, custo do NAT, erro de config, stateful confunde, troubleshooting difícil).
- **Visual:** lista com ícones de alerta.

### Slide 14 — Pergunta 5: Demonstração
- **Título:** Demo ao vivo (OCI)
- **Fala:** João (~2,5 min)
- **Conteúdo:** os 3 comandos curl (site 200 OK; back-end falha; banco falha).
- **Figura:** screenshots do console OCI (VCN, subnet, Security List) + terminal com os resultados.

### Slide 15 — Pergunta 5: Tradução para AWS
- **Título:** O mesmo conceito na AWS
- **Fala:** João (fechamento)
- **Conteúdo:** tabela OCI↔AWS e a frase de conclusão.
- **Figura:** tabela comparativa.

### Slide 16 — Conclusão
- **Título:** Resumo
- **Fala:** João (30s)
- **Conteúdo:** 3 frases-chave:
  1. VPC = rede privada isolada.
  2. Subnets + gateways = segmentação.
  3. Security Groups/NACL = controle de acesso.
- **Visual:** linha do tempo resumida dos 4 conceitos.

### Slide 17 — Obrigado / Perguntas
- **Título:** Obrigado! Dúvidas?
- **Fala:** todos (aberto)
- **Visual:** contatos / link do repositório `equipe-sudo/infrastructure`.

---

## Prompt pronto para gerar os slides

> Cole o texto abaixo em outro modelo (gerador de slides/imagens). Substitua `[FERRAMENTA]` pela plataforma desejada (PowerPoint, Google Slides, Canva, etc.).

```
Você vai me ajudar a criar uma apresentação de slides profissional para um seminário
de faculdade. Siga exatamente o roteiro abaixo.

CONTEXTO:
- Tema: Redes e Isolamento na AWS (VPC, Subnets, Security Groups, NAT Gateway).
- Público: professores e alunos (didático, visual, fácil de entender).
- Idioma: português (mantenha nomes técnicos em inglês: VPC, Subnet, Security Group, NAT Gateway).
- Duração: 20 minutos, 4 apresentadores: João, Fernanda, Allan e Thiago.
- Formato desejado: [FERRAMENTA] (slide por slide, com título, bullets e indicação de figura/imagem).

REQUISITOS GERAIS:
1. Cada slide deve ter: título claro, 3-6 bullets curtos, e uma indicação de figura/imagem
   (diagrama, ícone, ilustração ou screenshot).
2. Visual limpo e profissional, cores sóbrias (azul AWS #232F3E / laranja #FF9900 opcional).
3. Não encha os slides de texto: os detalhes ficam na fala do apresentador.
4. Marque em cada slide o NOME de quem apresenta e o tempo estimado.

SLIDES (na ordem):

1. CAPA — "Redes e Isolamento na AWS" — subtítulo "VPC, Subnets, Security Groups e NAT
   Gateway" — nomes: João, Fernanda, Allan, Thiago. (João, 10s)
2. ROTEIRO — "O que vamos ver" — as 5 perguntas e quem responde cada uma. (João, 15s)
3. P1 O PROBLEMA — "Qual problema o VPC resolve?" — sem rede controlada tudo fica exposto;
   banco/back-end viram alvo; ninguém sabe quem fala com quem. Figura: "antes" (recursos
   expostos, alerta). (João, 2min)
4. P1 A SOLUÇÃO — "VPC: sua rede privada na nuvem" — isolamento lógico, segmentação
   (subnets pública/privada), controle fino (Security Groups). Figura: "depois" (caixa fechada).
   (João, continuação)
5. P1 ANALOGIA — "Analogia: um prédio com portaria" — prédio=VPC, apartamentos=subnets,
   varanda=pública, portaria=Security Group, porteiro pedindo pizza=NAT Gateway. (João, 30s)
6. P2 OS 4 BLOCOS — "Como funciona? 4 peças" — VPC, Subnets, Gateways (IGW/NAT), Firewalls
   (SG/NACL). 4 cards com ícones. (Fernanda, 2min)
7. P2 FLUXO — "Como um pacote é decidido" — passo 1→5: rota → gateway → NACL → SG → destino.
   Fluxograma vertical. (Fernanda, continuação)
8. P2 STATEFUL — "Firewall stateful vs stateless" — SG stateful (resposta volta sozinha) vs
   NACL stateless (libera entrada e saída). Tabela 2 colunas. (Fernanda, 30s)
9. P3 ARQUITETURA — "Arquitetura usando VPC" — diagrama: Internet → ALB (pública) → App
   (privada) → Banco (privada); setas tracejadas "bloqueado" para app/banco; IGW e NAT.
   (Allan, 2min)
10. P3 REGRAS — "Regras de segurança" — tabela SG-ALB (443/0.0.0.0/0), SG-APP (80/SG-ALB),
    SG-DB (5432/SG-APP). Verde=permitido, vermelho=bloqueado. (Allan, continuação)
11. P3 NOSSO PROJETO — "É o que já fazemos na OCI" — tabela AWS↔OCI: VPC↔VCN,
    SG↔Security List, IGW↔IGW. Lado a lado. (Allan, 30s)
12. P4 VANTAGENS — "Vantagens" — isolamento, defesa em profundidade, controle granular,
    segmentação, NAT seguro, auditoria. Ícones de check. (Thiago, 1,5min)
13. P4 LIMITAÇÕES — "Limitações" — curva de aprendizado, limite de VPCs, custo do NAT,
    erro de config, stateful confunde, troubleshooting difícil. Ícones de alerta. (Thiago, 1,5min)
14. P5 DEMO — "Demo ao vivo (OCI)" — comandos: site 200 OK; back-end falha; banco falha.
    Screenshots do console OCI (VCN, subnet, Security List) + terminal. (João, 2,5min)
15. P5 TRADUÇÃO — "O mesmo conceito na AWS" — tabela OCI↔AWS + frase de conclusão.
    (João, 30s)
16. CONCLUSÃO — "Resumo" — 3 frases-chave + linha do tempo dos 4 conceitos. (João, 30s)
17. OBRIGADO — "Obrigado! Dúvidas?" — contatos/link do repo equipe-sudo/infrastructure.
    (todos, aberto)

TAREFA:
Gere o conteúdo completo de cada slide (título, bullets exatos em português, e descrição
da figura/imagem a inserir). Para os diagramas (slides 3, 4, 5, 6, 7, 9, 11, 15), descreva
exatamente o que o diagrama deve mostrar (nós, setas, cores) para eu desenhar ou pedir
geração de imagem. Seja didático e visual.
```

---

## Checklist antes de apresentar

- [ ] Testar os comandos `curl` da demo antes (ter o terminal aberto).
- [ ] Ter screenshots do console OCI (VCN, subnet, Security List) prontos.
- [ ] Confirmar quem abre e fecha a apresentação (sugestão: João).
- [ ] Cronometrar ~3 min por pergunta (treinar as transições).
- [ ] Ter o link do repositório `equipe-sudo/infrastructure` para a conclusão.
