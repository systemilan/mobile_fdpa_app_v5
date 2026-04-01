/// Model for time-based race events (inputFormat "1") - 100m, 200m, 400m, etc.
/// These events use lanes and time-based results

class ResultType1Response {
  final bool success;
  final ResultType1Data data;
  final String timestamp;

  ResultType1Response({
    required this.success,
    required this.data,
    required this.timestamp,
  });

  factory ResultType1Response.fromJson(Map<String, dynamic> json) {
    return ResultType1Response(
      success: json['success'] ?? false,
      data: ResultType1Data.fromJson(json['data']),
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class ResultType1Data {
  final EventTestResult eventTest;
  final List<ResultSeries> series;

  ResultType1Data({
    required this.eventTest,
    required this.series,
  });

  factory ResultType1Data.fromJson(Map<String, dynamic> json) {
    return ResultType1Data(
      eventTest: EventTestResult.fromJson(json['eventTest']),
      series: (json['series'] as List<dynamic>?)
              ?.map((s) => ResultSeries.fromJson(s))
              .toList() ??
          [],
    );
  }

  /// Get all results from all series combined
  List<RaceAthleteResult> get allResults {
    return series.expand((serie) => serie.results).toList();
  }

  /// Convert time string ("SS.ss" or "MM:SS.ss") to seconds for sorting
  static double _timeStringToSeconds(String t) {
    if (t.contains(':')) {
      final parts = t.split(':');
      final minutes = double.tryParse(parts[0]) ?? 0;
      final seconds = double.tryParse(parts[1]) ?? 0;
      return minutes * 60 + seconds;
    }
    return double.tryParse(t) ?? double.infinity;
  }

  /// Get all results sorted by time (fastest first)
  List<RaceAthleteResult> get rankedResults {
    final validResults = allResults.where((r) => r.time != null && r.time!.isNotEmpty).toList();
    validResults.sort((a, b) => ResultType1Data._timeStringToSeconds(a.time!).compareTo(ResultType1Data._timeStringToSeconds(b.time!)));
    return validResults;
  }
}

class EventTestResult {
  final String id;
  final String time;
  final String? customName;
  final String? displayName;
  final TestInfo test;
  final List<Gender> genders;
  final List<Category> categories;
  final dynamic combinedEvent;

  EventTestResult({
    required this.id,
    required this.time,
    this.customName,
    this.displayName,
    required this.test,
    required this.genders,
    required this.categories,
    this.combinedEvent,
  });

  factory EventTestResult.fromJson(Map<String, dynamic> json) {
    return EventTestResult(
      id: json['id'] ?? '',
      time: json['time'] ?? '',
      customName: json['customName'] as String?,
      displayName: json['displayName'] as String?,
      test: TestInfo.fromJson(json['test']),
      genders: (json['genders'] as List<dynamic>?)
              ?.map((g) => Gender.fromJson(g))
              .toList() ??
          [],
      categories: (json['categories'] as List<dynamic>?)
              ?.map((c) => Category.fromJson(c))
              .toList() ??
          [],
      combinedEvent: json['combinedEvent'],
    );
  }

  /// Nombre a mostrar: customName → commonName → displayName → officialName
  String get displayedName {
    if (customName != null && customName!.isNotEmpty) return customName!;
    if (test.commonName.isNotEmpty) return test.commonName;
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    return test.officialName;
  }

  String get gendersFormatted {
    return genders.map((g) => g.shortName).join(', ');
  }

  String get categoriesFormatted {
    return categories.map((c) => c.shortName).join(', ');
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
      inputFormat: json['inputFormat'] ?? json['input_format'] ?? '',
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

class ResultSeries {
  final String id;
  final String name;
  final int position;
  final String? wind;
  final bool status;
  final List<RaceAthleteResult> results;

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
      status: json['status'] ?? true,
      results: (json['results'] as List<dynamic>?)
              ?.map((r) => RaceAthleteResult.fromJson(r))
              .toList() ??
          [],
    );
  }
}

class RaceAthleteResult {
  final int displayOrder;
  final int? position;
  final String? positionAthlete;
  final String? athleteStatus;
  final String athleteId;
  final String name;
  final String team;
  final String? country;
  final String? birthDate;
  final int lane;
  final String? time;
  final List<String> attempts;
  final List<String> winds;
  final String? bestMark;
  final bool status;
  final String eventType;

  RaceAthleteResult({
    this.displayOrder = 0,
    this.position,
    this.positionAthlete,
    this.athleteStatus,
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

  factory RaceAthleteResult.fromJson(Map<String, dynamic> json) {
    return RaceAthleteResult(
      displayOrder: json['displayOrder'] as int? ?? 0,
      position: json['position'] as int?,
      positionAthlete: json['positionAthlete']?.toString(),
      athleteStatus: json['athleteStatus']?.toString(),
      athleteId: json['athleteId']?.toString() ?? '',
      name: json['name'] ?? '',
      team: json['team'] ?? '',
      country: json['country'],
      birthDate: json['birthDate'],
      lane: json['lane'] ?? 0,
      time: json['time']?.toString(),
      attempts: (json['attempts'] as List<dynamic>?)?.map((a) => a.toString()).toList() ?? [],
      winds: (json['winds'] as List<dynamic>?)?.map((w) => w.toString()).toList() ?? [],
      bestMark: json['bestMark']?.toString(),
      status: json['status'] ?? true,
      eventType: json['eventType'] ?? '',
    );
  }

  /// Texto de posición: positionAthlete (NSP/DNS/DFQ…) > posición numérica > athleteStatus > '- - -'
  String get positionText {
    if (positionAthlete != null && positionAthlete!.isNotEmpty) return positionAthlete!;
    if (position != null) return '${position}°';
    if (athleteStatus != null && athleteStatus!.isNotEmpty) return athleteStatus!;
    return '- - -';
  }

  /// True si no tiene posición competitiva (DNS/DNF/DQ/NH/NM/NSP…)
  bool get isDNS {
    // Si tiene tiempo válido → participó, NO es DNS aunque position sea null
    if (time != null && time!.isNotEmpty) return false;
    // Si tiene una marca válida → participó
    if (bestMark != null && bestMark!.isNotEmpty) return false;
    // positionAthlete con texto → sin posición competitiva
    if (positionAthlete != null && positionAthlete!.isNotEmpty) return true;
    // Si tiene athleteStatus explícito (DNS, DNF, DQ, etc.) → sí es DNS
    if (athleteStatus != null && athleteStatus!.isNotEmpty) return true;
    // Sin tiempo, sin marca, sin status y sin posición → DNS
    return position == null;
  }

  /// Get formatted time - returns the value exactly as it comes from the API
  String get timeFormatted {
    if (time == null || time!.isEmpty) return '- - -';
    return time!;
  }

  /// Get club formatted for display (splits team into lines)
  String get clubFormatted {
    if (team.isEmpty) return '';
    
    // Split by " - " if exists
    if (team.contains(' - ')) {
      return team.replaceAll(' - ', '\n');
    }
    
    // If team is too long, split it
    if (team.length > 6) {
      final words = team.split(' ');
      if (words.length > 1) {
        return words.take(3).join('\n');
      }
      // Split by 3 characters
      final parts = <String>[];
      for (var i = 0; i < team.length; i += 3) {
        parts.add(team.substring(i, i + 3 > team.length ? team.length : i + 3));
      }
      return parts.take(3).join('\n');
    }
    
    return team;
  }
}
