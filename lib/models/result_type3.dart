import 'dart:convert';

/// Model for height-based field events (inputFormat "2") - High Jump, Pole Vault, etc.
/// These events use progressive heights where athletes attempt each height until elimination

class ResultType3Response {
  final bool success;
  final ResultType3Data data;
  final String timestamp;

  ResultType3Response({
    required this.success,
    required this.data,
    required this.timestamp,
  });

  factory ResultType3Response.fromJson(Map<String, dynamic> json) {
    return ResultType3Response(
      success: json['success'] ?? false,
      data: ResultType3Data.fromJson(json['data']),
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class ResultType3Data {
  final EventTestResult eventTest;
  final List<ResultSeries> series;

  ResultType3Data({
    required this.eventTest,
    required this.series,
  });

  factory ResultType3Data.fromJson(Map<String, dynamic> json) {
    return ResultType3Data(
      eventTest: EventTestResult.fromJson(json['eventTest']),
      series: (json['series'] as List<dynamic>?)
              ?.map((s) => ResultSeries.fromJson(s))
              .toList() ??
          [],
    );
  }

  /// Get all results from all series combined
  List<HeightAthleteResult> get allResults {
    return series.expand((serie) => serie.results).toList();
  }

  /// Get all unique heights across all athletes, sorted
  List<String> get allHeights {
    final heightsSet = <String>{};
    for (final serie in series) {
      for (final result in serie.results) {
        for (final attempt in result.attempts) {
          heightsSet.add(attempt.height);
        }
      }
    }
    final heights = heightsSet.toList();
    // Sort heights numerically
    heights.sort((a, b) {
      final aNum = double.tryParse(a) ?? 0.0;
      final bNum = double.tryParse(b) ?? 0.0;
      return aNum.compareTo(bNum);
    });
    return heights;
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
  final List<HeightAthleteResult> results;

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
              ?.map((r) => HeightAthleteResult.fromJson(r))
              .toList() ??
          [],
    );
  }
}

class HeightAthleteResult {
  final int displayOrder;
  final int? position;
  final String? athleteStatus;
  final String athleteId;
  final String name;
  final String team;
  final String? country;
  final String? birthDate;
  final int lane;
  final String? time;
  final List<HeightAttempt> attempts;
  final List<String> winds;
  final String? bestMark;
  final bool status;
  final String eventType;

  HeightAthleteResult({
    this.displayOrder = 0,
    this.position,
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

  factory HeightAthleteResult.fromJson(Map<String, dynamic> json) {
    // Parse attempts from JSON strings
    List<HeightAttempt> parseAttempts(List<dynamic>? attemptsJson) {
      if (attemptsJson == null) return [];
      
      return attemptsJson.map((attemptItem) {
        String height = '';
        String result = '';

        if (attemptItem is Map<String, dynamic>) {
          // Ya es un objeto: {"height":"4.59","result":"O"}
          height = attemptItem['height']?.toString() ?? '';
          result = attemptItem['result']?.toString() ?? '';
        } else if (attemptItem is String) {
          // JSON stringificado: "{\"height\":\"4.59\",\"result\":\"——\"}"
          try {
            final decoded = jsonDecode(attemptItem) as Map<String, dynamic>;
            height = decoded['height']?.toString() ?? '';
            result = decoded['result']?.toString() ?? '';
          } catch (_) {
            // Fallback: "height:result" separado por :
            final colonIdx = attemptItem.indexOf(':');
            if (colonIdx > 0) {
              height = attemptItem.substring(0, colonIdx);
              result = attemptItem.substring(colonIdx + 1);
            }
          }
        }

        return HeightAttempt(height: height, result: result);
      }).toList();
    }

    return HeightAthleteResult(
      displayOrder: json['displayOrder'] as int? ?? 0,
      position: json['position'] as int?,
      athleteStatus: json['athleteStatus']?.toString(),
      athleteId: json['athleteId']?.toString() ?? '',
      name: json['name'] ?? '',
      team: json['team'] ?? '',
      country: json['country'],
      birthDate: json['birthDate'],
      lane: json['lane'] ?? 0,
      time: json['time']?.toString(),
      attempts: parseAttempts(json['attempts']),
      winds: (json['winds'] as List<dynamic>?)?.map((w) => w.toString()).toList() ?? [],
      bestMark: _formatHeightMark(json['bestMark']),
      status: json['status'] ?? true,
      eventType: json['eventType'] ?? '',
    );
  }

  /// Formatea una marca de altura a siempre 2 decimales (ej: 5.9 → "5.90")
  static String? _formatHeightMark(dynamic value) {
    if (value == null) return null;
    final d = double.tryParse(value.toString());
    if (d == null) return value.toString();
    return d.toStringAsFixed(2);
  }

  /// Texto de posición: número si tiene posición, athleteStatus si es DNS/DNF/NH/NM
  String get positionText {
    if (position != null) return '${position}°';
    if (athleteStatus != null && athleteStatus!.isNotEmpty) return athleteStatus!;
    return '--';
  }

  /// True si no tiene posición competitiva (DNS/DNF/DQ/NH/NM)
  bool get isDNS {
    // Si tiene tiempo válido → participó, NO es DNS aunque position sea null
    if (bestMark != null) return false;
    // Si tiene athleteStatus explícito (DNS, DNF, DQ, etc.) → sí es DNS
    if (athleteStatus != null && athleteStatus!.isNotEmpty) return true;
    // Sin marca, sin status y sin posición → DNS
    return position == null;
  }

  /// Get the best cleared height (highest O, XO, XXO, etc.)
  String? get bestHeight {
    String? highest;
    double highestValue = 0.0;
    
    for (final attempt in attempts) {
      if (attempt.isCleared) {
        final value = double.tryParse(attempt.height) ?? 0.0;
        if (value > highestValue) {
          highestValue = value;
          highest = attempt.height;
        }
      }
    }
    
    return highest;
  }

  /// Get club formatted for display (splits team into lines)
  String get clubFormatted {
    if (team.isEmpty) return '';
    
    // If team is too long, split it
    if (team.length > 6) {
      final words = team.split(' ');
      if (words.length > 1) {
        return words.take(2).join('\n');
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

class HeightAttempt {
  final String height;
  final String result;

  HeightAttempt({
    required this.height,
    required this.result,
  });

  /// Check if the height was cleared (O after any X's: O, XO, XXO)
  bool get isCleared {
    if (result.isEmpty) return false;
    final last = result[result.length - 1];
    // 'O' (letra) o '0' (dígito, usado en algunos sistemas de datos)
    return last == 'O' || last == 'o' || last == '0';
  }

  /// Check if the height was failed (ends with X = no clear)
  bool get isFailed {
    if (result.isEmpty) return false;
    final last = result[result.length - 1];
    return last == 'X' || last == 'x';
  }

  /// Check if the athlete passed/skipped this height (——, –, -, etc.)
  bool get isPassed {
    if (result.isEmpty) return false;
    // Manejar em-dashes (——), en-dashes (–) y guiones normales (-)
    final stripped = result
        .replaceAll('\u2014', '') // em-dash —
        .replaceAll('\u2013', '') // en-dash –
        .replaceAll('-', '')
        .trim();
    return stripped.isEmpty;
  }

  /// Check if DNS (Did Not Start)
  bool get isDNS {
    return result == 'DNS';
  }

  /// Get attempt status for display
  String get displayResult {
    if (result.isEmpty) return '';
    if (isDNS) return 'DNS';
    if (isPassed) return 'Pass';
    if (isFailed) return 'Failed';
    if (isCleared) return 'Cleared';
    return result;
  }

  /// Count number of misses (X's) in this attempt
  int get missCount {
    return result.split('').where((c) => c == 'X').length;
  }

  /// Count number of clears (O's) in this attempt  
  int get clearCount {
    return result.split('').where((c) => c == 'O').length;
  }
}
