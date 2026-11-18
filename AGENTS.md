# AGENTS.md — Diário de Leituras (Flutter, Android)

## 0. Como trabalhar (leia antes de qualquer ação)
Este documento é a fonte da verdade. Você executa o projeto **uma etapa por vez**, seguindo a seção 9, e **só avança quando a pessoa autorizar**.

**Ao iniciar uma etapa**
1. Diga em 2 ou 3 linhas o que vai fazer nela.
2. Implemente somente o que a etapa pede. Não adiante etapas futuras, não adicione funcionalidades nem dependências que não estejam neste documento sem perguntar antes.

**Ao concluir uma etapa**
1. Se mexeu no banco, rode `dart run build_runner build --delete-conflicting-outputs`.
2. Rode `flutter analyze` e `flutter test`. Corrija todo erro e aviso antes de seguir.
3. Faça um commit no Git com a mensagem `etapa N: descrição curta`. Na etapa 1, rode `git init` se ainda não houver repositório.
4. Entregue um relatório curto com: o que foi feito, os principais arquivos criados ou alterados, como testar no celular (`flutter run`), o que a pessoa deve conferir à mão e qualquer decisão que você tomou ou pendência que ficou.
5. **Pare e pergunte:** "Etapa N concluída. Posso seguir para a etapa N+1?" Não comece a próxima etapa sem uma resposta afirmativa.

**Durante todo o projeto**
- Se algo for ambíguo, ou contradisser este documento, pergunte. Não invente regras.
- Se a pessoa relatar um problema, corrija dentro da etapa atual e repita o fluxo de conclusão antes de avançar.
- Se a pessoa mudar uma decisão (campos, regras, telas), atualize este `AGENTS.md` primeiro e depois ajuste o código, para o documento e o app nunca se contradizerem.
- Não faça estilização nesta fase (veja a seção 2).

## 1. Objetivo
App pessoal, 100% offline, para registrar obras (livros, artigos e outros textos), fichá-las, escrever análises em formato de artigo e acompanhar estatísticas de leitura. Idioma da interface: português do Brasil. Plataforma-alvo: Android.

## 2. Escopo desta fase
- Construir a **estrutura base**: banco de dados, modelos, navegação, telas funcionais e estatísticas.
- **Não estilizar.** Use o tema Material 3 padrão, sem cores, fontes ou ilustrações customizadas. Concentre todo o tema em `lib/core/theme.dart` para a fase de estilização posterior.
- Fora de escopo: contas, nuvem, sincronização, notificações, busca em APIs externas de livros.

## 3. Stack
- Flutter estável mais recente, Dart null-safe, Material 3.
- Banco: **SQLite com Drift** (`drift`, `drift_flutter`, `drift_dev`, `build_runner`).
- Estado: **Riverpod** (`flutter_riverpod`), sem geração de código para os providers. Prefira `StreamProvider` sobre as queries reativas do Drift.
- Navegação: `go_router` com `StatefulShellRoute` e barra de navegação inferior.
- Gráficos: `fl_chart`.
- Backup: `file_picker`, `share_plus`, `path_provider`.
- Formatação de datas e números: `intl` com locale `pt_BR`.
- Use as versões estáveis mais recentes compatíveis entre si. Se uma API divergir deste documento, siga a documentação oficial do pacote.
- Este projeto substitui qualquer protótipo anterior que use `shared_preferences`.

## 4. Estrutura de pastas
```
lib/
  main.dart
  app.dart                  # MaterialApp.router, locale, tema
  core/
    theme.dart              # único lugar de estilo
    router.dart
    formatters.dart
  data/
    database.dart           # tabelas Drift + DAOs
    backup_service.dart     # exportar/importar JSON
  features/
    works/                  # aba Obras
    notes/                  # aba Fichamentos
    analyses/               # aba Análises
    stats/                  # aba Estatísticas
```
Cada feature tem `*_screen.dart`, `*_form.dart` (quando houver edição) e `*_providers.dart`. Nenhuma tela acessa o banco direto: sempre via provider.

## 5. Modelo de dados (Drift)
Datas guardadas como `DateTime`. IDs inteiros autoincrementais.

| Tabela | Campos |
|---|---|
| `works` | id, type (`livro`/`artigo`/`outro`), title, author, genre, year?, pages?, status (`quero_ler`/`lendo`/`lido`), rating? (0.5 a 5, passos de 0,5), startedAt?, finishedAt?, createdAt |
| `reading_sessions` | id, workId → works (cascade), date, pagesRead, note? |
| `notes` (fichamento) | id, workId → works (cascade), label (ex.: "Cap. 3" ou "Releitura 2024"), summary, thesis, concepts, critique, createdAt, updatedAt |
| `quotes` | id, noteId → notes (cascade), text, page?, comment? |
| `analyses` | id, title, body, createdAt, updatedAt |
| `analysis_works` | analysisId → analyses (cascade), workId → works (cascade), chave primária composta |

