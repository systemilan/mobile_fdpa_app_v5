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
  final int? position;
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

  factory HeightAthleteResult.fromJson(Map<String, dynamic> json) {
    // Parse attempts from JSON strings
    List<HeightAttempt> parseAttempts(List<dynamic>? attemptsJson) {
      if (attemptsJson == null) return [];
      
      return attemptsJson.map((attemptStr) {
        if (attemptStr is String) {
          try {
            // Parse the JSON string like: {"height":"1.88","result":"---"}
            final attemptJson = attemptStr.replaceAll('{', '{"')
                .replaceAll(':', '":"')
                .replaceAll(',', '","')
                .replaceAll('}', '"}')
                .replaceAll('""', '"');
            
            // Simple parse
            final heightMatch = RegExp(r'"height":"([^"]+)"').firstMatch(attemptStr);
            final resultMatch = RegExp(r'"result":"([^"]*)"').firstMatch(attemptStr);
            
            final height = heightMatch?.group(1) ?? '';
            final result = resultMatch?.group(1) ?? '';
            
            return HeightAttempt(height: height, result: result);
          } catch (e) {
            return HeightAttempt(height: '', result: '');
          }
        }
        return HeightAttempt(height: '', result: '');
      }).toList();
    }

    return HeightAthleteResult(
      position: json['position'],
      athleteId: json['athleteId']?.toString() ?? '',
      name: json['name'] ?? '',
      team: json['team'] ?? '',
      country: json['country'],
      birthDate: json['birthDate'],
      lane: json['lane'] ?? 0,
      time: json['time'],
      attempts: parseAttempts(json['attempts']),
      winds: (json['winds'] as List<dynamic>?)?.map((w) => w.toString()).toList() ?? [],
      bestMark: json['bestMark'],
      status: json['status'] ?? true,
      eventType: json['eventType'] ?? '',
    );
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

  /// Check if the height was cleared (O, XO, XXO, -XO, X-O, etc.)
  bool get isCleared {
    return result.contains('O') && !result.startsWith('X') && result != 'XXX';
  }

  /// Check if the height was failed (XXX or three X's)
  bool get isFailed {
    return result == 'XXX' || result.replaceAll('-', '').length >= 3;
  }

  /// Check if the athlete passed/skipped this height (---, --, etc.)
  bool get isPassed {
    return result.replaceAll('-', '').isEmpty && result.isNotEmpty;
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
