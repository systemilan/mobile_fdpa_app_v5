// Modelos para resultados de pruebas de campo (tipo 2)
// Endpoint: /public/event-tests/{id}/results

class FieldAthleteResult {
  final int? position;
  final String athleteId;
  final String name;
  final String team;
  final String? country;
  final String? birthDate;
  final int lane;
  final String? time;
  final List<String> attempts;
  final List<String> winds;
  final double? bestMark;
  final bool status;
  final String eventType;

  FieldAthleteResult({
    this.position,
    required this.athleteId,
    required this.name,
    required this.team,
    this.country,
    this.birthDate,
    required this.lane,
    this.time,
    required this.attempts,
    required this.winds,
    this.bestMark,
    required this.status,
    required this.eventType,
  });

  factory FieldAthleteResult.fromJson(Map<String, dynamic> json) {
    return FieldAthleteResult(
      position: json['position'],
      athleteId: json['athleteId']?.toString() ?? '',
      name: json['name'] ?? '',
      team: json['team'] ?? '',
      country: json['country'],
      birthDate: json['birthDate'],
      lane: json['lane'] ?? 0,
      time: json['time'],
      attempts: (json['attempts'] as List<dynamic>?)
              ?.map((e) => e?.toString() ?? '')
              .toList() ??
          [],
      winds: (json['winds'] as List<dynamic>?)
              ?.map((e) => e?.toString() ?? '')
              .toList() ??
          [],
      bestMark: json['bestMark']?.toDouble(),
      status: json['status'] ?? false,
      eventType: json['eventType'] ?? '',
    );
  }

  String get bestMarkFormatted {
    if (bestMark == null) return '-';
    return bestMark!.toStringAsFixed(2);
  }

  // Helper para obtener el club en formato de 3 líneas
  String get clubFormatted {
    // Dividir el team en palabras
    final words = team.split(' ');
    if (words.length >= 3) {
      return '${words[0]}\n${words[1]}\n${words[2]}';
    } else if (words.length == 2) {
      return '${words[0]}\n${words[1]}\n';
    } else if (words.length == 1) {
      return '${words[0]}\n\n';
    }
    return team;
  }
}

class ResultSeries {
  final String id;
  final String name;
  final int position;
  final String? wind;
  final bool status;
  final List<FieldAthleteResult> results;

  ResultSeries({
    required this.id,
    required this.name,
    required this.position,
    this.wind,
    required this.status,
    required this.results,
  });

  factory ResultSeries.fromJson(Map<String, dynamic> json) {
    return ResultSeries(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      position: json['position'] ?? 0,
      wind: json['wind'],
      status: json['status'] ?? false,
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => FieldAthleteResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TestInfo {
  final String id;
  final String officialName;
  final String commonName;
  final String type;
  final String inputFormat;
  final bool measuresWind;

  TestInfo({
    required this.id,
    required this.officialName,
    required this.commonName,
    required this.type,
    required this.inputFormat,
    required this.measuresWind,
  });

  factory TestInfo.fromJson(Map<String, dynamic> json) {
    return TestInfo(
      id: json['id'] ?? '',
      officialName: json['officialName'] ?? '',
      commonName: json['commonName'] ?? '',
      type: json['type'] ?? '',
      inputFormat: json['inputFormat'] ?? '',
      measuresWind: json['measuresWind'] ?? false,
    );
  }
}

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
}

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
}

class EventTestResult {
  final String id;
  final String time;
  final TestInfo test;
  final List<Gender> genders;
  final List<Category> categories;
  final dynamic combinedEvent;

  EventTestResult({
    required this.id,
    required this.time,
    required this.test,
    required this.genders,
    required this.categories,
    this.combinedEvent,
  });

  factory EventTestResult.fromJson(Map<String, dynamic> json) {
    return EventTestResult(
      id: json['id'] ?? '',
      time: json['time'] ?? '',
      test: TestInfo.fromJson(json['test'] as Map<String, dynamic>? ?? {}),
      genders: (json['genders'] as List<dynamic>?)
              ?.map((e) => Gender.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      combinedEvent: json['combinedEvent'],
    );
  }

  String get categoriesFormatted {
    if (categories.isEmpty) return '';
    return categories.map((c) => c.shortName).join(', ');
  }

  String get gendersFormatted {
    if (genders.isEmpty) return '';
    if (genders.length == 1) {
      return genders.first.longName;
    }
    return 'Mixto';
  }
}

class ResultType2Data {
  final EventTestResult eventTest;
  final List<ResultSeries> series;

  ResultType2Data({
    required this.eventTest,
    required this.series,
  });

  factory ResultType2Data.fromJson(Map<String, dynamic> json) {
    return ResultType2Data(
      eventTest: EventTestResult.fromJson(
          json['eventTest'] as Map<String, dynamic>? ?? {}),
      series: (json['series'] as List<dynamic>?)
              ?.map((e) => ResultSeries.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // Helper para obtener todos los resultados combinados de todas las series
  List<FieldAthleteResult> get allResults {
    return series.expand((s) => s.results).toList();
  }

  // Helper para obtener solo los resultados con posición (atletas que completaron)
  List<FieldAthleteResult> get rankedResults {
    return allResults.where((r) => r.position != null).toList()
      ..sort((a, b) => (a.position ?? 999).compareTo(b.position ?? 999));
  }
}

class ResultType2Response {
  final bool success;
  final ResultType2Data data;
  final String timestamp;

  ResultType2Response({
    required this.success,
    required this.data,
    required this.timestamp,
  });

  factory ResultType2Response.fromJson(Map<String, dynamic> json) {
    return ResultType2Response(
      success: json['success'] ?? false,
      data: ResultType2Data.fromJson(json['data'] as Map<String, dynamic>? ?? {}),
      timestamp: json['timestamp'] ?? '',
    );
  }
}
