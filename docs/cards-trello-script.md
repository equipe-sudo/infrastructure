# Script para Criação Automática dos Cards no Trello

Após autorizar o Trello MCP no VS Code, execute um a um:

## FASE 1 — Infraestrutura (João Pedro)
1. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Provisionar VCN e Subnet (Terraform)', descrição 'Criar código Terraform para VCN pública com subnet, security list (portas 22, 80, 443) e Internet Gateway', prioridade alta"
2. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Provisionar VM A1.Flex (Terraform)', descrição 'VM.Standard.A1.Flex com 2 OCPU e 12 GB RAM, Oracle Linux, chave SSH', prioridade alta"
3. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Configurar Docker e dependências (Ansible)', descrição 'Playbook Ansible para instalar Docker, Docker Compose, Python e git na VM', prioridade alta"
4. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Configurar Object Storage para estado do Terraform', descrição 'Criar bucket S3-compatible no OCI para backend remoto do Terraform', prioridade média"
5. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Subir PostgreSQL + backend + frontend (Docker Compose)', descrição 'Criar docker-compose.yml com PostgreSQL, backend e frontend com Nginx como reverse proxy', prioridade alta"
6. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Testar acesso público à aplicação', descrição 'Validar URL pública, portas abertas e latência da aplicação', prioridade média"
7. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Criar diagrama da arquitetura Cloud', descrição 'Diagrama draw.io/Excalidraw mostrando VCN, VM, containers, Object Storage e fluxo de comunicação', prioridade média"
8. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Documentar justificativas técnicas', descrição 'Documento com justificativa de cada escolha: OCI Always Free, A1.Flex, Docker, PostgreSQL', prioridade média"

## FASE 2 — Aplicação Backend (Allan + Josi)
9. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Definir framework e estrutura do backend', descrição 'Escolher FastAPI ou Flask, criar estrutura de pastas, requirements.txt', prioridade alta"
10. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Desenvolver models e entidades ORM', descrição 'Criar classes SQLAlchemy mapeando as entidades do sistema', prioridade alta"
11. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Desenvolver rotas e endpoints da API', descrição 'CRUD completo com validação e tratamento de erros', prioridade alta"
12. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Configurar conexão com PostgreSQL', descrição 'String de conexão via variável de ambiente, testar conectividade', prioridade alta"
13. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Testar endpoints localmente', descrição 'Testar todas as rotas com Postman/Insomnia', prioridade média"
14. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Containerizar backend (Dockerfile)', descrição 'Dockerfile otimizado para a API Python', prioridade média"
15. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Documentar API com Swagger/OpenAPI', descrição 'Documentação automática dos endpoints', prioridade baixa"

## FASE 3 — Frontend (Allan + Josi)
16. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Definir tecnologia do frontend', descrição 'Escolher React, Vue.js ou HTML/CSS/JS puro, decidir com o grupo', prioridade alta"
17. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Criar estrutura do projeto frontend', descrição 'Scaffold inicial com dependências básicas', prioridade alta"
18. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Desenvolver tela principal da aplicação', descrição 'Página inicial com navegação e listagem dos dados', prioridade alta"
19. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Desenvolver formulários CRUD', descrição 'Telas de criar, editar e visualizar registros consumindo API', prioridade alta"
20. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Integrar frontend com API backend', descrição 'Chamadas HTTP para todos os endpoints', prioridade alta"
21. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Containerizar frontend (Dockerfile + Nginx)', descrição 'Dockerfile com Nginx servindo arquivos estáticos', prioridade média"
22. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Testar fluxo completo do usuário', descrição 'Navegação ponta a ponta: entrar, listar, criar, editar, excluir', prioridade média"

## FASE 4 — Banco de Dados (Allan + Josi)
23. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Modelar entidades e relacionamentos (DER)', descrição 'Diagrama Entidade-Relacionamento com tabelas, colunas e chaves', prioridade alta"
24. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Criar script SQL de schema', descrição 'CREATE TABLEs com constraints, índices e tipos adequados', prioridade alta"
25. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Criar script de seed data', descrição 'Dados de exemplo realistas para teste da aplicação', prioridade alta"
26. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Configurar volume persistente no Docker', descrição 'Garantir que dados sobrevivam a restart do container', prioridade alta"
27. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Validar persistência pós-restart', descrição 'Parar container, remover, subir de novo — dados intactos?', prioridade média"
28. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Documentar dicionário de dados', descrição 'Descrição de cada tabela, coluna, tipo e restrição', prioridade baixa"

## FASE 5 — Gestão e Documentação (Fernanda + Thiago)
29. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Cadastrar cards no BACKLOG do Trello', descrição 'Importar todas as atividades do projeto para o Trello', prioridade alta"
30. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Priorizar atividades com a equipe', descrição 'Revisar dependências: infra primeiro, backend depois, frontend por último', prioridade alta"
31. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Criar relatório de andamento', descrição 'Documento listando: concluído, em desenvolvimento, dificuldades e próximos passos', prioridade alta"
32. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Coletar evidências (prints e vídeo)', descrição 'Print da aplicação, kanban, repositórios; vídeo de até 5 minutos', prioridade alta"
33. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Organizar apresentação final', descrição 'Roteiro: quem fala o que, ordem e ensaio geral com o grupo', prioridade alta"
34. "Crie um card no Trello no board 'Equipe SUDO', lista BACKLOG, com título 'Validar entrega antes do prazo', descrição 'Checklist: app no ar, docs prontos, evidências coletadas, kanban atualizado', prioridade alta"
