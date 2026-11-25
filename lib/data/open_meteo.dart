import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/place.dart';
import '../models/weather.dart';

class WeatherRequestException implements Exception {
  const WeatherRequestException(this.message);
  final String message;
}

class OpenMeteo {
  OpenMeteo(this._client);
  final http.Client _client;

  Future<List<Place>> search(String query) async {
    final text = query.trim();
    if (text.length < 2) return const [];
    final data = await _get(
      Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': text,
        'count': '10',
        'language': 'id',
        'format': 'json',
      }),
    );
    final raw = data['results'];
    if (raw == null) return const [];
    if (raw is! List) {
      throw const WeatherRequestException(
        'Format hasil pencarian tidak valid.',
      );
    }
    final places = <int, Place>{};
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        try {
          final place = Place.fromJson(item);
          places[place.id] = place;
        } on FormatException {
          // Hasil bermasalah tidak menghalangi pilihan lain yang valid.
        } on TypeError {
          continue;
        }
      }
    }
    return List.unmodifiable(places.values);
  }

  Future<WeatherReport> forecast(Place place) async {
    final data = await _get(
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '${place.latitude}',
        'longitude': '${place.longitude}',
        'current':
            'temperature_2m,relative_humidity_2m,apparent_temperature,'
            'precipitation,weather_code,wind_speed_10m,is_day',
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
        'timezone': 'auto',
        'forecast_days': '7',
        'temperature_unit': 'celsius',
        'wind_speed_unit': 'kmh',
        'precipitation_unit': 'mm',
      }),
    );
    return WeatherReport.fromJson(data);
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    try {
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 429) {
        throw const WeatherRequestException(
          'Terlalu banyak permintaan. Coba lagi sebentar.',
        );
      }
      if (response.statusCode != 200) {
        throw WeatherRequestException(
          'Open-Meteo tidak dapat memproses permintaan (${response.statusCode}).',
        );
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic> || data['error'] == true) {
        throw const FormatException();
      }
      return data;
    } on TimeoutException {
      throw const WeatherRequestException(
        'Waktu tunggu habis. Periksa koneksi internetmu.',
      );
    } on http.ClientException {
      throw const WeatherRequestException(
        'Tidak dapat terhubung. Periksa koneksi internetmu.',
      );
    } on FormatException {
      throw const WeatherRequestException(
        'Respons Open-Meteo tidak dapat dibaca.',
      );
    }
  }
}
