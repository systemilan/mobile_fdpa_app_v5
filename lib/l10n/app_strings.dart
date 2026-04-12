/// Archivo central de traducciones — ES / EN
/// Para agregar un nuevo idioma: añadir la condición en cada getter.
class AppStrings {
  final String languageCode;
  const AppStrings._(this.languageCode);

  static const es = AppStrings._('es');
  static const en = AppStrings._('en');

  bool get _isEs => languageCode == 'es';

  // ─── Common ──────────────────────────────────────────────────────────────
  String get appTitle => _isEs ? 'FDPA Atletismo' : 'FDPA Athletics';
  String get federationLine1 => _isEs ? 'Federación Deportiva' : 'Sports Federation';
  String get federationLine2 => _isEs ? 'Peruana de Atletismo' : 'Peruvian of Athletics';
  String get federationNameFull => _isEs
      ? 'FEDERACIÓN PERUANA DE ATLETISMO'
      : 'PERUVIAN ATHLETICS FEDERATION';
  String get close => _isEs ? 'Cerrar' : 'Close';
  String get retry => _isEs ? 'Reintentar' : 'Retry';
  String get ok => 'OK';
  String get search => _isEs ? 'Buscar' : 'Search';
  String get loading => _isEs ? 'Cargando...' : 'Loading...';
  String get unknownError => _isEs ? 'Error desconocido' : 'Unknown error';
  String get team => _isEs ? 'EQUIPO' : 'TEAM';
  String get category => _isEs ? 'Categoría' : 'Category';
  String get place => _isEs ? 'Lugar' : 'Place';
  String get date => _isEs ? 'Fecha' : 'Date';
  String get coach => _isEs ? 'Entrenador' : 'Coach';
  String get pdf => 'PDF';
  String get all => _isEs ? 'Todos' : 'All';
  String get men => _isEs ? 'Varones' : 'Men';
  String get women => _isEs ? 'Damas' : 'Women';
  String get mixed => _isEs ? 'Mixto' : 'Mixed';
  String get na => 'N/A';
  String get updated => _isEs ? 'Act.' : 'Upd.';

  // ─── Home ─────────────────────────────────────────────────────────────────
  String get latestResults => _isEs ? 'Últimos resultados' : 'Latest results';
  String get viewAll => _isEs ? 'Ver todos' : 'View all';
  String get minimumMarks => _isEs ? 'Marcas Mínimas' : 'Minimum Marks';
  String get nationalRecords => _isEs ? 'Records Nacionales' : 'National Records';
  String get nationalRanking => _isEs ? 'Ranking Nacional' : 'National Ranking';
  String get upcomingEvents => _isEs ? 'Próximos eventos' : 'Upcoming events';
  String get openCalendar => _isEs ? 'Abrir calendario' : 'Open calendar';
  String get noUpcomingEvents =>
      _isEs ? 'No hay eventos próximos' : 'No upcoming events';
  String seasonYear(int year) =>
      _isEs ? 'TEMPORADA $year' : 'SEASON $year';
  String get calendarWord => _isEs ? 'Calendario' : 'Calendar';
  String get ofEventsWord => _isEs ? 'de Eventos' : 'of Events';
  String get calendarOfEvents =>
      _isEs ? 'Calendario de Eventos' : 'Event Calendar';
  String get moreInfo => _isEs ? 'Más Info' : 'More Info';
  String get register => _isEs ? 'Inscribirse' : 'Register';
  String get noRecentResults =>
      _isEs ? 'No hay resultados recientes' : 'No recent results';
  String get pastResultsHere => _isEs
      ? 'Los resultados de eventos pasados aparecerán aquí'
      : 'Past event results will appear here';
  String get pdfMobileOnly => _isEs
      ? 'La descarga de PDF solo está disponible en la app móvil.'
      : 'PDF download is only available in the mobile app.';
  String get downloadingCalendarPdf =>
      _isEs ? 'Descargando calendario PDF...' : 'Downloading calendar PDF...';
  String calendarDownloaded(String path) =>
      _isEs ? 'Calendario descargado en: $path' : 'Calendar downloaded at: $path';
  String errorDownloadingPdf(String error) =>
      _isEs ? 'Error al descargar PDF: $error' : 'Error downloading PDF: $error';
  String eventOnDate(String day, String month, String year) =>
      _isEs ? 'Evento del $day de $month $year' : 'Event on $month $day, $year';

