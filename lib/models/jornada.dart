/// Modelo para categoría
class Category {
  final String id;
  final String shortName;
  final String longName;

  Category({
    required this.id,
    required this.shortName,
    required this.longName,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      shortName: json['shortName'] ?? '',
      longName: json['longName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shortName': shortName,
      'longName': longName,
    };
  }
}

/// Modelo para género
class Gender {
  final String id;
  final String shortName;
  final String longName;

  Gender({
    required this.id,
    required this.shortName,
    required this.longName,
  });

  factory Gender.fromJson(Map<String, dynamic> json) {
    return Gender(
      id: json['id'] ?? '',
      shortName: json['shortName'] ?? '',
      longName: json['longName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shortName': shortName,
      'longName': longName,
    };
  }
}

/// Modelo para prueba/test
class TestInfo {
  final String id;
  final String officialName;
  final String commonName;
  final String type; // "1" para tiempo, "2" para medida
  final String inputFormat; // "1", "2", "3", etc.

  TestInfo({
    required this.id,
    required this.officialName,
    required this.commonName,
    required this.type,
    required this.inputFormat,
  });

  factory TestInfo.fromJson(Map<String, dynamic> json) {
    return TestInfo(
      id: json['id'] ?? '',
      officialName: json['officialName'] ?? '',
      commonName: json['commonName'] ?? '',
      type: json['type']?.toString() ?? '1',
      inputFormat: json['inputFormat']?.toString() ?? json['input_format']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'officialName': officialName,
      'commonName': commonName,
      'type': type,
      'inputFormat': inputFormat,
    };
  }

  // Helper para determinar si es prueba de tiempo
  bool get isTimeTest => type == '1';
  
  // Helper para determinar si es prueba de medida/campo
  bool get isFieldTest => type == '2';
  
  // Helper para determinar si usa inputFormat 3 (lanzamientos/saltos con serie de intentos)
  bool get isInputFormat3 => inputFormat == '3';
}

/// Modelo para una prueba programada en una jornada
class ScheduledTest {
  final String id;
  final String? time; // Puede ser null
  final String? customName;
  final String? displayName;
  final TestInfo test;
  final List<Gender> genders;
  final List<Category> categories;
  final dynamic combinedEvent;

  ScheduledTest({
    required this.id,
    this.time,
    this.customName,
    this.displayName,
    required this.test,
    required this.genders,
    required this.categories,
    this.combinedEvent,
  });

