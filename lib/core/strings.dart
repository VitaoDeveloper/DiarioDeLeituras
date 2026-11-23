abstract final class AppStrings {
  static const String appTitle = 'Diário de Leituras';
  static const String works = 'Obras';
  static const String notes = 'Fichamentos';
  static const String analyses = 'Análises';
  static const String stats = 'Estatísticas';

  static const String settings = 'Configurações';
  static const String exportData = 'Exportar dados';
  static const String importData = 'Importar dados';
  static const String importTitle = 'Importar dados';
  static const String importConfirmation =
      'Os dados atuais serão substituídos pelos dados do arquivo. '
      'Esta ação não pode ser desfeita.';
  static const String exportSuccess = 'Arquivo compartilhado.';
  static const String importSuccess = 'Dados importados.';
  static const String exportError = 'Não foi possível exportar os dados.';
  static const String importError = 'Não foi possível importar os dados.';
  static const String invalidJson =
      'Arquivo inválido: não é um JSON de backup.';
  static const String invalidBackup = 'Arquivo de backup inválido.';
  static const String unsupportedVersion = 'Versão de backup não suportada.';
  static const String noteSingular = 'fichamento';
  static const String notePlural = 'fichamentos';
  static const String analysisSingular = 'análise';
  static const String analysisPlural = 'análises';

  static String noteCountLabel(int count) =>
      '$count ${count == 1 ? noteSingular : notePlural}';

  static String analysisCountLabel(int count) =>
      '$count ${count == 1 ? analysisSingular : analysisPlural}';

  static String importSummary(
    int works,
    int readings,
    int notes,
    int analyses,
  ) =>
      '${workCountLabel(works)}\n'
      '${readingCountLabel(readings)}\n'
      '${noteCountLabel(notes)}\n'
      '${analysisCountLabel(analyses)}';

  static const String currentStreak = 'Sequência atual';
  static const String bestStreak = 'Maior sequência';
  static const String streakDaySingular = 'dia seguido';
  static const String streakDaysPlural = 'dias seguidos';
  static const String streakAtRisk = 'Em risco';
  static const String readTodayHint = 'Leia hoje para manter a sequência';
  static const String noStreak = 'Nenhuma leitura registrada ainda.';
  static const String calendar = 'Calendário de leitura';
  static const String statusChart = 'Leituras por status';
  static const String typeChart = 'Obras por tipo';
  static const String genreChart = 'Obras por gênero';
  static const String pagesChart = 'Páginas lidas';
  static const String completedChart = 'Leituras concluídas';
  static const String ratingByGenre = 'Nota média por gênero';
  static const String ratingByAuthor = 'Nota média por autor';
  static const String granularityDay = 'Dia';
  static const String periodMonth = 'Mês';
  static const String periodYear = 'Ano';
  static const String previousPeriod = 'Período anterior';
  static const String nextPeriod = 'Próximo período';
  static const String workSingular = 'obra';
  static const String workPlural = 'obras';
  static const List<String> weekdayInitials = [
    'seg',
    'ter',
    'qua',
    'qui',
    'sex',
    'sáb',
    'dom',
  ];
  static const String emptyWorksChart = 'Cadastre obras para ver este gráfico.';
  static const String emptyReadingsChart =
      'Cadastre uma leitura para ver este gráfico.';
  static const String emptySessionsChart =
      'Registre sessões de leitura para ver este gráfico.';
  static const String emptyFinishedChart =
      'Marque uma leitura como lida para ver este gráfico.';
  static const String emptyRatingsChart =
      'Avalie leituras para ver este gráfico.';
  static const String emptyPeriod = 'Nenhum dado neste período.';

  // Resumo e tooltips dos gráficos de estatísticas.
  static const String chartTotalLabel = 'Total';
  static const String chartItemCountLabel = 'Itens';
  static const String showAll = 'Ver todos';
  static const String showLess = 'Ver menos';
  static const String pageSingular = 'página';
  static const String pagePlural = 'páginas';

  static String chartSummary(String label, String value) => '$label: $value';

  static String pageCountLabel(int count) =>
      '$count ${count == 1 ? pageSingular : pagePlural}';

  static String streakLabel(int count) =>
      '$count ${count == 1 ? streakDaySingular : streakDaysPlural}';

  static String workCountLabel(int count) =>
      '$count ${count == 1 ? workSingular : workPlural}';

  static const String newWork = 'Nova obra';
  static const String editWork = 'Editar obra';
  static const String workDetails = 'Detalhes da obra';
  static const String invalidWork = 'Obra não encontrada.';

  static const String searchWorks = 'Buscar por título ou autor';
  static const String all = 'Todos';
  static const String statusFilter = 'Status';
  static const String typeFilter = 'Tipo';
  static const String genreFilter = 'Gênero';

  static const String title = 'Título';
  static const String author = 'Autor';
  static const String type = 'Tipo';
  static const String genre = 'Gênero';
  static const String year = 'Ano';
  static const String pages = 'Páginas';
  static const String status = 'Status';
  static const String rating = 'Nota';
  static const String noRating = 'Sem nota';
  static const String startedAt = 'Início da leitura';
  static const String finishedAt = 'Fim da leitura';
  static const String createdAt = 'Cadastrado em';

  static const String typeLivro = 'Livro';
  static const String typeArtigo = 'Artigo';
  static const String typeOutro = 'Outro';
  static const String statusQueroLer = 'Quero ler';
  static const String statusLendo = 'Lendo';
  static const String statusLido = 'Lido';

  static const String save = 'Salvar';
  static const String cancel = 'Cancelar';
  static const String edit = 'Editar';
  static const String delete = 'Excluir';
  static const String confirm = 'Confirmar';
  static const String chooseDate = 'Escolher data';
  static const String clearDate = 'Limpar data';

  static const String requiredTitle = 'Informe o título.';
  static const String invalidYear = 'Ano inválido.';
  static const String invalidPages = 'Informe um número de páginas positivo.';
  static const String invalidRating = 'A nota deve estar entre 0,5 e 5.';
  static const String invalidPagesRead =
      'Informe uma quantidade de páginas lidas positiva.';

  static const String noWorks = 'Nenhuma obra cadastrada.';
  static const String noWorksFilter = 'Nenhuma obra com esses filtros.';
  static const String noRatingValue = '—';
  static const String genreSuggestions = 'Gêneros já usados';

  static const String readingSingular = 'leitura';
  static const String readingPlural = 'leituras';

  static String readingCountLabel(int count) =>
      '$count ${count == 1 ? readingSingular : readingPlural}';

  static String readingLabel(int number) => '$numberª leitura';

  static const String readings = 'Leituras';
  static const String newReading = 'Nova leitura';
  static const String editReading = 'Editar leitura';
  static const String noReadings = 'Nenhuma leitura registrada.';
  static const String readingSaved = 'Leitura salva.';
  static const String readingAdded = 'Leitura registrada.';
  static const String readingFieldsHint =
      'Status, nota e datas são registrados em cada leitura nos detalhes da obra.';
  static const String deleteReadingTitle = 'Excluir leitura?';
  static const String deleteReadingBody =
      'As sessões desta leitura também serão removidas. As demais leituras '
      'da obra serão mantidas.';
  static const String lastReadingError =
      'Não é possível excluir a única leitura da obra.';

  static const String readingSessions = 'Sessões de leitura';
  static const String registerSession = 'Registrar sessão';
  static const String editSession = 'Editar sessão';
  static const String sessionDate = 'Data';
  static const String pagesRead = 'Páginas lidas';
  static const String sessionNote = 'Observação';
  static const String noSessions = 'Nenhuma sessão registrada.';
  static const String progress = 'Progresso';
  static const String pagesProgress = 'Páginas lidas de';
  static const String pagesWithoutTotal = 'páginas lidas';
  static const String pagesOverflow =
      'As sessões somam mais páginas do que o total da obra.';
  static const String pagesOverflowValidation =
      'A soma das páginas não pode ultrapassar o total da obra.';

  static const String linkedNotes = 'Fichamentos desta obra';
  static const String linkedAnalyses = 'Análises desta obra';
  static const String linkedWorks = 'Obras vinculadas';
  static const String noLinkedNotes = 'Nenhum fichamento vinculado.';
  static const String noLinkedAnalyses = 'Nenhuma análise vinculada.';

  static const String newAnalysis = 'Nova análise';
  static const String editAnalysis = 'Editar análise';
  static const String invalidAnalysis = 'Análise não encontrada.';
  static const String searchAnalyses = 'Buscar análises';
  static const String analysisBody = 'Texto';
  static const String autoSaveHint =
      'As alterações são salvas ao sair da tela.';
  static const String noAnalyses = 'Nenhuma análise cadastrada.';
  static const String noAnalysesFilter = 'Nenhuma análise com esse título.';
  static const String analysisSaved = 'Análise salva.';
  static const String analysisDeleted = 'Análise excluída.';
  static const String deleteAnalysisTitle = 'Excluir análise?';
  static const String deleteAnalysisBody =
      'Os vínculos com obras também serão removidos. As obras não serão apagadas.';

  static const String newNote = 'Novo fichamento';
  static const String editNote = 'Editar fichamento';
  static const String invalidNote = 'Fichamento não encontrado.';
  static const String searchNotes = 'Buscar fichamentos';
  static const String noteWork = 'Obra';
  static const String selectWork = 'Selecione uma obra.';
  static const String label = 'Rótulo';
  static const String summary = 'Resumo';
  static const String thesis = 'Tese';
  static const String concepts = 'Conceitos';
  static const String critique = 'Crítica';
  static const String updatedAt = 'Atualizado em';
  static const String quoteText = 'Texto da citação';
  static const String quotePage = 'Página';
  static const String quoteComment = 'Comentário';
  static const String quotes = 'Citações';
  static const String addQuote = 'Adicionar citação';
  static const String removeQuote = 'Remover citação';
  static const String requiredQuoteText = 'Informe o texto da citação.';
  static const String noteWithoutLabel = '(sem rótulo)';
  static const String noSummary = 'Sem resumo.';
  static const String noNotes = 'Nenhum fichamento cadastrado.';
  static const String noNotesFilter = 'Nenhum fichamento com essa busca.';
  static const String needWorkForNote =
      'Cadastre uma obra antes de criar um fichamento.';
  static const String noteSaved = 'Fichamento salvo.';
  static const String noteDeleted = 'Fichamento excluído.';
  static const String deleteNoteTitle = 'Excluir fichamento?';
  static const String deleteNoteBody =
      'As citações deste fichamento também serão removidas.';
  static const String deleteQuoteTitle = 'Remover citação?';
  static const String deleteQuoteBody =
      'Esta citação será excluída ao salvar o fichamento.';

  static String quoteTitle(int index) => 'Citação $index';

  static const String deleteWorkTitle = 'Excluir obra?';
  static const String deleteWorkBody =
      'As leituras, sessões, fichamentos e vínculos desta obra também serão '
      'removidos.';
  static const String deleteSessionTitle = 'Excluir sessão?';
  static const String deleteSessionBody = 'Esta ação não pode ser desfeita.';

  static const String saveError = 'Não foi possível salvar. Tente novamente.';
  static const String deleteError =
      'Não foi possível excluir. Tente novamente.';
  static const String loadError = 'Não foi possível carregar os dados.';
  static const String workSaved = 'Obra salva.';
  static const String sessionSaved = 'Sessão salva.';

  static String workTypeLabel(String value) => switch (value) {
    'livro' => typeLivro,
    'artigo' => typeArtigo,
    _ => typeOutro,
  };

  static String workStatusLabel(String value) => switch (value) {
    'quero_ler' => statusQueroLer,
    'lendo' => statusLendo,
    _ => statusLido,
  };
}