  // ─── Drawer ───────────────────────────────────────────────────────────────
  String get darkMode => _isEs ? 'Modo Oscuro' : 'Dark Mode';
  String get changeAppearance =>
      _isEs ? 'Cambiar apariencia de la app' : 'Change app appearance';
  String get updates => _isEs ? 'Actualizaciones' : 'Updates';
  String get updateAvailable =>
      _isEs ? 'Actualización disponible' : 'Update available';
  String get checking => _isEs ? 'Verificando...' : 'Checking...';
  String get checkUpdates =>
      _isEs ? 'Verificar actualizaciones' : 'Check for updates';
  String get about => _isEs ? 'Sobre la app' : 'About';
  String get infoAndVersion =>
      _isEs ? 'Información y versión' : 'Information and version';
  String get language => _isEs ? 'Idioma' : 'Language';
  String get selectLanguage =>
      _isEs ? 'Seleccionar idioma de la app' : 'Select app language';
  String get spanish => 'Español';
  String get english => 'English';
  String get versionLabel => _isEs ? 'Versión' : 'Version';
  String get buildLabel => 'Build';
  String get aboutTitle =>
      _isEs ? 'Sobre la aplicación' : 'About the application';
  String aboutContent(String version, String buildDate) {
    final buildInfo = buildDate.isNotEmpty ? '  |  Build: $buildDate' : '';
    return _isEs
        ? 'FDPA App\nVersión $version$buildInfo\n\nAplicación oficial de la Federación Deportiva Peruana de Atletismo para consultar resultados, estadísticas y eventos.'
        : 'FDPA App\nVersion $version$buildInfo\n\nOfficial application of the Peruvian Athletics Sports Federation to check results, statistics and events.';
  }

  String get languageDialogTitle => _isEs ? 'Idioma de la app' : 'App Language';
  String get languageDialogContent => _isEs
      ? 'Selecciona el idioma que deseas usar en la aplicación.'
      : 'Select the language you want to use in the application.';

  // ─── Rankings ─────────────────────────────────────────────────────────────
  String get nationalRankings =>
      _isEs ? 'Rankings Nacionales' : 'National Rankings';
  String get noRankingsAvailable =>
      _isEs ? 'No hay rankings disponibles' : 'No rankings available';
  String get notAvailable => _isEs ? 'No disponible' : 'Not available';
  String get archived => _isEs ? 'Archivado' : 'Archived';
  String get active => _isEs ? 'Activo' : 'Active';
  String get rankingHistoric => _isEs ? 'Histórico' : 'Historic';
  String get rankingActive => _isEs ? 'Vigente' : 'Active';
  String get collapse => _isEs ? 'Colapsar' : 'Collapse';
  String rankingListUpdated(String d) =>
      _isEs ? 'Lista actualizada el $d' : 'List updated on $d';
  String get rankingCouldNotLoad =>
      _isEs ? 'No se pudo cargar el ranking' : 'Ranking could not be loaded';
  String errorLoadingRanking(String e) =>
      _isEs ? 'No se pudieron cargar los rankings.\n$e' : 'Could not load rankings.\n$e';
  String rankingSeason(int year) =>
      _isEs ? 'Temporada $year · Todas las categorías' : 'Season $year · All categories';
  String get rankingAllSeasons =>
      _isEs ? 'Todas las temporadas · Todas las categorías' : 'All seasons · All categories';
  String rankingNotPublished(int year) =>
      _isEs ? 'El ranking $year aún no ha sido publicado.' : 'The $year ranking has not been published yet.';
  String rankingNoDataForYear(int year) =>
      _isEs ? 'Sin datos para $year' : 'No data for $year';
  String get expandAll => _isEs ? 'Expandir todo' : 'Expand all';
  String get collapseAll => _isEs ? 'Colapsar todo' : 'Collapse all';
  String get searchAthletePlaceholder =>
      _isEs ? 'Buscar atleta...' : 'Search athlete...';
  String get searchAthleteHint =>
      _isEs ? 'Buscar atleta (ej: Chirinos…)' : 'Search athlete (e.g.: Smith…)';
  String get noResultsForSearch =>
      _isEs ? 'Sin resultados para la búsqueda' : 'No results for search';
  String noAthletesForQuery(String q) =>
      _isEs ? 'No se encontraron atletas para\n"$q"' : 'No athletes found for\n"$q"';
  String get noDisciplinesAvailable =>
      _isEs ? 'No hay disciplinas disponibles' : 'No disciplines available';
  String rankingResultsSummary(int entries, int disciplines) => _isEs
      ? '$entries resultado${entries != 1 ? 's' : ''} en $disciplines disciplina${disciplines != 1 ? 's' : ''}'
      : '$entries result${entries != 1 ? 's' : ''} in $disciplines discipline${disciplines != 1 ? 's' : ''}';
  String athleteCount(int n) =>
      _isEs ? '$n atleta${n != 1 ? 's' : ''}' : '$n athlete${n != 1 ? 's' : ''}';
  String get generatedFromEvents =>
      _isEs ? 'Generado desde eventos' : 'Generated from events';
  String rankingPublishedOn(String date) =>
      _isEs ? 'Publicado el $date' : 'Published on $date';
  String get rankingMen => _isEs ? 'VARONES' : 'MEN';
  String get rankingWomen => _isEs ? 'DAMAS' : 'WOMEN';
  String get rankingPos => _isEs ? 'Pos.' : 'Pos.';
  String get rankingAthleta => _isEs ? 'Atleta' : 'Athlete';
  String get rankingMark => _isEs ? 'Marca' : 'Mark';
  String get rankingWind => _isEs ? 'Viento' : 'Wind';
  String get rankingNoData =>
      _isEs ? 'No hay datos disponibles' : 'No data available';
  String get searchInRankings =>
      _isEs ? 'Buscar en Rankings' : 'Search in Rankings';
  String get searchAthleteInRankingsHint =>
      _isEs ? 'Buscar atleta (ej: Vila…)' : 'Search athlete (e.g.: Smith…)';
  String get noRankingAthleteResults =>
      _isEs ? 'No se encontraron atletas en los rankings' : 'No athletes found in the rankings';
  String rankingAthleteResultsCount(int n) => _isEs
      ? '$n resultado${n != 1 ? 's' : ''} en rankings'
      : '$n result${n != 1 ? 's' : ''} in rankings';

