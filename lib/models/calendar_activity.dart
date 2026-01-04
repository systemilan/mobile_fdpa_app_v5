import 'package:flutter/material.dart';

/// Modelo para actividades del calendario
class CalendarActivity {
  final String id;
  final String createdAt;
  final String updatedAt;
  final bool status;
  final int position;
  final String title;
  final String description;
  final String dateStart;
  final String dateEnd;
  final String type; // national, international, regional
  final String? color;
  final String location;
  final bool isPublic;
  final String? eventId;
  final dynamic event;

  CalendarActivity({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.position,
    required this.title,
    required this.description,
    required this.dateStart,
    required this.dateEnd,
    required this.type,
    this.color,
    required this.location,
    required this.isPublic,
    this.eventId,
    this.event,
  });

  factory CalendarActivity.fromJson(Map<String, dynamic> json) {
    return CalendarActivity(
      id: json['id'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      status: json['status'] ?? true,
      position: json['position'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dateStart: json['dateStart'] ?? '',
      dateEnd: json['dateEnd'] ?? '',
      type: json['type'] ?? 'national',
      color: json['color'],
      location: json['location'] ?? '',
      isPublic: json['isPublic'] ?? true,
      eventId: json['eventId'],
      event: json['event'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'status': status,
      'position': position,
      'title': title,
      'description': description,
      'dateStart': dateStart,
      'dateEnd': dateEnd,
      'type': type,
      'color': color,
      'location': location,
      'isPublic': isPublic,
      'eventId': eventId,
      'event': event,
    };
  }

  // Helper para obtener el rango de fechas formateado
  String get formattedDateRange {
    try {
      final start = DateTime.parse(dateStart);
      final end = DateTime.parse(dateEnd);
      
      final List<String> months = [
        'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
        'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
      ];
      
      if (dateStart == dateEnd) {
        // Mismo día
        return '${start.day} de ${months[start.month - 1]} ${start.year}';
      } else if (start.month == end.month && start.year == end.year) {
        // Mismo mes y año
        return '${start.day}-${end.day} de ${months[start.month - 1]} ${start.year}';
      } else if (start.year == end.year) {
        // Mismo año, diferente mes
        return '${start.day} ${months[start.month - 1]} - ${end.day} ${months[end.month - 1]} ${start.year}';
      } else {
        // Años diferentes
        return '${start.day} ${months[start.month - 1]} ${start.year} - ${end.day} ${months[end.month - 1]} ${end.year}';
      }
    } catch (e) {
      return '$dateStart - $dateEnd';
    }
  }

  // Helper para obtener solo la fecha de inicio formateada
  String get formattedStartDate {
    try {
      final date = DateTime.parse(dateStart);
      final List<String> months = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
      ];
      return '${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return dateStart;
    }
  }

  // Helper para obtener el tipo formateado
  String get typeFormatted {
    switch (type) {
      case 'national':
        return 'Nacional';
      case 'international':
        return 'Internacional';
      case 'regional':
        return 'Regional';
      default:
        return type;
    }
  }

  // Helper para obtener el color según el tipo
  Color get typeColor {
    switch (type) {
      case 'national':
        return const Color(0xFFD91023); // Rojo FDPA
      case 'international':
        return const Color(0xFF2196F3); // Azul
      case 'regional':
        return const Color(0xFFFF9800); // Naranja
      default:
        return const Color(0xFF666666); // Gris
    }
  }

  // Helper para verificar si es próximo (dentro de los próximos 60 días)
  bool get isUpcoming {
    try {
      final now = DateTime.now();
      final start = DateTime.parse(dateStart);
      final difference = start.difference(now).inDays;
      return difference >= 0 && difference <= 60;
    } catch (e) {
      return false;
    }
  }

  // Helper para verificar si ya pasó
  bool get isPast {
    try {
      final now = DateTime.now();
      final end = DateTime.parse(dateEnd);
      return end.isBefore(now);
    } catch (e) {
      return false;
    }
  }

  // Helper para verificar si es multi-día
  bool get isMultiDay {
    try {
      final start = DateTime.parse(dateStart);
      final end = DateTime.parse(dateEnd);
      return !start.isAtSameMomentAs(end);
    } catch (e) {
      return false;
    }
  }

  // Helper para obtener días hasta el evento
  int get daysUntil {
    try {
      final now = DateTime.now();
      final start = DateTime.parse(dateStart);
      return start.difference(now).inDays;
    } catch (e) {
      return -1;
    }
  }

  // Alias para compatibilidad con el código del home_screen
  int get daysUntilStart => daysUntil;
  
  // Helper para obtener días restantes del evento
  int get daysRemaining {
    try {
      final now = DateTime.now();
      final end = DateTime.parse(dateEnd);
      return end.difference(now).inDays;
    } catch (e) {
      return -1;
    }
  }

  // Helper para formatear la duración
  String get formattedDuration {
    try {
      final start = DateTime.parse(dateStart);
      final end = DateTime.parse(dateEnd);
      final duration = end.difference(start).inDays;
      
      if (duration == 0) {
        return '1 día';
      } else if (duration == 1) {
        return '2 días';
      } else {
        return '${duration + 1} días';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  // Helper para obtener fecha de inicio parseada
  DateTime? get dateStartParsed {
    try {
      return DateTime.parse(dateStart);
    } catch (e) {
      return null;
    }
  }

  // Helper para obtener fecha de fin parseada
  DateTime? get dateEndParsed {
    try {
      return DateTime.parse(dateEnd);
    } catch (e) {
      return null;
    }
  }
}

/// Modelo para la respuesta de la API de actividades
class CalendarActivitiesResponse {
  final bool success;
  final List<CalendarActivity> data;
  final int total;

  CalendarActivitiesResponse({
    required this.success,
    required this.data,
    required this.total,
  });

  factory CalendarActivitiesResponse.fromJson(Map<String, dynamic> json) {
    return CalendarActivitiesResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => CalendarActivity.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.map((activity) => activity.toJson()).toList(),
      'total': total,
    };
  }

  // Alias para acceder a las actividades más fácilmente
  List<CalendarActivity> get activities => data;
}
