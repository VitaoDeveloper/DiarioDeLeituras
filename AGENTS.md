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
- Não faça estilização antes da etapa 9 (veja as seções 2 e 11).

## 1. Objetivo
App pessoal, 100% offline, para registrar obras (livros, artigos e outros textos), fichá-las, escrever análises em formato de artigo e acompanhar estatísticas de leitura. Idioma da interface: português do Brasil. Plataforma-alvo: Android.

## 2. Escopo desta fase
- Construir a **estrutura base**: banco de dados, modelos, navegação, telas funcionais e estatísticas.
- **Não estilizar.** Use o tema Material 3 padrão, sem cores, fontes ou ilustrações customizadas. Concentre todo o tema em `lib/core/theme.dart` para a fase de estilização (seção 11, etapas 9 a 13).
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
9. Estilização: fontes, tokens e `theme.dart` (seção 11).
10. Estilização das telas de Obras (lista, formulário, detalhe).
11. Estilização de Fichamentos e Análises.
12. Estilização de Estatísticas e da sequência diária.
13. Revisão visual: tema escuro, texto ampliado, contraste e consistência.

## 10. Critérios de aceite
- `flutter analyze` sem avisos e `flutter build apk --release` conclui sem erro.
- Todos os dados persistem após fechar e reabrir o app, sem internet.
- Exportar e importar em seguida reproduz exatamente os mesmos dados.
- A sequência atual e a maior sequência batem com as sessões registradas e se atualizam ao adicionar, editar ou apagar uma sessão.
- Excluir uma obra remove suas sessões e fichamentos e desfaz os vínculos com análises, sem apagar as análises.

## 11. Estilização (etapas 9 a 13)
Só comece quando a pessoa autorizar a etapa 9. O fluxo da seção 0 continua valendo: uma etapa por vez, `flutter analyze` e testes, commit e pergunta antes de avançar.

### Direção
Biblioteca clássica: serifas, papel e tinta, neutros levemente quentes e **um único acento carmesim escuro**. Sóbrio, silencioso, sem ornamentos. Tema claro e escuro com `ThemeMode.system`.

### Regras gerais
- Todo estilo vive em `lib/core/theme.dart` (e `lib/core/tokens.dart`, se quiser separar as constantes). Telas e widgets **não** podem ter cores, tamanhos de fonte ou raios fixos no código: usam `Theme.of(context)` e os tokens.
- Monte o `ColorScheme` explicitamente com os valores abaixo. Não use `ColorScheme.fromSeed`.
- Crie `ThemeData buildTheme(Brightness b)` e configure `useMaterial3: true`.
- Zere o tom de superfície do Material 3 (`surfaceTintColor: Colors.transparent`) e use elevação 0 em todo o app. Separe elementos com bordas finas de 1 px na cor `outline`.

### Cores
| Token | Claro | Escuro |
|---|---|---|
| `background` (papel) | `#F4F1EB` | `#1C1A18` |
| `surface` (cartões) | `#FBF9F5` | `#25221F` |
| `surfaceVariant` (campos, chips) | `#ECE7DE` | `#2F2B27` |
| `outline` | `#CFC8BB` | `#433E38` |
| `onBackground` / texto | `#24211E` | `#EDE8DF` |
| `onSurfaceVariant` / texto secundário | `#6B645B` | `#A39B8F` |
| `accent` (primary) | `#7A1B2C` | `#D98591` |
| `onAccent` | `#FBF9F5` | `#1C1A18` |
| `error` | `#9B2C2C` | `#E08A8A` |

Uso do acento, **somente** em:
- ações principais (`FilledButton`, FAB, indicador da aba ativa);
- sequência diária (indicador, calendário, estado atual);
- nota por estrelas.

Todo o resto é neutro: chips de status e tipo (contorno neutro; "lido" com preenchimento neutro `surfaceVariant`), barras de progresso (cor do texto sobre trilho `surfaceVariant`), ícones e divisores. Nunca comunique algo só pela cor.

### Tipografia
- Família única: **Literata**, em todo o app, **embutida como asset** (o app é offline; não use `google_fonts` em tempo de execução). Baixe a fonte em fonts.google.com/specimen/Literata (licença OFL) e adicione ao projeto os arquivos estáticos Regular (400), Medium (500), SemiBold (600) e Italic (400) em `assets/fonts/`, declarados no `pubspec.yaml`.
- Mapeie no `TextTheme`:
  - `headlineSmall` 24/32, peso 600 (títulos de tela e de obra);
  - `titleLarge` 20/28, peso 600 · `titleMedium` 16/24, peso 600 (títulos de cartão);
  - `bodyLarge` 16/24 (texto padrão) · `bodyMedium` 14/20 · `bodySmall` 12/16 (metadados, cor secundária);
  - `labelLarge` 14/20, peso 500 (botões e abas).
- Textos longos (campos de fichamento, citações e editor de análise) usam 17/28 (altura 1,6), com `Italic` nas citações. Limite a largura do texto a cerca de 65 caracteres em telas largas.
- Respeite a escala de texto do sistema; nenhuma tela pode quebrar com escala 1,3.

### Forma, espaço e componentes
- Raio: 8 px em cartões, botões, campos e chips; 12 px em diálogos e folhas inferiores.
- Espaçamento em múltiplos de 8: margem lateral de tela 16, padding interno de cartão 16, intervalo entre cartões 12, altura mínima de linha de lista 56. Áreas de toque de pelo menos 48 px.
- Barra superior plana, sem tom ao rolar, título em `titleLarge`. Barra de navegação inferior com indicador em `accent` suave e ícones contornados (`*_outlined`).
- Campos de texto preenchidos com `surfaceVariant`, sem sublinhado, borda `outline` de 1 px e, em foco, borda `accent` de 1,5 px.
- Divisores finos em `outline`. Snackbars e diálogos nas cores de `surface`.
- Estados vazios: ícone contornado neutro, uma frase curta em `bodyLarge` e, quando fizer sentido, um botão de ação.

### Elementos específicos
- **Nota:** estrelas (meia estrela suportada), preenchidas em `accent` e vazias em `outline`.
- **Sequência diária:** indicador compacto na aba Obras. "Em risco" (hoje sem leitura) usa contorno em `accent` sem preenchimento; "mantida" usa preenchimento `accent` com `onAccent`.
- **Calendário do mês:** dia lido = círculo preenchido em `accent`; hoje = círculo com contorno; demais dias sem decoração.
- **Gráficos (`fl_chart`):** barras em cor de texto com tons neutros; o período atual (mês ou ano corrente) em `accent`. Evite pizza: use barras horizontais ordenadas, com rótulos e valores escritos. Eixos e grades em `outline`, rótulos em `bodySmall`.
- **Editor de análise e de fichamento:** sem barra de ferramentas colorida; título em `headlineSmall`, corpo em texto longo, e salvamento automático discreto ("Salvo") em texto secundário.

### Critérios de aceite da estilização
- Nenhuma cor, tamanho de fonte ou raio fixo fora de `theme.dart`/`tokens.dart` (verifique com busca por `Color(`, `Colors.` e `fontSize:` nas telas).
- Tema claro e escuro funcionam e trocam com o sistema, sem texto ilegível em nenhuma tela.
- Contraste de texto e de controles de pelo menos 4,5:1 (3:1 para ícones e bordas de componentes).
- Todas as telas funcionam com escala de texto 1,3 sem estouro.
- Com o app em uso, a única cor viva é o acento carmesim, nos lugares listados acima.