  factory ScheduledTest.fromJson(Map<String, dynamic> json) {
    return ScheduledTest(
      id: json['id'] ?? '',
      time: json['time'], // Permitir null
      customName: json['customName'] as String?,
      displayName: json['displayName'] as String?,
      test: TestInfo.fromJson(json['test'] ?? {}),

      genders: (json['genders'] as List<dynamic>?)
              ?.map((item) => Gender.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      categories: (json['categories'] as List<dynamic>?)
              ?.map((item) => Category.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      combinedEvent: json['combinedEvent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'customName': customName,
      'displayName': displayName,
      'test': test.toJson(),
      'genders': genders.map((g) => g.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'combinedEvent': combinedEvent,
    };
  }

  // Helper para obtener el nombre a mostrar:
  // Prioridad: customName → commonName → displayName → officialName
  String get displayedName {
    if (customName != null && customName!.isNotEmpty) return customName!;
    if (test.commonName.isNotEmpty) return test.commonName;
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    return test.officialName;
  }

  // Helper para obtener categorías formateadas
  String get categoriesFormatted {
    if (categories.isEmpty) return '';
    return categories.map((c) => c.shortName).join(', ');
  }

  // Helper para obtener géneros formateados
  String get gendersFormatted {
    if (genders.isEmpty) return '';
    return genders.map((g) => g.shortName).join(', ');
  }
}

/// Modelo para una jornada
class Jornada {
  final String id;
  final String shortName;
  final String longName;
  final String date;
  final List<ScheduledTest> tests;

  Jornada({
    required this.id,
    required this.shortName,
    required this.longName,
    required this.date,
    required this.tests,
  });

  factory Jornada.fromJson(Map<String, dynamic> json) {
    return Jornada(
      id: json['id'] ?? '',
      shortName: json['shortName'] ?? '',
      longName: json['longName'] ?? '',
      date: json['date'] ?? '',
      tests: (json['tests'] as List<dynamic>?)
              ?.map((item) => ScheduledTest.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shortName': shortName,
      'longName': longName,
      'date': date,
      'tests': tests.map((t) => t.toJson()).toList(),
    };
  }

  // Helper para obtener la fecha formateada
  String get dateFormatted {
    try {
      final DateTime dateTime = DateTime.parse(date);
      final List<String> months = [
        'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
        'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
      ];
      return '${dateTime.day} de ${months[dateTime.month - 1]} del ${dateTime.year}';
    } catch (e) {
      return date;
    }
  }
}

/// Sub-resultado de una disciplina dentro de una prueba combinada
class CombinedSubResult {
  final int? points;
  final String? mark;

  CombinedSubResult({this.points, this.mark});

  factory CombinedSubResult.fromJson(Map<String, dynamic> json) {
    return CombinedSubResult(
      points: json['points'] as int?,
      mark: json['mark'] as String?,
    );
  }
}

/// Columna de disciplina en el resumen de prueba combinada
class CombinedSubTest {
  final String eventTestId;
  final String displayName;

  CombinedSubTest({required this.eventTestId, required this.displayName});

  factory CombinedSubTest.fromJson(Map<String, dynamic> json) {
    return CombinedSubTest(
      eventTestId: json['eventTestId'] ?? '',
      displayName: json['displayName'] ?? '',
    );
  }

  /// Abreviatura para la cabecera de columna (ej. "100", "SL", "BALA", "110V")
  String get shortLabel {
    final n = displayName.toLowerCase();
    if (n.contains('100') && (n.contains('valla') || n.contains('obstáculo'))) return '100V';
    if (n.contains('110') && n.contains('valla')) return '110V';
    if (n.contains('60') && n.contains('valla')) return '60V';
    if (n.contains('100')) return '100';
    if (n.contains('200')) return '200';
    if (n.contains('400')) return '400';
    if (n.contains('800')) return '800';
    if (n.contains('1500')) return '1500';
    if (n.contains('5000')) return '5000';
    if (n.contains('triple')) return 'ST';
    if (n.contains('longitud') || n.contains('largo')) return 'SL';
    if (n.contains('garrocha') || n.contains('pértiga')) return 'SG';
    if (n.contains('altura') || n.contains('alto')) return 'SA';
    if (n.contains('bala') || n.contains('impuls')) return 'BALA';
    if (n.contains('disco')) return 'DIS';
    if (n.contains('jabalina') || n.contains('javelin')) return 'JAB';
    if (n.contains('martillo') || n.contains('hammer')) return 'MAR';
    final trimmed = displayName.trim();
    return trimmed.length <= 4
        ? trimmed.toUpperCase()
        : trimmed.substring(0, 4).toUpperCase();
  }
}

/// Fila de atleta en el resumen de prueba combinada
class CombinedAthlete {
  final String athleteId;
  final String name;
  final String team;
  final String country;
  final int totalPoints;
  final Map<String, CombinedSubResult> subResults;
  final int finalPosition;

  CombinedAthlete({
    required this.athleteId,
    required this.name,
    required this.team,
    required this.country,
    required this.totalPoints,
    required this.subResults,
    required this.finalPosition,
  });

  factory CombinedAthlete.fromJson(Map<String, dynamic> json) {
    final rawSub = json['subResults'] as Map<String, dynamic>? ?? {};
    final subResults = rawSub.map(
      (k, v) => MapEntry(
        k,
        CombinedSubResult.fromJson(v as Map<String, dynamic>),
      ),
    );
    return CombinedAthlete(
      athleteId: json['athleteId']?.toString() ?? '',
      name: json['name'] ?? '',
      team: json['team'] ?? '',
      country: json['country'] ?? '',
      totalPoints: json['totalPoints'] as int? ?? 0,
      subResults: subResults,
      finalPosition: json['finalPosition'] as int? ?? 0,
    );
  }

  /// Nombre formateado en Title Case
  String get nameFormatted {
    return name
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}

/// Resumen completo de una prueba combinada (decatlón / heptatlón)
class CombinedSummary {
  final Map<String, dynamic> combinedEventData;
  final List<CombinedSubTest> subTests;
  final List<CombinedAthlete> athletes;

  CombinedSummary({
    required this.combinedEventData,
    required this.subTests,
    required this.athletes,
  });

  factory CombinedSummary.fromJson(Map<String, dynamic> json) {
    return CombinedSummary(
      combinedEventData: json['combinedEvent'] as Map<String, dynamic>? ?? {},
      subTests: (json['subTests'] as List<dynamic>?)
              ?.map((e) => CombinedSubTest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      athletes: (json['athletes'] as List<dynamic>?)
              ?.map((e) => CombinedAthlete.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get longName =>
      combinedEventData['longName'] as String? ??
      combinedEventData['shortName'] as String? ??
      '';

  String get shortName => combinedEventData['shortName'] as String? ?? '';
}

/// Modelo para la respuesta de jornadas
class JornadasResponse {
  final bool success;
  final JornadasData data;
  final String timestamp;

  JornadasResponse({
    required this.success,
    required this.data,
    required this.timestamp,
  });

  factory JornadasResponse.fromJson(Map<String, dynamic> json) {
    return JornadasResponse(
      success: json['success'] ?? false,
      data: JornadasData.fromJson(json['data'] ?? {}),
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.toJson(),
      'timestamp': timestamp,
    };
  }
}

/// Modelo para los datos de jornadas (incluye evento, jornadas y resúmenes combinados)
class JornadasData {
  final Map<String, dynamic> event;
  final List<Jornada> jornadas;
  final List<CombinedSummary> combinedSummaries;

  JornadasData({
    required this.event,
    required this.jornadas,
    this.combinedSummaries = const [],
  });

  factory JornadasData.fromJson(Map<String, dynamic> json) {
    return JornadasData(
      event: json['event'] ?? {},
      jornadas: (json['jornadas'] as List<dynamic>?)
              ?.map((item) => Jornada.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      combinedSummaries: (json['combinedSummaries'] as List<dynamic>?)
              ?.map((e) => CombinedSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // Helper para verificar si el evento es histórico
  bool get isEventHistorical {
    return event['oldHistory'] == true;
  }

  // Helper para obtener el ID del evento
  String get eventId {
    return event['id'] ?? '';
  }

  Map<String, dynamic> toJson() {
    return {
      'event': event,
      'jornadas': jornadas.map((j) => j.toJson()).toList(),
    };
  }
}
