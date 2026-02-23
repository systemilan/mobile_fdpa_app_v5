class AthleteSearchResponse {
  final bool success;
  final String query;
  final int total;
  final List<AthleteSearchResult> data;

  const AthleteSearchResponse({
    required this.success,
    required this.query,
    required this.total,
    required this.data,
  });

  factory AthleteSearchResponse.fromJson(Map<String, dynamic> json) {
    return AthleteSearchResponse(
      success: json['success'] as bool? ?? false,
      query: json['query']?.toString() ?? '',
      total: json['total'] as int? ?? 0,
      data: (json['data'] as List?)
              ?.map((e) => AthleteSearchResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Evento incluido en resultados de búsqueda global
class AthleteSearchEvent {
  final String id;
  final String shortName;
  final String longName;
  final String dateStart;
  final String dateEnd;

  const AthleteSearchEvent({
    required this.id,
    required this.shortName,
    required this.longName,
    required this.dateStart,
    required this.dateEnd,
  });

  factory AthleteSearchEvent.fromJson(Map<String, dynamic> json) {
    return AthleteSearchEvent(
      id: json['id']?.toString() ?? '',
      shortName: json['shortName']?.toString() ?? '',
      longName: json['longName']?.toString() ?? '',
      dateStart: json['dateStart']?.toString() ?? '',
      dateEnd: json['dateEnd']?.toString() ?? '',
    );
  }
}

class AthleteSearchResult {
  final AthleteSearchEvent? event; // presente en búsqueda global
  final AthleteSearchJornada jornada;
  final AthleteSearchEventTest eventTest;
  final AthleteSearchSerie serie;
  final AthleteSearchResultData result;

  const AthleteSearchResult({
    this.event,
    required this.jornada,
    required this.eventTest,
    required this.serie,
    required this.result,
  });

  factory AthleteSearchResult.fromJson(Map<String, dynamic> json) {
    return AthleteSearchResult(
      event: json['event'] != null
          ? AthleteSearchEvent.fromJson(json['event'] as Map<String, dynamic>)
          : null,
      jornada: AthleteSearchJornada.fromJson(
          json['jornada'] as Map<String, dynamic>? ?? {}),
      eventTest: AthleteSearchEventTest.fromJson(
          json['eventTest'] as Map<String, dynamic>? ?? {}),
      serie: AthleteSearchSerie.fromJson(
          json['serie'] as Map<String, dynamic>? ?? {}),
      result: AthleteSearchResultData.fromJson(
          json['result'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class AthleteSearchJornada {
  final String id;
  final String shortName;
  final String longName;

  const AthleteSearchJornada({
    required this.id,
    required this.shortName,
    required this.longName,
  });

  factory AthleteSearchJornada.fromJson(Map<String, dynamic> json) {
    return AthleteSearchJornada(
      id: json['id']?.toString() ?? '',
      shortName: json['shortName']?.toString() ?? '',
      longName: json['longName']?.toString() ?? '',
    );
  }
}

class AthleteSearchEventTest {
  final String id;
  final String? displayName;
  final String? customName;
  final AthleteSearchTest test;

  const AthleteSearchEventTest({
    required this.id,
    this.displayName,
    this.customName,
    required this.test,
  });

  /// Nombre a mostrar: customName → displayName → officialName
  String get displayedName {
    if (customName != null && customName!.isNotEmpty) return customName!;
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    return test.officialName;
  }

  factory AthleteSearchEventTest.fromJson(Map<String, dynamic> json) {
    return AthleteSearchEventTest(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString(),
      customName: json['customName']?.toString(),
      test: AthleteSearchTest.fromJson(
          json['test'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class AthleteSearchTest {
  final String officialName;
  final String type;

  const AthleteSearchTest({required this.officialName, required this.type});

  factory AthleteSearchTest.fromJson(Map<String, dynamic> json) {
    return AthleteSearchTest(
      officialName: json['officialName']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }
}

class AthleteSearchSerie {
  final String id;
  final String name;
  final int position;
  final int totalAthletes;

  const AthleteSearchSerie({
    required this.id,
    required this.name,
    required this.position,
    required this.totalAthletes,
  });

  factory AthleteSearchSerie.fromJson(Map<String, dynamic> json) {
    return AthleteSearchSerie(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      position: json['position'] as int? ?? 0,
      totalAthletes: json['totalAthletes'] as int? ?? 0,
    );
  }
}

class AthleteSearchResultData {
  final int? position;
  final String athleteId;
  final String name;
  final String team;
  final int? lane;
  final String? time;
  final String? bestMark;
  final String? athleteStatus;

  const AthleteSearchResultData({
    this.position,
    required this.athleteId,
    required this.name,
    required this.team,
    this.lane,
    this.time,
    this.bestMark,
    this.athleteStatus,
  });

  /// Texto a mostrar en el resultado (tiempo, DNS, bestMark, etc.)
  String get displayTime {
    if (athleteStatus != null && athleteStatus!.isNotEmpty) {
      return athleteStatus!;
    }
    if (bestMark != null && bestMark!.isNotEmpty) {
      return bestMark!;
    }
    if (time != null && time!.isNotEmpty) {
      return time!;
    }
    return '- - -';
  }

  /// Equipo formateado: "MOL  - MAS" → "MOL / MAS"
  String get teamFormatted {
    return team.replaceAll(RegExp(r'\s+-\s+'), ' / ').trim();
  }

  factory AthleteSearchResultData.fromJson(Map<String, dynamic> json) {
    return AthleteSearchResultData(
      position: json['position'] as int?,
      athleteId: json['athleteId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      team: json['team']?.toString() ?? '',
      lane: json['lane'] as int?,
      time: json['time']?.toString(),
      bestMark: json['bestMark']?.toString(),
      athleteStatus: json['athleteStatus']?.toString(),
    );
  }
}
