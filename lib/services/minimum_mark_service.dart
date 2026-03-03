import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../config/environment.dart';
import '../models/minimum_mark.dart';

class MinimumMarkService {
  static final MinimumMarkService _instance = MinimumMarkService._internal();
  factory MinimumMarkService() => _instance;
  MinimumMarkService._internal();

  final String _baseUrl = Environment.publicBaseUrl;

  Future<List<MinimumMarkSet>> getAll() async {
    final url = Uri.parse('$_baseUrl/minimum-marks');
    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    ).timeout(Environment.connectTimeout);

    if (response.statusCode == 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>;
      return data
          .map((e) => MinimumMarkSet.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al obtener marcas mínimas: ${response.statusCode}');
  }

  Future<MinimumMarkDetail> getById(String id) async {
    final url = Uri.parse('$_baseUrl/minimum-marks/$id');
    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    ).timeout(Environment.connectTimeout);

    if (response.statusCode == 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      return MinimumMarkDetail.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception('Error al obtener detalle: ${response.statusCode}');
  }

  Future<void> openFile(String fileUrl, String? fileType) async {
    if (kIsWeb) {
      throw Exception('Descarga no disponible en la versión web. Usa la app móvil.');
    }

    final dio = Dio();
    final ext = fileType == 'pdf' ? 'pdf' : 'jpg';

    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory == null) throw Exception('No se pudo acceder al directorio');

    final fileName = 'marcas-minimas-${DateTime.now().millisecondsSinceEpoch}.$ext';
    final filePath = '${directory.path}/$fileName';

    await dio.download(fileUrl, filePath);
    await OpenFilex.open(filePath);
  }
}
