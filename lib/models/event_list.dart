class EventListResponse {
  final bool success;
  final List<EventItem> data;
  final int total;
  final String timestamp;

  EventListResponse({
    required this.success,
    required this.data,
    required this.total,
    required this.timestamp,
  });

  factory EventListResponse.fromJson(Map<String, dynamic> json) {
    return EventListResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => EventItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class EventItem {
  final String id;
  final String shortName;
  final String longName;
  final String dateStart;
  final String dateEnd;
  final Stadium stadium;

  EventItem({
    required this.id,
    required this.shortName,
    required this.longName,
    required this.dateStart,
    required this.dateEnd,
    required this.stadium,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      id: json['id'] ?? '',
      shortName: json['shortName'] ?? '',
      longName: json['longName'] ?? '',
      dateStart: json['dateStart'] ?? '',
      dateEnd: json['dateEnd'] ?? '',
      stadium: Stadium.fromJson(json['stadium'] ?? {}),
    );
  }

  // Formatear fechas
  String get formattedDateRange {
    if (dateStart.isEmpty) return '';
    
    try {
      final start = DateTime.parse(dateStart);
      final end = DateTime.parse(dateEnd);
      
      final months = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      
      if (start.year == end.year && start.month == end.month && start.day == end.day) {
        // Mismo día
        return '${start.day} ${months[start.month - 1]} ${start.year}';
      } else if (start.year == end.year && start.month == end.month) {
        // Mismo mes
        return '${start.day} - ${end.day} ${months[start.month - 1]} ${start.year}';
      } else if (start.year == end.year) {
        // Mismo año
        return '${start.day} ${months[start.month - 1]} - ${end.day} ${months[end.month - 1]} ${start.year}';
      } else {
        // Diferente año
        return '${start.day} ${months[start.month - 1]} ${start.year} - ${end.day} ${months[end.month - 1]} ${end.year}';
      }
    } catch (e) {
      return dateStart;
    }
  }

  String get year {
    try {
      final start = DateTime.parse(dateStart);
      return start.year.toString();
    } catch (e) {
      return '';
    }
  }
  
  // Formatear solo fecha de inicio
  String get formattedStartDate {
    if (dateStart.isEmpty) return '';
    
    try {
      final start = DateTime.parse(dateStart);
      
      final months = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      
      return '${start.day} ${months[start.month - 1]} ${start.year}';
    } catch (e) {
      return dateStart;
    }
  }
}

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

  String get locationFormatted {
    final parts = <String>[];
    if (district.name.isNotEmpty) parts.add(district.name);
    if (district.province.isNotEmpty && district.province != district.name) {
      parts.add(district.province);
    }
    return parts.join(', ');
  }
}

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
}