Regras:
- Uma obra tem **vários** fichamentos. Cada fichamento tem campos fixos **e** uma lista de citações.
- Uma análise é texto livre com título. O vínculo com obras é **opcional** e pode ser com várias.
- Ao mudar o status para `lido`, preencha `finishedAt` com a data atual (editável). Ao mudar para `lendo` pela primeira vez, preencha `startedAt`.
- `pagesRead` deve ser > 0. Se a obra tiver `pages`, avise (sem bloquear) quando a soma das sessões passar do total.
- Gêneros são texto livre, com sugestão automática dos já usados.
- Habilite `PRAGMA foreign_keys = ON`.

### Sequência diária (streak)
Não tem tabela própria: é sempre calculada a partir de `reading_sessions`.
- Um dia conta como "lido" se tiver ao menos uma sessão com `pagesRead` > 0. Use a data local do aparelho (considere só ano, mês e dia).
- **Sequência atual:** quantidade de dias consecutivos lidos até hoje. Se hoje ainda não tem sessão, a sequência **não zera**: ela continua contando a partir de ontem e é marcada como "em risco" até o fim do dia. Só zera quando passa um dia inteiro sem leitura.
- **Maior sequência:** maior série de dias consecutivos já registrada.
- Como as sessões podem ser registradas com data passada, editar ou apagar uma sessão recalcula a sequência.

## 6. Telas (barra inferior com 4 abas)
1. **Obras**
   - Lista com filtros por status, tipo e gênero e busca por título ou autor.
   - Cada item mostra título, autor, tipo, status e nota.
   - Formulário de criar/editar com todos os campos.
   - Detalhe da obra: dados, progresso (soma das sessões ÷ páginas), botão "Registrar sessão", lista de sessões, fichamentos e análises vinculadas, e ação de excluir com confirmação.
   - No topo da aba Obras, mostrar um indicador compacto da sequência atual (ex.: "5 dias seguidos") e, se hoje ainda não tiver leitura, o aviso "Leia hoje para manter a sequência". Tocar nele abre a aba Estatísticas.
2. **Fichamentos**
   - Lista de todos os fichamentos, agrupados por obra, com busca.
   - Formulário: escolher obra, rótulo, resumo, tese, conceitos, crítica e adicionar/remover citações (texto, página, comentário).
3. **Análises**
   - Lista por data de atualização, com busca por título.
   - Editor: título, texto livre multilinha e seleção opcional de obras vinculadas.
   - Salvar automaticamente ao sair da tela. Pedir confirmação antes de excluir.
4. **Estatísticas**
   - **Sequência diária:** sequência atual (com o estado "em risco" quando hoje ainda não tem leitura), maior sequência e um calendário do mês com os dias lidos marcados, navegável entre meses.
   - Obras por status, por tipo e por gênero (gráficos de barra ou pizza).
   - Páginas lidas por mês e por ano (soma de `reading_sessions.pagesRead`), com alternância mês/ano.
   - Nota média por gênero e por autor (ignorar obras sem nota; mostrar a quantidade de obras usada).
   - Obras concluídas por mês e por ano (usa `finishedAt`).
   - Seletor de período. Estados vazios com mensagem curta indicando o que registrar.

Configurações (ícone na barra superior da aba Obras): exportar e importar dados.

## 7. Backup
- **Exportar:** gerar um arquivo `.json` com todas as tabelas e um campo `version`, e abrir o diálogo de compartilhamento do Android.
- **Importar:** escolher um `.json`, validar `version` e estrutura, mostrar o resumo (quantidade de obras, fichamentos, análises) e pedir confirmação. A importação **substitui** os dados atuais dentro de uma única transação; em caso de erro, nada muda.

## 8. Convenções
- Todas as strings da interface em pt-BR, centralizadas para facilitar ajustes.
- Validação nos formulários: título obrigatório na obra e na análise; ano entre 0 e o ano atual; páginas e nota positivas.
- Toda exclusão destrutiva pede confirmação.
- Sem `print` em código final; trate erros de banco e de arquivo com mensagem para a pessoa.
- Testes: unitários para as queries de estatística, para exportar/importar (ida e volta sem perda) e para o cálculo da sequência (sem leitura, só hoje, só ontem, buraco no meio, virada de mês e de ano, sessões com data passada, sessão apagada).

## 9. Ordem de implementação
1. Projeto, dependências, tema padrão, rotas e as quatro abas vazias.
2. Banco Drift (tabelas, DAOs, migração inicial) e providers.
3. Obras: lista, formulário, detalhe e sessões de leitura.
4. Fichamentos e citações.
5. Análises e vínculo com obras.
6. Estatísticas, incluindo a sequência diária e o indicador na aba Obras.
7. Exportar e importar JSON.
8. Testes e revisão dos estados vazios e de erro.

## 10. Critérios de aceite
- `flutter analyze` sem avisos e `flutter build apk --release` conclui sem erro.
- Todos os dados persistem após fechar e reabrir o app, sem internet.
- Exportar e importar em seguida reproduz exatamente os mesmos dados.
- A sequência atual e a maior sequência batem com as sessões registradas e se atualizam ao adicionar, editar ou apagar uma sessão.
- Excluir uma obra remove suas sessões e fichamentos e desfaz os vínculos com análises, sem apagar as análises.
