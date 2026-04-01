import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/ranking.dart';

/// Servicio para consumir la API de Rankings Nacionales
class RankingService {
  static final RankingService _instance = RankingService._internal();
  factory RankingService() => _instance;
  RankingService._internal();

  final String _baseUrl = Environment.baseUrl;

  /// Lista todos los rankings publicados/archivados.
  /// Parámetros opcionales: [year], [gender] ("M"|"F"), [category] ("U18"|"U20"|"MAYORES")
  Future<List<RankingMaster>> getRankings({
    int? year,
    String? gender,
    String? category,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (year != null) queryParams['year'] = '$year';
      if (gender != null) queryParams['gender'] = gender;
      if (category != null) queryParams['category'] = category;

      final url = Uri.parse('$_baseUrl/public/rankings')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      if (Environment.enableLogs) {
        debugPrint('🏆 Fetching rankings from: $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        Environment.connectTimeout,
        onTimeout: () => throw Exception('Connection timeout'),
      );

      if (Environment.enableLogs) {
        debugPrint('📊 Rankings response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData['ok'] == true || jsonData['data'] != null) {
          final List<dynamic> dataList = jsonData['data'] ?? [];
          final rankings =
              dataList.map((e) => RankingMaster.fromJson(e as Map<String, dynamic>)).toList();
          if (Environment.enableLogs) {
            debugPrint('✅ Loaded ${rankings.length} rankings');
          }
          return rankings;
        }
        return [];
      } else {
        throw Exception('Error al cargar rankings: ${response.statusCode}');
      }
    } catch (e) {
      if (Environment.enableLogs) {
        debugPrint('❌ Error fetching rankings: $e');
      }
      rethrow;
    }
  }

  /// Detalle de un ranking con todas las disciplinas y atletas agrupados.
  /// Lanza excepción si el ranking no existe o no está publicado (404).
  Future<RankingDetail> getRankingDetail(String id) async {
    try {
      final url = Uri.parse('$_baseUrl/public/rankings/$id');

      if (Environment.enableLogs) {
        debugPrint('🏆 Fetching ranking detail: $url');
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        Environment.connectTimeout,
        onTimeout: () => throw Exception('Connection timeout'),
      );

      if (Environment.enableLogs) {
        debugPrint('📊 Ranking detail status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData['ok'] == true || jsonData['data'] != null) {
          final detail = RankingDetail.fromJson(
              jsonData['data'] as Map<String, dynamic>);
          if (Environment.enableLogs) {
            debugPrint(
                '✅ Loaded ranking detail: ${detail.disciplines.length} disciplines');
          }
          return detail;
        }
        throw Exception('Ranking no encontrado');
      } else if (response.statusCode == 404) {
        throw Exception('Ranking no encontrado o no publicado');
      } else {
        throw Exception('Error al cargar detalle: ${response.statusCode}');
      }
    } catch (e) {
      if (Environment.enableLogs) {
        debugPrint('❌ Error fetching ranking detail: $e');
      }
      rethrow;
    }
  }
}
