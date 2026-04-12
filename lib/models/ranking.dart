/// Modelo para un ranking nacional (cabecera)
class RankingMaster {
  final String id;
  final int year;
  final String gender; // "M" | "F"
  final String category; // "U18" | "U20" | "MAYORES"
  final String label;
  final String rankingStatus; // "published" | "archived"
  final DateTime publishedAt;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  RankingMaster({
    required this.id,
    required this.year,
    required this.gender,
    required this.category,
    required this.label,
    required this.rankingStatus,
    required this.publishedAt,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RankingMaster.fromJson(Map<String, dynamic> json) {
    return RankingMaster(
      id: json['id'] ?? '',
      year: json['year'] is int
          ? json['year']
          : int.tryParse(json['year'].toString()) ?? 0,
      gender: json['gender'] ?? 'M',
      category: json['category'] ?? 'MAYORES',
      label: json['label'] ?? '',
      rankingStatus: json['rankingStatus'] ?? 'published',
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      archivedAt: json['archivedAt'] != null
          ? DateTime.tryParse(json['archivedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// "Damas" | "Varones"
  String get genderLabel => gender == 'F' ? 'Damas' : 'Varones';

  /// "Sub 18" | "Sub 20" | "Mayores"
  String get categoryLabel {
    switch (category) {
      case 'U18':
        return 'Sub 18';
      case 'U20':
        return 'Sub 20';
      case 'MAYORES':
        return 'Mayores';
      default:
        return category;
    }
  }

  bool get isPublished => rankingStatus == 'published';
  bool get isArchived => rankingStatus == 'archived';

  String get formattedPublishedAt {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    final dt = publishedAt.toLocal();
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }
}

/// Entrada de atleta dentro de una disciplina
class RankingEntry {
  final String id;
  final String rankingId;
  final String discipline;
  final int disciplineOrder;
  final int rankPosition;
  final String mark;
  final String? wind;
  final String athleteName;
  final String? club;
  final String? birthDate;
  final String? competitionName;
  final String? competitionDate;
  final String? notes;
  final bool isManual;
  final DateTime createdAt;
  final DateTime updatedAt;

  RankingEntry({
    required this.id,
    required this.rankingId,
    required this.discipline,
    required this.disciplineOrder,
    required this.rankPosition,
    required this.mark,
    this.wind,
    required this.athleteName,
    this.club,
    this.birthDate,
    this.competitionName,
    this.competitionDate,
    this.notes,
    required this.isManual,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      id: json['id'] ?? '',
      rankingId: json['rankingId'] ?? '',
      discipline: json['discipline'] ?? '',
      disciplineOrder: json['disciplineOrder'] is int
          ? json['disciplineOrder']
          : int.tryParse(json['disciplineOrder'].toString()) ?? 0,
      rankPosition: json['rankPosition'] is int
          ? json['rankPosition']
          : int.tryParse(json['rankPosition'].toString()) ?? 0,
      mark: json['mark']?.toString() ?? '',
      wind: json['wind']?.toString(),
      athleteName: json['athleteName'] ?? '',
      club: json['club']?.toString(),
      birthDate: json['birthDate']?.toString(),
      competitionName: json['competitionName']?.toString(),
      competitionDate: json['competitionDate']?.toString(),
      notes: json['notes']?.toString(),
      isManual: json['isManual'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Nombre del atleta en formato título (Cayetana Chirinos Asalde)
  String get athleteNameFormatted {
    return athleteName.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Fecha de competencia formateada (31 Oct 2025)
  String? get formattedCompetitionDate {
    if (competitionDate == null) return null;
    try {
      // birthDate y competitionDate vienen en YYYY-MM-DD
      final dt = DateTime.parse('${competitionDate}T00:00:00');
      const months = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return competitionDate;
    }
  }

  /// Fecha de nacimiento formateada (26 Ene 2008)
  String? get formattedBirthDate {
    if (birthDate == null) return null;
    try {
      final dt = DateTime.parse('${birthDate}T00:00:00');
      const months = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return birthDate;
    }
  }
}

/// Disciplina dentro de un ranking (agrupa entradas)
class RankingDiscipline {
  final String name;
  final int disciplineOrder;
  final List<RankingEntry> entries;

  RankingDiscipline({
    required this.name,
    required this.disciplineOrder,
    required this.entries,
  });

  factory RankingDiscipline.fromJson(Map<String, dynamic> json) {
    final entriesJson = json['entries'] as List<dynamic>? ?? [];
    return RankingDiscipline(
      name: json['name']?.toString() ?? '',
      disciplineOrder: json['disciplineOrder'] is int
          ? json['disciplineOrder']
          : int.tryParse(json['disciplineOrder'].toString()) ?? 0,
      entries: entriesJson
          .map((e) => RankingEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Resultado de búsqueda de atleta en rankings (endpoint /rankings/search-athlete)
class RankingAthleteSearchResult {
  final String rankingId;
  final int year;
  final String gender;
  final String category;
  final String label;
  final String? lastEventDate;
  final String id;
  final String discipline;
  final int rankPosition;
  final String mark;
  final String? wind;
  final bool isWindAssisted;
  final String athleteName;
  final String? club;
  final String? birthDate;
  final String? competitionName;
  final String? competitionDate;
  final bool isManual;

  const RankingAthleteSearchResult({
    required this.rankingId,
    required this.year,
    required this.gender,
    required this.category,
    required this.label,
    this.lastEventDate,
    required this.id,
    required this.discipline,
    required this.rankPosition,
    required this.mark,
    this.wind,
    required this.isWindAssisted,
    required this.athleteName,
    this.club,
    this.birthDate,
    this.competitionName,
    this.competitionDate,
    required this.isManual,
  });

  factory RankingAthleteSearchResult.fromJson(Map<String, dynamic> json) {
    return RankingAthleteSearchResult(
      rankingId: json['rankingId'] ?? '',
      year: json['year'] is int
          ? json['year']
          : int.tryParse(json['year'].toString()) ?? 0,
      gender: json['gender'] ?? 'M',
      category: json['category'] ?? 'MAYORES',
      label: json['label'] ?? '',
      lastEventDate: json['lastEventDate']?.toString(),
      id: json['id'] ?? '',
      discipline: json['discipline'] ?? '',
      rankPosition: json['rankPosition'] is int
          ? json['rankPosition']
          : int.tryParse(json['rankPosition'].toString()) ?? 0,
      mark: json['mark']?.toString() ?? '',
      wind: json['wind']?.toString(),
      isWindAssisted: json['isWindAssisted'] == true,
      athleteName: json['athleteName'] ?? '',
      club: json['club']?.toString(),
      birthDate: json['birthDate']?.toString(),
      competitionName: json['competitionName']?.toString(),
      competitionDate: json['competitionDate']?.toString(),
      isManual: json['isManual'] == true,
    );
  }

  /// Marca a mostrar: si tiene viento asistido agrega " w"
  String get displayMark => isWindAssisted ? '$mark w' : mark;

  String get genderLabel => gender == 'F' ? 'Damas' : 'Varones';

  String get categoryLabel {
    switch (category) {
      case 'U18': return 'Sub 18';
      case 'U20': return 'Sub 20';
      case 'MAYORES': return 'Mayores';
      default: return category;
    }
  }

  String get athleteNameFormatted {
    return athleteName.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  String? get formattedCompetitionDate {
    if (competitionDate == null) return null;
    try {
      final dt = DateTime.parse('${competitionDate}T00:00:00');
      const months = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return competitionDate;
    }
  }
}

/// Detalle completo de un ranking (incluye disciplines)
class RankingDetail extends RankingMaster {
  final List<RankingDiscipline> disciplines;

  RankingDetail({
    required super.id,
    required super.year,
    required super.gender,
    required super.category,
    required super.label,
    required super.rankingStatus,
    required super.publishedAt,
    super.archivedAt,
    required super.createdAt,
    required super.updatedAt,
    required this.disciplines,
  });

  factory RankingDetail.fromJson(Map<String, dynamic> json) {
    final disciplinesJson = json['disciplines'] as List<dynamic>? ?? [];
    return RankingDetail(
      id: json['id'] ?? '',
      year: json['year'] is int
          ? json['year']
          : int.tryParse(json['year'].toString()) ?? 0,
      gender: json['gender'] ?? 'M',
      category: json['category'] ?? 'MAYORES',
      label: json['label'] ?? '',
      rankingStatus: json['rankingStatus'] ?? 'published',
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      archivedAt: json['archivedAt'] != null
          ? DateTime.tryParse(json['archivedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      disciplines: disciplinesJson
          .map((d) => RankingDiscipline.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Retorna todas las entradas de todas las disciplinas como lista plana
  List<RankingEntry> get allEntries {
    return disciplines.expand((d) => d.entries).toList();
  }
}
