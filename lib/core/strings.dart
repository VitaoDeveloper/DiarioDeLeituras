abstract final class AppStrings {
  static const String appTitle = 'Diário de Leituras';
  static const String works = 'Obras';
  static const String notes = 'Fichamentos';
  static const String analyses = 'Análises';
  static const String stats = 'Estatísticas';

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

  static const String linkedNotes = 'Fichamentos desta obra';
  static const String linkedAnalyses = 'Análises desta obra';
  static const String noLinkedNotes = 'Nenhum fichamento vinculado.';
  static const String noLinkedAnalyses = 'Nenhuma análise vinculada.';

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
      'As sessões, fichamentos e vínculos desta obra também serão removidos.';
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
