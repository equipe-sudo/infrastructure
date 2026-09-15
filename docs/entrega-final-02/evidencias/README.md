# Evidências — Entrega Final 02

Coloque aqui as capturas de tela e saídas usadas como prova dos testes (seção 11 do
[README da entrega](../README.md)).

## Nome dos arquivos

| Arquivo | Evidência |
|---|---|
| `E1-uso-normal.png` | Aplicação usada pelo domínio (criar/listar/concluir/excluir) |
| `E1-paineis-3-5-6.png` | Painéis 3, 5 e 6 refletindo a operação |
| `E2-volume.png` | Painéis 4 e 5 após gerar volume de requisições |
| `E3-falha-aplicacao-http400.png` | Painel 4 com 4xx no período do teste |
| `E3-falha-aplicacao-painel8.png` | Painel 8 mostrando o log `todos.create.invalid` |
| `E4-falha-banco-painel7.png` | Painel 7 com falhas > 0 % |
| `E4-falha-banco-painel8.png` | Painel 8 com o erro de conexão |
| `E5-disponibilidade-paineis-1-2.png` | Painéis 1 e 2 com 100 % e barras verdes |
| `E6-docker-ps.png` | `docker compose ps` nas duas VMs |
| `E6-security-list.png` | Security List da observabilidade no console OCI |

## O que registrar em cada captura

Cenário, **data e hora**, **período selecionado no painel** e conclusão.
Um mesmo cenário pode validar mais de um painel, desde que a relação seja explicada.

## Prova do caminho evento → log → painel

Em uma captura do painel 8, destaque o `request_id` de uma linha de erro. Em outra captura,
mostre o mesmo `request_id` na saída de `docker logs todo-backend` na VM da aplicação.
Isso comprova o caminho *geração → coleta → armazenamento → painel*.

> Não use dados fictícios. Restaure o ambiente normal após os testes (`docker compose start mongo`).
