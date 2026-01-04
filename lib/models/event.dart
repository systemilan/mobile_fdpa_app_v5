/// Modelo para el distrito
class District {
  final String id;
  final String name;
  final String province;
  final String department;

  District({
    required this.id,
    required this.name,
    required this.province,
    required this.department,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      province: json['province'] ?? '',
      department: json['department'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'province': province,
      'department': department,
    };
  }
}

/// Modelo para el estadio
class Stadium {
  final String id;
  final String shortName;
  final String longName;
  final String address;
  final String description;
  final District district;

  Stadium({
    required this.id,
    required this.shortName,
    required this.longName,
    required this.address,
    required this.description,
    required this.district,
  });

  factory Stadium.fromJson(Map<String, dynamic> json) {
    return Stadium(
      id: json['id'] ?? '',
      shortName: json['shortName'] ?? '',
      longName: json['longName'] ?? '',
      address: json['address'] ?? '',
      description: json['description'] ?? '',
      district: District.fromJson(json['district'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shortName': shortName,
      'longName': longName,
      'address': address,
      'description': description,
      'district': district.toJson(),
    };
  }

  // Helper para obtener la ubicación completa
  String get fullLocation {
    return '${district.name}, ${district.province}';
  }
}

/// Modelo para un evento/campeonato
class Event {
  final String id;
  final String shortName;
  final String longName;
  final String dateStart;
  final String dateEnd;
  final Stadium stadium;
  final bool oldHistory; // Campo para identificar eventos históricos

  Event({
    required this.id,
    required this.shortName,
    required this.longName,
    required this.dateStart,
    required this.dateEnd,
    required this.stadium,
    this.oldHistory = false, // Por defecto false
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? '',
      shortName: json['shortName'] ?? '',
      longName: json['longName'] ?? '',
      dateStart: json['dateStart'] ?? '',
      dateEnd: json['dateEnd'] ?? '',
      stadium: Stadium.fromJson(json['stadium'] ?? {}),
      oldHistory: json['oldHistory'] ?? false, // Leer desde la API
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shortName': shortName,
      'longName': longName,
      'dateStart': dateStart,
      'dateEnd': dateEnd,
      'stadium': stadium.toJson(),
      'oldHistory': oldHistory,
    };
  }

  // Helper para obtener el rango de fechas formateado
  String get dateRange {
    return _formatDate(dateStart);
  }

  // Helper para formatear fechas
  String _formatDate(String date) {
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

  // Helper para obtener la ubicación
  String get location {
    return stadium.fullLocation;
  }

  // Helper para obtener dateStart como DateTime
  DateTime? get dateStartParsed {
    try {
      return DateTime.parse(dateStart);
    } catch (e) {
      return null;
    }
  }

  // Helper para obtener dateEnd como DateTime
  DateTime? get dateEndParsed {
    try {
      return DateTime.parse(dateEnd);
    } catch (e) {
      return null;
    }
  }

  // Helper para determinar si es evento histórico
  bool get isHistorical => oldHistory;
}

/// Modelo para la respuesta de la API
class EventsResponse {
  final bool success;
  final List<Event> data;
  final int total;
  final String timestamp;

  EventsResponse({
    required this.success,
    required this.data,
    required this.total,
    required this.timestamp,
  });

  factory EventsResponse.fromJson(Map<String, dynamic> json) {
    return EventsResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => Event.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.map((event) => event.toJson()).toList(),
      'total': total,
      'timestamp': timestamp,
    };
  }

  // Alias para acceder a los eventos más fácilmente
  List<Event> get events => data;
}
