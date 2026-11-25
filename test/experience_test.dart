import 'dart:async';
import 'dart:convert';

// Tetap memakai facade Flutter agar proyek juga bisa dibuka di SDK sebelum 3.47.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:langit_kota/app.dart';
import 'package:langit_kota/data/local_places.dart';
import 'package:langit_kota/data/open_meteo.dart';
import 'package:langit_kota/models/place.dart';
import 'package:langit_kota/viewmodels/search_model.dart';
import 'package:langit_kota/viewmodels/weather_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'open_meteo_test.dart' show forecastFixture;

const bandung = Place(
  id: 1650357,
  name: 'Bandung',
  latitude: -6.91,
  longitude: 107.61,
  region: 'Jawa Barat',
  country: 'Indonesia',
);

Future<LocalPlaces> store() async =>
    LocalPlaces(await SharedPreferences.getInstance());
http.Response response(Object body) => http.Response(jsonEncode(body), 200);

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'penyimpanan memulihkan favorit, lokasi aktif, dan riwayat tanpa duplikasi',
    () async {
      final local = await store();
      await local.toggleFavorite(bandung);
      await local.select(bandung);
      await local.select(Place.initial);
      await local.select(bandung);
      final restored = await store();
      expect(restored.favorites.map((x) => x.id), [bandung.id]);
      expect(restored.active.id, bandung.id);
      expect(restored.recent.map((x) => x.id), [bandung.id, Place.initial.id]);
      await restored.toggleFavorite(bandung);
      expect((await store()).favorites, isEmpty);
    },
  );

  test('respons cuaca kota lama tidak dapat mengganti kota aktif', () async {
    final slow = Completer<http.Response>();
    final local = await store();
    final api = OpenMeteo(
      MockClient(
        (req) async =>
            req.url.queryParameters['latitude'] == '${bandung.latitude}'
            ? response(forecastFixture)
            : slow.future,
      ),
    );
    final vm = WeatherModel(api, local);
    addTearDown(vm.dispose);
    final first = vm.refresh();
    await vm.choose(bandung);
    slow.complete(http.Response('{}', 503));
    await first;
    expect(vm.place.name, 'Bandung');
    expect(vm.weather?.current.temperature, 24.5);
    expect(vm.error, isNull);
  });

  testWidgets('ponsel sempit: buka pencarian, simpan favorit, dan ganti kota', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final local = await store();
    final queries = <String>[];
    final api = OpenMeteo(
      MockClient((req) async {
        final query = req.url.queryParameters['name'];
        if (query == null) return response(forecastFixture);
        queries.add(query);
        return response({
          'results': [bandung.toJson()],
        });
      }),
    );
    await tester.pumpWidget(LangitKota(api: api, local: local));
    await tester.pumpAndSettle();
    expect(find.text('Prakiraan 7 hari'), findsOneWidget);
    await tester.tap(find.byTooltip('Cari kota'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Bandung');
    await tester.pump(const Duration(milliseconds: 410));
    await tester.pumpAndSettle();
    expect(queries, ['Bandung']);
    await tester.tap(find.byTooltip('Simpan Bandung ke favorit'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Bandung').first);
    await tester.pumpAndSettle();
    expect(find.text('Bandung'), findsOneWidget);
    expect(local.isFavorite(bandung), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'kueri usang diabaikan; pencarian kosong dan galat bisa dibedakan',
    (tester) async {
      final slow = Completer<http.Response>();
      final api = OpenMeteo(
        MockClient(
          (req) async => switch (req.url.queryParameters['name']) {
            'Lama' => slow.future,
            'Gangguan' => http.Response('{}', 500),
            _ => response({}),
          },
        ),
      );
      final vm = SearchModel(api);
      addTearDown(vm.dispose);
      vm.changeQuery('Lama');
      await tester.pump(const Duration(milliseconds: 410));
      vm.changeQuery('Baru');
      await tester.pump(const Duration(milliseconds: 410));
      expect(vm.results, isEmpty);
      expect(vm.error, isNull);
      slow.complete(
        response({
          'results': [bandung.toJson()],
        }),
      );
      await tester.pumpAndSettle();
      expect(vm.results, isEmpty);
      vm.changeQuery('Gangguan');
      await tester.pump(const Duration(milliseconds: 410));
      expect(vm.error, isNotNull);
    },
  );
}
