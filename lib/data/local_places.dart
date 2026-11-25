import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/place.dart';

class LocalPlaces extends ChangeNotifier {
  LocalPlaces(this._preferences) {
    final raw = _preferences.get(_key);
    if (raw is! String) return;
    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) return;
      _favorites = _readList(data['favorites']);
      _recent = _readList(data['recent']);
      _active = _readPlace(data['active']) ?? Place.initial;
    } on FormatException {
      // Preferensi rusak atau versi lama tidak mencegah aplikasi dibuka.
    }
  }

  static const _key = 'langit_kota.locations.v1';
  final SharedPreferences _preferences;
  Place _active = Place.initial;
  List<Place> _recent = [];
  List<Place> _favorites = [];
  Future<void> _pending = Future.value();

  Place get active => _active;
  List<Place> get favorites => List.unmodifiable(_favorites);
  List<Place> get recent => List.unmodifiable(_recent);
  bool isFavorite(Place place) => _favorites.any((p) => p.id == place.id);

  Future<void> toggleFavorite(Place place) => _update(() {
    if (isFavorite(place)) {
      _favorites = _favorites.where((p) => p.id != place.id).toList();
    } else {
      _favorites = [place, ..._favorites];
    }
  });

  Future<void> select(Place place) => _update(() {
    _active = place;
    _recent = [
      place,
      ..._recent.where((p) => p.id != place.id),
    ].take(8).toList();
  });

  // Antrean mencegah penulisan lama menimpa perubahan yang lebih baru.
  Future<void> _update(VoidCallback change) {
    final operation = _pending.then((_) async {
      final active = _active;
      final favorites = _favorites;
      final recent = _recent;
      change();
      try {
        final ok = await _preferences.setString(
          _key,
          jsonEncode({
            'active': _active.toJson(),
            'favorites': _favorites.map((p) => p.toJson()).toList(),
            'recent': _recent.map((p) => p.toJson()).toList(),
          }),
        );
        if (!ok) throw StateError('Penyimpanan lokal gagal.');
      } catch (_) {
        _active = active;
        _favorites = favorites;
        _recent = recent;
        rethrow;
      }
      notifyListeners();
    });
    _pending = operation.catchError((Object _) {});
    return operation;
  }

  static Place? _readPlace(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    try {
      return Place.fromJson(data);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  static List<Place> _readList(Object? data) =>
      data is List ? data.map(_readPlace).whereType<Place>().toList() : [];
}
