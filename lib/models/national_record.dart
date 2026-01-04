/// Modelo para récord nacional
class NationalRecord {
  final String id;
  final String category;
  final String event;
  final String record;
  final String? wind;
  final String athlete;
  final String place;
  final DateTime recordDate;
  final String coach;
  final int rowOrder;
  final bool status;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  NationalRecord({
    required this.id,
    required this.category,
    required this.event,
    required this.record,
    this.wind,
    required this.athlete,
    required this.place,
    required this.recordDate,
    required this.coach,
    required this.rowOrder,
    required this.status,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NationalRecord.fromJson(Map<String, dynamic> json) {
    return NationalRecord(
      id: json['id'] ?? '',
      category: json['category'] ?? '',
      event: json['event'] ?? '',
      record: json['record'] ?? '',
      wind: json['wind'],
      athlete: json['athlete'] ?? '',
      place: json['place'] ?? '',
      recordDate: json['recordDate'] != null 
          ? DateTime.parse(json['recordDate']) 
          : DateTime.now(),
      coach: json['coach'] ?? '',
      rowOrder: json['rowOrder'] ?? 0,
      status: json['status'] ?? true,
      position: json['position'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'event': event,
      'record': record,
      'wind': wind,
      'athlete': athlete,
      'place': place,
      'recordDate': recordDate.toIso8601String(),
      'coach': coach,
      'rowOrder': rowOrder,
      'status': status,
      'position': position,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Modelo para estadísticas de categorías
class CategoryStat {
  final String category;
  final String count;

  CategoryStat({
    required this.category,
    required this.count,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      category: json['category'] ?? '',
      count: json['count']?.toString() ?? '0',
    );
  }
}

/// Modelo para última actualización
class LastUpdate {
  final DateTime date;
  final String fileName;
  final String uploadedBy;
  final int totalRecords;
  final int processingTime;

  LastUpdate({
    required this.date,
    required this.fileName,
    required this.uploadedBy,
    required this.totalRecords,
    required this.processingTime,
  });

  factory LastUpdate.fromJson(Map<String, dynamic> json) {
    return LastUpdate(
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
      fileName: json['fileName'] ?? '',
      uploadedBy: json['uploadedBy'] ?? '',
      totalRecords: json['totalRecords'] ?? 0,
      processingTime: json['processingTime'] ?? 0,
    );
  }
}

/// Modelo para estadísticas de subida
class UploadStats {
  final int total;
  final int successful;
  final int failed;

  UploadStats({
    required this.total,
    required this.successful,
    required this.failed,
  });

  factory UploadStats.fromJson(Map<String, dynamic> json) {
    return UploadStats(
      total: json['total'] ?? 0,
      successful: json['successful'] ?? 0,
      failed: json['failed'] ?? 0,
    );
  }
}

/// Modelo para estadísticas de récords nacionales
class NationalRecordStatistics {
  final int totalRecords;
  final List<CategoryStat> categories;
  final LastUpdate lastUpdate;
  final UploadStats uploadStats;

  NationalRecordStatistics({
    required this.totalRecords,
    required this.categories,
    required this.lastUpdate,
    required this.uploadStats,
  });

  factory NationalRecordStatistics.fromJson(Map<String, dynamic> json) {
    return NationalRecordStatistics(
      totalRecords: json['totalRecords'] ?? 0,
      categories: (json['categories'] as List?)
          ?.map((cat) => CategoryStat.fromJson(cat))
          .toList() ?? [],
      lastUpdate: LastUpdate.fromJson(json['lastUpdate'] ?? {}),
      uploadStats: UploadStats.fromJson(json['uploadStats'] ?? {}),
    );
  }
}
