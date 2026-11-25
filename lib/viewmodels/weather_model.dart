import 'package:flutter/foundation.dart';

import '../data/local_places.dart';
import '../data/open_meteo.dart';
import '../models/place.dart';
import '../models/weather.dart';

class WeatherModel extends ChangeNotifier {
  WeatherModel(this._api, this._local) : place = _local.active;
  final OpenMeteo _api;
  final LocalPlaces _local;
  var _request = 0;
  var _disposed = false;

  Place place;
  WeatherReport? weather;
  String? error;
  String? storageError;
  bool loading = false;
  bool empty = false;

  Future<void> choose(Place next) async {
    if (_disposed) return;
    if (next.id != place.id) weather = null;
    place = next;
    storageError = null;
    final request = refresh();
    try {
      await _local.select(next);
    } catch (_) {
      if (!_disposed && place.id == next.id) {
        storageError = 'Pilihan kota belum tersimpan di perangkat.';
        notifyListeners();
      }
    }
    await request;
  }

  Future<void> refresh() async {
    if (_disposed) return;
    final id = ++_request;
    final target = place;
    loading = true;
    error = null;
    empty = false;
    notifyListeners();
    try {
      final report = await _api.forecast(target);
      if (_owns(id)) weather = report;
    } on NoWeatherData {
      if (_owns(id)) {
        weather = null;
        empty = true;
      }
    } on WeatherRequestException catch (failure) {
      if (_owns(id)) error = failure.message;
    } catch (_) {
      if (_owns(id)) error = 'Data cuaca tidak dapat ditampilkan.';
    } finally {
      if (_owns(id)) {
        loading = false;
        notifyListeners();
      }
    }
  }

  bool _owns(int id) => !_disposed && id == _request;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
