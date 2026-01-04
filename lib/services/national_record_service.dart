import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
}