  // ─── All Results ──────────────────────────────────────────────────────────
  String get allResults => _isEs ? 'Todos los resultados' : 'All results';
  String get currentYear => _isEs ? 'Año actual' : 'Current year';
  String get byYear => _isEs ? 'Por año' : 'By year';
  String get noEventsAvailable =>
      _isEs ? 'No hay eventos disponibles' : 'No events available';
  String errorLoadingEvents(String e) =>
      _isEs ? 'Error al cargar los eventos: $e' : 'Error loading events: $e';
  String get noEventsFound =>
      _isEs ? 'No se encontraron eventos' : 'No events found';
  String get noCurrentYearEvents => _isEs
      ? 'No se encontraron eventos para el año actual'
      : 'No events found for the current year';
  String noSelectedYearEvents(int year) => _isEs
      ? 'No se encontraron eventos para el año seleccionado'
      : 'No events found for the selected year';

  // ─── Records ──────────────────────────────────────────────────────────────
  String get downloadingPdf =>
      _isEs ? 'Descargando PDF...' : 'Downloading PDF...';
  String pdfDownloaded(String path) =>
      _isEs ? 'PDF descargado exitosamente en: $path' : 'PDF downloaded successfully at: $path';
  String errorDownloadPdf(String e) =>
      _isEs ? 'Error al descargar PDF: $e' : 'Error downloading PDF: $e';
  String get noRecordsFound =>
      _isEs ? 'No se encontraron registros' : 'No records found';
  String forQuery(String q) => _isEs ? 'para "$q"' : 'for "$q"';
  String get enterNameSurname =>
      _isEs ? 'Escriba el nombre o apellido' : 'Enter name or surname';
  String errorLoadingData(String e) =>
      _isEs ? 'Error al cargar datos: $e' : 'Error loading data: $e';
  String errorLoadingRecords(String e) =>
      _isEs ? 'Error al cargar récords: $e' : 'Error loading records: $e';
  String errorInSearch(String e) =>
      _isEs ? 'Error en la búsqueda: $e' : 'Search error: $e';

  // ─── Championship ─────────────────────────────────────────────────────────
  String get noSessionsAvailable =>
      _isEs ? 'No hay jornadas disponibles' : 'No sessions available';
  String categoriesCount(int n) =>
      _isEs ? '$n categorías' : '$n categories';
  String get sessionSchedule => _isEs
      ? 'Lista de eventos y horarios para esta jornada.'
      : 'List of events and schedules for this session.';
  String get viewFullDetails =>
      _isEs ? 'Ver Detalles Completos' : 'View Full Details';

