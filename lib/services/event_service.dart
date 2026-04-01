import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import '../config/environment.dart';
import '../models/event.dart';
import '../models/event_list.dart';
import '../models/jornada.dart';
import '../models/result_type1.dart';
import '../models/result_type2.dart';
import '../models/result_type3.dart';
import '../models/athlete_search.dart';
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

  /// Obtener los resultados de una prueba específica.
  /// El backend retorna la misma estructura para los tres tipos;
  /// la pantalla de destino (Type1/Type2/Type3) determina cómo interpretarlos.
  ///
  /// Este método reemplaza los tres anteriores (getEventTestResults,
  /// getRaceEventResults, getHeightEventResults) que apuntaban al mismo endpoint.
  Future<ResultType2Response> getEventTestResults(String eventTestId, {String? eventId}) async {
    try {
      Uri url = Uri.parse('$_baseUrl/public/event-tests/$eventTestId/results');

      if (eventId != null) {
        url = url.replace(queryParameters: {'eventId': eventId});
      } else if (eventTestId.startsWith('hist-test-')) {
        debugPrint('⚠️ [EventService] Petición histórica sin eventId para $eventTestId — puede fallar en backend');
      }

      debugPrint('🌐 [EventService] GET $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        Environment.connectTimeout,
        onTimeout: () {
          throw Exception('Connection timeout al obtener resultados de $eventTestId');
        },
      );

      debugPrint('📊 [EventService] Status: ${response.statusCode}');
      if (response.body.length < 2000) {
        debugPrint('📦 [EventService] Body: ${response.body}');
      } else {
        debugPrint('📦 [EventService] Body (primeros 500 chars): ${response.body.substring(0, 500)}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final resultsResponse = ResultType2Response.fromJson(jsonData);
        debugPrint('✅ [EventService] ${resultsResponse.data.series.length} series obtenidas para $eventTestId');
        return resultsResponse;
      } else {
        throw Exception('Error ${response.statusCode} al obtener resultados de $eventTestId: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [EventService] Error en getEventTestResults($eventTestId): $e');
      rethrow;
    }
  }

  /// Alias para compatibilidad — parsea el mismo endpoint con ResultType1Response
  /// (usado por ResultDetailScreenType2 — carreras con carril y tiempo).
  Future<ResultType1Response> getRaceEventResults(String eventTestId, {String? eventId}) async {
    try {
      Uri url = Uri.parse('$_baseUrl/public/event-tests/$eventTestId/results');
      if (eventId != null) {
        url = url.replace(queryParameters: {'eventId': eventId});
      }
      debugPrint('🌐 [EventService] getRaceEventResults GET $url');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ).timeout(Environment.connectTimeout, onTimeout: () {
        throw Exception('Timeout en getRaceEventResults($eventTestId)');
      });
      debugPrint('📊 [EventService] getRaceEventResults status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return ResultType1Response.fromJson(jsonData);
      }
      throw Exception('Error ${response.statusCode} en getRaceEventResults($eventTestId)');
    } catch (e) {
      debugPrint('❌ [EventService] getRaceEventResults($eventTestId): $e');
      rethrow;
    }
  }

  /// Alias para compatibilidad — parsea el mismo endpoint con ResultType3Response
  /// (usado por ResultDetailScreenType3 — pruebas de altura).
  Future<ResultType3Response> getHeightEventResults(String eventTestId, {String? eventId}) async {
    try {
      Uri url = Uri.parse('$_baseUrl/public/event-tests/$eventTestId/results');
      if (eventId != null) {
        url = url.replace(queryParameters: {'eventId': eventId});
      }
      debugPrint('🌐 [EventService] getHeightEventResults GET $url');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ).timeout(Environment.connectTimeout, onTimeout: () {
        throw Exception('Timeout en getHeightEventResults($eventTestId)');
      });
      debugPrint('📊 [EventService] getHeightEventResults status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return ResultType3Response.fromJson(jsonData);
      }
      throw Exception('Error ${response.statusCode} en getHeightEventResults($eventTestId)');
    } catch (e) {
      debugPrint('❌ [EventService] getHeightEventResults($eventTestId): $e');
      rethrow;
    }
  }

  /// Obtener eventos con filtros opcionales del endpoint público.
  ///
  /// [filter]: all | current-month | year
  /// [year]: requerido cuando filter=year
  /// [limit]: límite de resultados
  Future<EventListResponse> getAllEvents({
    String? filter,
    int limit = 2000,
    int? year,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': '$limit',
      };

      if (filter != null && filter.isNotEmpty) {
        queryParams['filter'] = filter;
      }
      if (year != null) {
        queryParams['year'] = '$year';
      }

      final url = Uri.parse('$_baseUrl/public/events').replace(
        queryParameters: queryParams,
      );
      
      if (Environment.enableLogs) {
        print('🌐 Fetching events from: $url');
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
        print('❌ Error fetching events: $e');
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

  /// Buscar atleta por nombre dentro de un evento
  Future<AthleteSearchResponse> searchAthlete(
      String eventId, String query) async {
    try {
      final url = Uri.parse('$_baseUrl/public/events/$eventId/search-athlete')
          .replace(queryParameters: {'q': query});

      debugPrint('🔍 [EventService] searchAthlete GET $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Environment.connectTimeout, onTimeout: () {
        throw Exception('Timeout en searchAthlete');
      });

      debugPrint('📊 [EventService] searchAthlete status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return AthleteSearchResponse.fromJson(jsonData);
      }
      throw Exception(
          'Error ${response.statusCode} en searchAthlete: ${response.body}');
    } catch (e) {
      debugPrint('❌ [EventService] searchAthlete: $e');
      rethrow;
    }
  }

  /// Buscar atleta dentro de una prueba específica
  /// Endpoint: GET /event-tests/:eventTestId/search-athlete?q=TEXTO
  Future<EventTestSearchResponse> searchAthleteInTest(
      String eventTestId, String query) async {
    try {
      final url =
          Uri.parse('$_baseUrl/public/event-tests/$eventTestId/search-athlete')
              .replace(queryParameters: {'q': query});

      debugPrint('🔍 [EventService] searchAthleteInTest GET $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Environment.connectTimeout, onTimeout: () {
        throw Exception('Timeout en searchAthleteInTest');
      });

      debugPrint(
          '📊 [EventService] searchAthleteInTest status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return EventTestSearchResponse.fromJson(jsonData);
      }
      throw Exception(
          'Error ${response.statusCode} en searchAthleteInTest: ${response.body}');
    } catch (e) {
      debugPrint('❌ [EventService] searchAthleteInTest: $e');
      rethrow;
    }
  }

  /// Búsqueda global de atletas en todos los eventos
  /// [query] nombre o apellido del atleta
  /// [eventId] opcional: filtrar por evento específico
  /// [limit] opcional: limitar resultados (default 50)
  Future<AthleteSearchResponse> searchAthletesGlobal(
    String query, {
    String? eventId,
    int limit = 50,
  }) async {
    try {
      final params = <String, String>{'q': query, 'limit': '$limit'};
      if (eventId != null && eventId.isNotEmpty) {
        params['eventId'] = eventId;
      }

      final url = Uri.parse('${Environment.publicBaseUrl}/athletes/search')
          .replace(queryParameters: params);

      debugPrint('🔍 [EventService] searchAthletesGlobal GET $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Environment.connectTimeout, onTimeout: () {
        throw Exception('Timeout en searchAthletesGlobal');
      });

      debugPrint('📊 [EventService] searchAthletesGlobal status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return AthleteSearchResponse.fromJson(jsonData);
      }
      throw Exception(
          'Error ${response.statusCode} en searchAthletesGlobal: ${response.body}');
    } catch (e) {
      debugPrint('❌ [EventService] searchAthletesGlobal: $e');
      rethrow;
    }
  }

  /// Descargar PDF del calendario de eventos
  Future<String> downloadCalendarPdf() async {
    try {
      if (kIsWeb) {
        throw Exception('La descarga de PDF no está disponible en la versión web. Por favor, usa la aplicación móvil.');
      }

      // Solicitar permisos de almacenamiento solo en Android
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            if (Environment.enableLogs) {
              debugPrint('⚠️ Storage permission not granted, but continuing (Android 13+)');
            }
          }
        }
      }

      final dio = Dio();
      final url = '$_baseUrl/public/calendar-activities/pdf';

      if (Environment.enableLogs) {
        debugPrint('🌐 Downloading Calendar PDF from: $url');
      }

      // Obtener directorio de descargas
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('No se pudo acceder al directorio de descargas');
      }

      // Generar nombre del archivo con fecha actual
      final now = DateTime.now();
      final formattedDate = '${now.day.toString().padLeft(2, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.year}';
      final fileName = 'calendario-fdpa-$formattedDate.pdf';
      final filePath = '${directory.path}/$fileName';

      // Descargar el archivo
      await dio.download(
        url,
        filePath,
        options: Options(
          headers: {
            'Content-Type': 'application/pdf',
            'Accept': 'application/pdf',
          },
        ),
      );

      if (Environment.enableLogs) {
        debugPrint('✅ Calendar PDF downloaded successfully: $filePath');
      }

      // Abrir el archivo automáticamente
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await OpenFilex.open(filePath);
        if (Environment.enableLogs) {
          debugPrint('📄 Open file result: ${result.message}');
        }
      }

      return filePath;
    } catch (e) {
      if (Environment.enableLogs) {
        debugPrint('❌ Error downloading Calendar PDF: $e');
      }
      rethrow;
    }
  }
}
