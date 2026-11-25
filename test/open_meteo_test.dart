import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:langit_kota/data/open_meteo.dart';
import 'package:langit_kota/models/place.dart';
import 'package:langit_kota/models/weather.dart';

void main() {
  test(
    'GET geocoding mengenkode kueri dan mengubah JSON menjadi Place',
    () async {
      final api = OpenMeteo(
        MockClient((req) async {
          expect(req.method, 'GET');
          expect(req.url.host, 'geocoding-api.open-meteo.com');
          expect(req.url.path, '/v1/search');
          expect(req.url.queryParameters['name'], 'New York');
          expect(req.url.queryParameters['language'], 'id');
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 5128581,
                  'name': 'New York',
                  'latitude': 40.71,
                  'longitude': -74.01,
                  'admin1': 'New York',
                  'country': 'Amerika Serikat',
                },
              ],
            }),
            200,
          );
        }),
      );
      final result = await api.search('  New York  ');
      expect(result.single.id, 5128581);
      expect(result.single.detail, 'Amerika Serikat');
    },
  );

  test('geocoding tanpa results adalah daftar kosong', () async {
    final api = OpenMeteo(MockClient((_) async => http.Response('{}', 200)));
    expect(await api.search('tidak ditemukan'), isEmpty);
  });

  test(
    'forecast meminta satuan dan field yang benar; peluang nol valid',
    () async {
      final api = OpenMeteo(
        MockClient((req) async {
          final params = req.url.queryParameters;
          expect(req.method, 'GET');
          expect(req.url.host, 'api.open-meteo.com');
          expect(params['timezone'], 'auto');
          expect(params['forecast_days'], '7');
          expect(params['latitude'], '${Place.initial.latitude}');
          expect(params['longitude'], '${Place.initial.longitude}');
          expect(
            params['current']!.split(','),
            containsAll([
              'temperature_2m',
              'relative_humidity_2m',
              'apparent_temperature',
              'precipitation',
              'weather_code',
              'wind_speed_10m',
            ]),
          );
          expect(
            params['daily']!.split(','),
            containsAll([
              'temperature_2m_min',
              'temperature_2m_max',
              'precipitation_probability_max',
              'weather_code',
            ]),
          );
          return http.Response(jsonEncode(forecastFixture), 200);
        }),
      );
      final weather = await api.forecast(Place.initial);
      expect(weather.current.temperature, 24.5);
      expect(weather.current.humidity, 90);
      expect(weather.current.apparent, 27.8);
      expect(weather.current.precipitation, 0.1);
      expect(weather.current.wind, 3.2);
      expect(weather.current.isDay, isFalse);
      expect(weather.days.first.rainChance, 0);
      expect(weather.days.last.rainChance, isNull);
      expect(weather.days.first.low, 22);
      expect(weather.days.first.high, 31);
    },
  );

  test('forecast kosong dibedakan dari galat HTTP', () async {
    final empty = OpenMeteo(MockClient((_) async => http.Response('{}', 200)));
    final error = OpenMeteo(MockClient((_) async => http.Response('{}', 503)));
    await expectLater(
      empty.forecast(Place.initial),
      throwsA(isA<NoWeatherData>()),
    );
    await expectLater(
      error.forecast(Place.initial),
      throwsA(isA<WeatherRequestException>()),
    );
  });

  test('kode kondisi asing tidak dianggap cerah', () {
    expect(WeatherCondition.fromCode(999), WeatherCondition.unknown);
    expect(WeatherCondition.fromCode(95), WeatherCondition.thunder);
  });
}

const forecastFixture = {
  'current': {
    'time': '2026-11-26T03:15',
    'temperature_2m': 24.5,
    'is_day': 0,
    'relative_humidity_2m': 90,
    'apparent_temperature': 27.8,
    'precipitation': 0.1,
    'wind_speed_10m': 3.2,
    'weather_code': 3,
  },
  'daily': {
    'time': ['2026-11-26', '2026-11-27'],
    'weather_code': [3, 61],
    'temperature_2m_min': [22, 23],
    'temperature_2m_max': [31, 32],
    'precipitation_probability_max': [0, null],
  },
};