  // ─── Global Athlete Search ────────────────────────────────────────────────
  String get searchAthleteTitle =>
      _isEs ? 'Buscar atleta' : 'Search athlete';
  String get searchAllEventsHint => _isEs
      ? 'Busca en todos los eventos (en cualquier orden)'
      : 'Search across all events (in any order)';
  String resultsCount(int n) =>
      _isEs ? '$n resultado(s) encontrado(s)' : '$n result(s) found';
  String get youCanType => _isEs
      ? 'Puede escribir: Milan, Ditxon Milan o Milan Ditxon'
      : 'You can type: Milan, Ditxon Milan or Milan Ditxon';
  String get noResultsFound =>
      _isEs ? 'No se encontraron resultados' : 'No results found';
  String get noResultsForFilter => _isEs
      ? 'No hay resultados para el filtro seleccionado'
      : 'No results for the selected filter';
  String get searchError => _isEs
      ? 'Error al buscar. Verifica tu conexión e intenta de nuevo.'
      : 'Search error. Check your connection and try again.';
  String get searchAllEventsInfo => _isEs
      ? 'Se buscará en todos los eventos registrados'
      : 'Search will cover all registered events';
  String get writeNameOrSurname => _isEs
      ? 'Escriba nombre o apellido (en cualquier orden)'
      : 'Write name or surname (in any order)';
  String positionLabel(int pos) =>
      _isEs ? 'Puesto $pos' : 'Position $pos';
  String positionStr(String pos) =>
      _isEs ? 'Puesto $pos' : 'Position $pos';
  String laneLabel(int lane) =>
      _isEs ? 'Carril $lane' : 'Lane $lane';

  // ─── Event Results ────────────────────────────────────────────────────────
  String get eventResults =>
      _isEs ? 'Resultados de la Prueba' : 'Event Results';
  String windLabel(String wind) =>
      _isEs ? 'Viento: $wind M/S' : 'Wind: $wind m/s';
  String positionOrdinal(int pos) => '$pos°';
  String get qualified => _isEs ? 'Clasificado' : 'Qualified';
  String get didNotParticipate =>
      _isEs ? 'No participó' : 'Did not participate';
  String get noResultsAvailable =>
      _isEs ? 'No hay resultados disponibles' : 'No results available';
  String get resultsNotRegistered => _isEs
      ? 'Los resultados de esta prueba aún no han sido registrados'
      : 'Results for this event have not been registered yet';
  String errorLoadingResults(String e) =>
      _isEs ? 'Error al cargar los resultados: $e' : 'Error loading results: $e';
  String get event => _isEs ? 'Prueba' : 'Event';
  String get viewMarks => _isEs ? 'Ver marcas →' : 'View marks →';
  String get noMarksRegistered =>
      _isEs ? 'No hay marcas registradas' : 'No marks registered';
  String get noMinimumMarksAvailable => _isEs
      ? 'No hay marcas mínimas disponibles'
      : 'No minimum marks available';

  // ─── Splash ───────────────────────────────────────────────────────────────
  String get splashLine1 =>
      _isEs ? 'FEDERACIÓN PERUANA' : 'PERUVIAN FEDERATION';
  String get splashLine2 =>
      _isEs ? 'DE ATLETISMO' : 'OF ATHLETICS';

  // ─── Month & day names ────────────────────────────────────────────────────
  List<String> get monthNames => _isEs
      ? ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
         'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre']
      : ['January', 'February', 'March', 'April', 'May', 'June',
         'July', 'August', 'September', 'October', 'November', 'December'];

  List<String> get monthNamesShort => _isEs
      ? ['Ene.', 'Feb.', 'Mar.', 'Abr.', 'May.', 'Jun.',
         'Jul.', 'Ago.', 'Sep.', 'Oct.', 'Nov.', 'Dic.']
      : ['Jan.', 'Feb.', 'Mar.', 'Apr.', 'May.', 'Jun.',
         'Jul.', 'Aug.', 'Sep.', 'Oct.', 'Nov.', 'Dec.'];

  List<String> get weekDayNames => _isEs
      ? ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado']
      : ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  List<String> get weekDayNamesShort => _isEs
      ? ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb']
      : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
}
