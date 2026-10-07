# Como rodar a demo na apresentação (projetor)

> Guia operacional para o **João** conduzir a demonstração da **Pergunta 5** no projetor,
> sem digitar na frente da turma e com controle total do ritmo.

---

## 1. Antes de sair de casa (checklist)

- [ ] Notebook carregado + cabo **HDMI/VGA** + adaptador se precisar.
- [ ] Internet de backup: **hotspot do celular** (caso o Wi-Fi da sala caia).
- [ ] Ter o repositório clonado e atualizado:

```bash
git checkout feat/seminario-redes-aws
git pull origin feat/seminario-redes-aws
```

- [ ] Rodar o **pré-flight** uma vez para confirmar que tudo responde (ver `04-demonstracao.md`).
- [ ] **Prints de segurança** (plano B) já salvos numa pasta:
  - console OCI (VCN / subnet / Security List);
  - terminal com os curls já rodados (site `200`, back-end e banco `timeout`).

---

## 2. Configurar o terminal para o projetor

O segredo da demo é **legibilidade**. Faça antes de conectar no projetor:

1. Abra um terminal e rode: `git pull` (item acima) para ter o script em mãos.
2. **Aumente a fonte**: `Ctrl` + `+` até ficar grande (≈ 18–20 pt). No projetor, fonte pequena some.
3. Use **tema escuro** (as cores do script — verde/amarelo — aparecem melhor em fundo escuro).
4. **Maximize** a janela (F11 / tela cheia).
5. Deixe o comando **já digitado**, sem dar Enter ainda:

```bash
./scripts/demo-rede.sh
```

> Dica: abra **duas abas** do terminal — uma para a demo, outra já aberta no console OCI
> (navegador) para o passo do Security List.

---

## 3. Conectando no projetor

1. Conecte o cabo HDMI/VGA.
2. Selecione **"Estender"** ou **"Duplicar"** tela (tecla `Win` + `P` no Windows / config no Mac).
   - Prefira **duplicar** para você ver exatamente o que a turma vê.
3. Ajuste a **resolução** se a imagem cortar.
4. Confirme que o terminal está legível do fundo da sala antes de começar.

---

## 4. Roteiro da demo ao vivo (o que apertar e o que falar)

O script **pausa a cada passo** e espera você apertar `Enter`. Use isso para narrar.

| Ação | Você faz | O que aparece | Você fala |
|---|---|---|---|
| Iniciar | `./scripts/demo-rede.sh` + Enter | Banner da demo | "Vou provar que nossa rede só libera o necessário." |
| Passo 1 | Enter | `Site -> HTTP 200` (verde) | "O site está no ar pela internet, entrando pelo Cloudflare Tunnel." |
| Passo 2 | Enter | `Back-end :5000 BLOQUEADO` (amarelo) | "O back-end NÃO é acessível de fora. Está isolado." |
| Passo 3 | Enter | `Banco :27017 BLOQUEADO` (amarelo) | "O banco também não. Ninguém chega nele pela internet." |
| Passo 4 | Enter | `SSH :22 aberto` (verde) | "Só a porta de gerenciamento (SSH) está aberta." |
| Resumo | — | Tabela resumida | "Tudo bloqueado, exceto o necessário." |
| Fechamento | — | — | "É o mesmo princípio de VPC + Subnets + Security Groups na AWS." |

**Duração total:** ~3 min (30–40s por passo + narração).

### Ritmo (como controlar)

- **Interativo (padrão):** o script espera o `Enter`. Você decide quando avançar.
- **Automático:** se preferir não tocar no teclado, rode `AUTO=1 SLEEP=4 ./scripts/demo-rede.sh`
  (avança sozinho a cada 4s — use só se estiver bem ensaiado).

---

## 5. Mostrar o "porquê" (console OCI + Terraform)

Depois do script, troque para a **outra aba/aba do navegador** e mostre:

**Opção A — Console OCI (rápida):**
- Abra **VCN → Security List** e mostre que só **SSH 22** está liberado (e o resto não tem regra).
- Fale: "essa regra é o que acabamos de ver bloqueando back-end e banco."

**Opção B — Terraform (mais impacto, mostra que a infra é código):**

```bash
cd terraform
terraform plan
```

- Mostra `No changes` e comprova que a regra de segurança é código versionado.
- Abra o `vcn.tf` e aponte o bloco `ingress_security_rules { ... 22 ... }`.
- Fale: "a mesma lógica de Security Group, só que declarada em código."

> **NÃO rode `terraform apply` ao vivo** — é lento, precisa de credencial OCI e, se houver
> mudança pendente, pode alterar/re criar recursos e derrubar o app que está no ar.

---

## 6. Plano B (se a internet cair no palco)

1. Não entre em pânico — você tem os **prints** do item 1.
2. Projete o print do terminal com os resultados (site 200 / back-end e banco bloqueados).
3. Projete o print do Security List (só SSH 22).
4. Conte exatamente a mesma história — a narrativa não muda, só troca "ao vivo" por "evidência".

**Alternativa:** mostre o log da **execução do workflow** (`Actions → Demo — Isolamento de rede`),
que é a prova reproduzível rodada no GitHub Actions.

---

## 7. Checklist final (2 min antes de subir)

- [ ] Terminal em tela cheia, fonte grande, fundo escuro.
- [ ] Comando `./scripts/demo-rede.sh` já digitado (sem Enter).
- [ ] Aba/navegador com o Security List aberto.
- [ ] Prints de backup num atalho fácil.
- [ ] Celular com hotspot ligado, se necessário.
- [ ] Timer visível (celular ou relógio) para não passar de ~3 min.
