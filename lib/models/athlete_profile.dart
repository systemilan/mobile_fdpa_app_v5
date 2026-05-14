class AthleteIdentity {
  final String canonicalName;
  final List<String> nameVariants;
  final String? birthDate;
  final String? ageCategory;
  final String? gender;
  final String club;
  final String country;

  AthleteIdentity({
    required this.canonicalName,
    required this.nameVariants,
    this.birthDate,
    this.ageCategory,
    this.gender,
    required this.club,
    required this.country,
  });

  factory AthleteIdentity.fromJson(Map<String, dynamic> j) => AthleteIdentity(
        canonicalName: j['canonicalName'] ?? '',
        nameVariants: List<String>.from(j['nameVariants'] ?? []),
        birthDate: j['birthDate'],
        ageCategory: j['ageCategory'],
        gender: j['gender'],
        club: j['club'] ?? '',
        country: j['country'] ?? '',
      );
}

class AthleteSB {
  final String mark;
  final String? wind;
  final String? date;
  final String? competition;

  AthleteSB({required this.mark, this.wind, this.date, this.competition});

  factory AthleteSB.fromJson(Map<String, dynamic> j) => AthleteSB(
        mark: j['mark'] ?? '',
        wind: j['wind'],
        date: j['date'],
        competition: j['competition'],
      );
}

class AthleteBestMark {
  final String discipline;
  final String mark;
  final String? wind;
  final String eventType;
  final String? date;
  final String? competition;
  final String? position;
  final AthleteSB? sb;

  AthleteBestMark({
    required this.discipline,
    required this.mark,
    this.wind,
    required this.eventType,
    this.date,
    this.competition,
    this.position,
    this.sb,
  });

  factory AthleteBestMark.fromJson(Map<String, dynamic> j) => AthleteBestMark(
        discipline: j['discipline'] ?? '',
        mark: j['mark'] ?? '',
        wind: j['wind'],
        eventType: j['eventType'] ?? '',
        date: j['date'],
        competition: j['competition'],
        position: j['position'],
        sb: j['sb'] != null ? AthleteSB.fromJson(j['sb'] as Map<String, dynamic>) : null,
      );
}

class AthleteRanking {
  final int year;
  final String gender;
  final String category;
  final String discipline;
  final int position;
  final String mark;
  final String? wind;
  final bool isWindAssisted;

  AthleteRanking({
    required this.year,
    required this.gender,
    required this.category,
    required this.discipline,
    required this.position,
    required this.mark,
    this.wind,
    required this.isWindAssisted,
  });

  factory AthleteRanking.fromJson(Map<String, dynamic> j) => AthleteRanking(
        year: j['year'] ?? 0,
        gender: j['gender'] ?? '',
        category: j['category'] ?? '',
        discipline: j['discipline'] ?? '',
        position: j['position'] ?? 0,
        mark: j['mark'] ?? '',
        wind: j['wind'],
        isWindAssisted: j['isWindAssisted'] ?? false,
      );
}

class AthleteNationalRecord {
  final String category;
  final String discipline;
  final String mark;
  final String? wind;
  final String? date;
  final String? place;

  AthleteNationalRecord({
    required this.category,
    required this.discipline,
    required this.mark,
    this.wind,
    this.date,
    this.place,
  });

  factory AthleteNationalRecord.fromJson(Map<String, dynamic> j) => AthleteNationalRecord(
        category: j['category'] ?? '',
        discipline: j['discipline'] ?? '',
        mark: j['mark'] ?? '',
        wind: j['wind'],
        date: j['date'],
        place: j['place'],
      );
}

class AthleteTimelineEntry {
  final String date;
  final String? competition;
  final String discipline;
  final String mark;
  final String? wind;
  final String? position;
  final String? status;
  final String eventType;

  AthleteTimelineEntry({
    required this.date,
    this.competition,
    required this.discipline,
    required this.mark,
    this.wind,
    this.position,
    this.status,
    required this.eventType,
  });

  factory AthleteTimelineEntry.fromJson(Map<String, dynamic> j) => AthleteTimelineEntry(
        date: j['date'] ?? '',
        competition: j['competition'],
        discipline: j['discipline'] ?? '',
        mark: j['mark'] ?? '',
        wind: j['wind'],
        position: j['position'],
        status: j['status'],
        eventType: j['eventType'] ?? '',
      );
}

class AthleteProfile {
  final AthleteIdentity identity;
  final List<AthleteBestMark> bestMarks;
  final List<AthleteRanking> rankings;
  final List<AthleteNationalRecord> nationalRecords;
  final List<AthleteTimelineEntry> timeline;

  AthleteProfile({
    required this.identity,
    required this.bestMarks,
    required this.rankings,
    required this.nationalRecords,
    required this.timeline,
  });

  factory AthleteProfile.fromJson(Map<String, dynamic> j) => AthleteProfile(
        identity: AthleteIdentity.fromJson(j['identity'] ?? {}),
        bestMarks: (j['bestMarks'] as List<dynamic>? ?? [])
            .map((e) => AthleteBestMark.fromJson(e))
            .toList(),
        rankings: (j['rankings'] as List<dynamic>? ?? [])
            .map((e) => AthleteRanking.fromJson(e))
            .toList(),
        nationalRecords: (j['nationalRecords'] as List<dynamic>? ?? [])
            .map((e) => AthleteNationalRecord.fromJson(e))
            .toList(),
        timeline: (j['timeline'] as List<dynamic>? ?? [])
            .map((e) => AthleteTimelineEntry.fromJson(e))
            .toList(),
      );
}
