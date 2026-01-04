import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/environment.dart';
import '../models/national_record.dart';

/// Servicio para consumir la API de récords nacionales
class NationalRecordService {
  static final NationalRecordService _instance = NationalRecordService._internal();
  factory NationalRecordService() => _instance;
  NationalRecordService._internal();

  final String _baseUrl = Environment.baseUrl;

  /// Obtener todas las categorías
  Future<List<String>> getCategories() async {
    try {
      final url = Uri.parse('$_baseUrl/national-records/categories');
      
      if (Environment.enableLogs) {
        print('🌐 Fetching categories from: $url');
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
      }

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((item) => item.toString()).toList();
      } else {
        throw Exception('Error al obtener categorías: ${response.statusCode}');
      }
    } catch (e) {
      if (Environment.enableLogs) {
        print('❌ Error fetching categories: $e');
      }
      rethrow;
    }
  }

  /// Obtener récords por categoría
  Future<List<NationalRecord>> getRecordsByCategory(String category) async {
    try {
      final encodedCategory = Uri.encodeComponent(category);
      final url = Uri.parse('$_baseUrl/national-records/category/$encodedCategory');
      
      if (Environment.enableLogs) {
        print('🌐 Fetching records for category: $category from: $url');
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
      }

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((record) => NationalRecord.fromJson(record)).toList();
      } else {
        throw Exception('Error al obtener récords: ${response.statusCode}');
      }
    } catch (e) {
      if (Environment.enableLogs) {
        print('❌ Error fetching records by category: $e');
      }
      rethrow;
    }
  }

  /// Buscar por atleta
  Future<List<NationalRecord>> searchByAthlete(String name) async {
    try {
      final url = Uri.parse('$_baseUrl/national-records/search/athlete').replace(
        queryParameters: {'name': name},
      );
      
      if (Environment.enableLogs) {
        print('🌐 Searching records by athlete: $name from: $url');
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
      }

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((record) => NationalRecord.fromJson(record)).toList();
      } else {
        throw Exception('Error al buscar atleta: ${response.statusCode}');
      }
    } catch (e) {
      if (Environment.enableLogs) {
        print('❌ Error searching by athlete: $e');
      }
      rethrow;
    }
  }

  /// Buscar por evento
  Future<List<NationalRecord>> searchByEvent(String event) async {
    try {
      final url = Uri.parse('$_baseUrl/national-records/search/event').replace(
        queryParameters: {'event': event},
      );
      
      if (Environment.enableLogs) {
        print('🌐 Searching records by event: $event from: $url');
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
      }

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((record) => NationalRecord.fromJson(record)).toList();
      } else {
        throw Exception('Error al buscar evento: ${response.statusCode}');
      }
    } catch (e) {
      if (Environment.enableLogs) {
        print('❌ Error searching by event: $e');
      }
      rethrow;
    }
  }

  /// Obtener todos los récords
  Future<List<NationalRecord>> getAllRecords() async {
    try {
      final url = Uri.parse('$_baseUrl/national-records');
      
      if (Environment.enableLogs) {
        print('🌐 Fetching all records from: $url');
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
      }

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((record) => NationalRecord.fromJson(record)).toList();
      } else {
        throw Exception('Error al obtener todos los récords: ${response.statusCode}');
      }
    } catch (e) {
      if (Environment.enableLogs) {
        print('❌ Error fetching all records: $e');
      }
      rethrow;
    }
  }

  /// Obtener estadísticas
  Future<NationalRecordStatistics> getStatistics() async {
    try {
      final url = Uri.parse('$_baseUrl/national-records/statistics');
      
      if (Environment.enableLogs) {
        print('🌐 Fetching statistics from: $url');
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
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return NationalRecordStatistics.fromJson(jsonData);
      } else {
        throw Exception('Error al obtener estadísticas: ${response.statusCode}');
      }
    } catch (e) {
      if (Environment.enableLogs) {
        print('❌ Error fetching statistics: $e');
      }
      rethrow;
    }
  }

  /// Descargar PDF de récords nacionales
  Future<String> downloadRecordsPdf() async {
    try {
      // Solicitar permisos de almacenamiento
      if (!kIsWeb && Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            // En Android 13+ (API 33+), los permisos de almacenamiento funcionan diferente
            // No se necesita permiso explícito para guardar en Downloads
            if (Environment.enableLogs) {
              print('⚠️ Storage permission not granted, but continuing (Android 13+)');
            }
          }
        }
      }

      final dio = Dio();
      final url = '$_baseUrl/national-records/pdf';
      
      if (Environment.enableLogs) {
        print('🌐 Downloading PDF from: $url');
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
      final fileName = 'records-nacionales-$formattedDate.pdf';
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
        print('✅ PDF downloaded successfully: $filePath');
      }

      return filePath;
    } catch (e) {
      if (Environment.enableLogs) {
        print('❌ Error downloading PDF: $e');
      }
      rethrow;
    }
  }
}
