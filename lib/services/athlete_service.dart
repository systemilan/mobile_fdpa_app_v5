import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/athlete_profile.dart';

class AthleteService {
  static final AthleteService _instance = AthleteService._internal();
  factory AthleteService() => _instance;
  AthleteService._internal();

  final String _base = '${Environment.publicBaseUrl}/athletes';

  Future<AthleteProfile> getProfile(String name) async {
    final url = Uri.parse('$_base/profile').replace(
      queryParameters: {'q': name},
    );

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    ).timeout(Environment.connectTimeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AthleteProfile.fromJson(json['data'] as Map<String, dynamic>);
    } else if (response.statusCode == 404) {
      throw AthleteNotFoundException();
    } else {
      throw Exception('Error ${response.statusCode} al obtener perfil de atleta');
    }
  }
}

class AthleteNotFoundException implements Exception {}
