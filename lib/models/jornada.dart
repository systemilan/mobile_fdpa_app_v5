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
  final TestInfo test;
  final List<Gender> genders;
  final List<Category> categories;
  final dynamic combinedEvent;

  ScheduledTest({
    required this.id,
    this.time,
    required this.test,
    required this.genders,
    required this.categories,
    this.combinedEvent,
  });

  factory ScheduledTest.fromJson(Map<String, dynamic> json) {
    return ScheduledTest(
      id: json['id'] ?? '',
      time: json['time'], // Permitir null
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
      'test': test.toJson(),
      'genders': genders.map((g) => g.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'combinedEvent': combinedEvent,
    };
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

/// Modelo para los datos de jornadas (incluye evento y jornadas)
class JornadasData {
  final Map<String, dynamic> event;
  final List<Jornada> jornadas;

  JornadasData({
    required this.event,
    required this.jornadas,
  });

  factory JornadasData.fromJson(Map<String, dynamic> json) {
    return JornadasData(
      event: json['event'] ?? {},
      jornadas: (json['jornadas'] as List<dynamic>?)
              ?.map((item) => Jornada.fromJson(item as Map<String, dynamic>))
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
