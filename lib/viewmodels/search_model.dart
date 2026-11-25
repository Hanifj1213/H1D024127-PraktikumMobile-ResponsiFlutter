import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/open_meteo.dart';
import '../models/place.dart';

class SearchModel extends ChangeNotifier {
  SearchModel(this._api);
  final OpenMeteo _api;
  Timer? _timer;
  int _revision = 0;
  bool _disposed = false;

  String query = '';
  List<Place> results = const [];
  String? error;
  bool loading = false;

  void changeQuery(String value, {bool immediate = false}) {
    _timer?.cancel();
    final revision = ++_revision;
    query = value.trim();
    final target = query;
    results = const [];
    error = null;
    loading = target.length >= 2;
    notifyListeners();
    if (!loading) return;
    if (immediate) {
      unawaited(_search(target, revision));
    } else {
      _timer = Timer(const Duration(milliseconds: 400), () {
        unawaited(_search(target, revision));
      });
    }
  }

  Future<void> _search(String target, int revision) async {
    try {
      final matches = await _api.search(target);
      if (_owns(revision)) results = matches;
    } on WeatherRequestException catch (failure) {
      if (_owns(revision)) error = failure.message;
    } catch (_) {
      if (_owns(revision)) error = 'Pencarian tidak dapat diselesaikan.';
    } finally {
      if (_owns(revision)) {
        loading = false;
        notifyListeners();
      }
    }
  }

  bool _owns(int revision) => !_disposed && revision == _revision;

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
