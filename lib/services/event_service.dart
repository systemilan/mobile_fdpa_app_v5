import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/event.dart';
import '../models/event_list.dart';
import '../models/jornada.dart';
import '../models/result_type1.dart';
import '../models/result_type2.dart';
import '../models/result_type3.dart';
import '../models/calendar_activity.dart';

/// Servicio para consumir la API de eventos
class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  final String _baseUrl = Environment.baseUrl;

  /// Obtener los últimos eventos/campeonatos
  Future<EventsResponse> getLatestEvents() async {
    try {
      final url = Uri.parse('$_baseUrl/public/events/latest');
      
      if (Environment.enableLogs) {
        print('🌐 Fetching latest events from: $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        Environment.connectTimeout,
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (Environment.enableLogs) {
        print('📊 Response status: ${response.statusCode}');
        print('📦 Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final eventsResponse = EventsResponse.fromJson(jsonData);
        
        if (Environment.enableLogs) {
          print('✅ Successfully fetched ${eventsResponse.total} events');
        }
        
        return eventsResponse;
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      if (Environment.enableLogs) {
        print('❌ Error fetching events: $e');
      }
      rethrow;
    }
  }

  /// Obtener un evento por ID (para implementar después)
  Future<Event?> getEventById(String eventId) async {
    try {
      final url = Uri.parse('$_baseUrl/public/events/$eventId');
      
      if (Environment.enableLogs) {
        print('🌐 Fetching event: $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Environment.connectTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        
        // Asumiendo que la respuesta tiene la estructura: {"success": true, "data": {...}}
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return Event.fromJson(jsonData['data']);
        }
        return null;
      } else {
        throw Exception('Failed to load event: ${response.statusCode}');
      }
    } catch (e) {
      if (Environment.enableLogs) {
        print('❌ Error fetching event: $e');
      }
      rethrow;
    }
  }

  /// Obtener las jornadas de un evento
  Future<JornadasResponse> getEventJornadas(String eventId) async {
    try {
      final url = Uri.parse('$_baseUrl/public/events/$eventId/jornadas');
      
      if (Environment.enableLogs) {
        print('🌐 Fetching jornadas for event $eventId from: $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        Environment.connectTimeout,
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (Environment.enableLogs) {
        print('📊 Response status: ${response.statusCode}');
        print('📦 Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final jornadasResponse = JornadasResponse.fromJson(jsonData);
        
        if (Environment.enableLogs) {
          print('✅ Successfully fetched ${jornadasResponse.data.jornadas.length} jornadas');
        }
        
        return jornadasResponse;
      } else {
        throw Exception('Failed to load jornadas: ${response.statusCode}');
      }
    } catch (e) {
      if (Environment.enableLogs) {
        print('❌ Error fetching jornadas: $e');
      }
      rethrow;
    }
  }

  /// Obtener los resultados de una prueba específica (tipo 2 - pruebas de campo)
  Future<ResultType2Response> getEventTestResults(String eventTestId, {String? eventId}) async {
    try {
      Uri url = Uri.parse('$_baseUrl/public/event-tests/$eventTestId/results');

      // Si se proporciona eventId (requerido para pruebas históricas), agregar como query param
      if (eventId != null) {
        url = url.replace(queryParameters: {'eventId': eventId});
      } else if (eventTestId.startsWith('hist-test-')) {
        // Log defensivo: petición histórica sin eventId probablemente fallará en backend
        if (Environment.enableLogs) {
          print('❌ Missing eventId for historical event-test $eventTestId');
        }
      }

      if (Environment.enableLogs) {
        print('🌐 Fetching results for event test $eventTestId from: $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        Environment.connectTimeout,
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (Environment.enableLogs) {
        print('📊 Response status: ${response.statusCode}');
        print('📦 Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final resultsResponse = ResultType2Response.fromJson(jsonData);
        
        if (Environment.enableLogs) {
          print('✅ Successfully fetched results with ${resultsResponse.data.series.length} series');
        }
        
        return resultsResponse;
      } else {
        throw Exception('Failed to load results: ${response.statusCode}');
      }
    } catch (e) {
      if (Environment.enableLogs) {
        print('❌ Error fetching results: $e');
      }
      rethrow;
    }
  }

  /// Obtener los resultados de pruebas de altura (tipo 3 - salto de altura, garrocha, etc.)
  Future<ResultType3Response> getHeightEventResults(String eventTestId, {String? eventId}) async {
    try {
      Uri url = Uri.parse('$_baseUrl/public/event-tests/$eventTestId/results');

      if (eventId != null) {
        url = url.replace(queryParameters: {'eventId': eventId});
      } else if (eventTestId.startsWith('hist-test-')) {
        if (Environment.enableLogs) {
          print('❌ Missing eventId for historical height event-test $eventTestId');
        }
      }

      if (Environment.enableLogs) {
        print('🌐 Fetching height event results for event test $eventTestId from: $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        Environment.connectTimeout,
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (Environment.enableLogs) {
        print('📊 Response status: ${response.statusCode}');
        print('📦 Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final resultsResponse = ResultType3Response.fromJson(jsonData);
        
        if (Environment.enableLogs) {
          print('✅ Successfully fetched height results with ${resultsResponse.data.series.length} series');
        }
        
        return resultsResponse;
      } else {
        throw Exception('Failed to load height results: ${response.statusCode}');
      }
    } catch (e) {
      if (Environment.enableLogs) {
        print('❌ Error fetching height results: $e');
      }
      rethrow;
    }
  }

  /// Obtener los resultados de carreras (tipo 1 - 100m, 200m, 400m, etc.)
  Future<ResultType1Response> getRaceEventResults(String eventTestId, {String? eventId}) async {
    try {
      Uri url = Uri.parse('$_baseUrl/public/event-tests/$eventTestId/results');

      if (eventId != null) {
        url = url.replace(queryParameters: {'eventId': eventId});
      } else if (eventTestId.startsWith('hist-test-')) {
        if (Environment.enableLogs) {
          print('❌ Missing eventId for historical race event-test $eventTestId');
        }
      }

      if (Environment.enableLogs) {
        print('🌐 Fetching race event results for event test $eventTestId from: $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        Environment.connectTimeout,
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (Environment.enableLogs) {
        print('📊 Response status: ${response.statusCode}');
        print('📦 Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final resultsResponse = ResultType1Response.fromJson(jsonData);
        
        if (Environment.enableLogs) {
          print('✅ Successfully fetched race results with ${resultsResponse.data.series.length} series');
        }
        
        return resultsResponse;
      } else {
        throw Exception('Failed to load race results: ${response.statusCode}');
      }
    } catch (e) {
      if (Environment.enableLogs) {
        print('❌ Error fetching race results: $e');
      }
      rethrow;
    }
  }

  /// Obtener todos los eventos
  Future<EventListResponse> getAllEvents() async {
    try {
      // Usar un límite alto para obtener todos los eventos
      // Si en el futuro tienes más eventos, puedes aumentar este número
      final url = Uri.parse('$_baseUrl/public/events?limit=2000');
      
      if (Environment.enableLogs) {
        print('🌐 Fetching all events from: $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        Environment.connectTimeout,
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (Environment.enableLogs) {
        print('📊 Response status: ${response.statusCode}');
        print('📦 Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final eventListResponse = EventListResponse.fromJson(jsonData);
        
        if (Environment.enableLogs) {
          print('✅ Successfully fetched ${eventListResponse.total} events');
        }
        
        return eventListResponse;
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      if (Environment.enableLogs) {
        print('❌ Error fetching all events: $e');
      }
      rethrow;
    }
  }

  /// Obtener todas las actividades del calendario
  Future<CalendarActivitiesResponse> getCalendarActivities() async {
    try {
      // Usar el endpoint público
      final url = Uri.parse('${Environment.baseUrl}/public/calendar-activities');
      
      debugPrint('📅 Fetching calendar activities from: $url');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('📊 Response status: ${response.statusCode}');
      debugPrint('📊 Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        debugPrint('📊 JSON parsed - success: ${jsonResponse['success']}');
        debugPrint('📊 JSON parsed - total: ${jsonResponse['total']}');
        debugPrint('📊 JSON parsed - data length: ${(jsonResponse['data'] as List?)?.length ?? 0}');
        
        final activityResponse = CalendarActivitiesResponse.fromJson(jsonResponse);
        
        debugPrint('✅ Successfully fetched ${activityResponse.total} calendar activities');
        if (activityResponse.data.isNotEmpty) {
          debugPrint('📌 First activity: ${activityResponse.data.first.title}');
        }
        
        return activityResponse;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('❌ Authentication required for calendar-activities endpoint');
        throw Exception('Calendar activities endpoint requires authentication. Status: ${response.statusCode}');
      } else {
        debugPrint('❌ Error response: ${response.body}');
        throw Exception('Failed to load calendar activities: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching calendar activities: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
}
