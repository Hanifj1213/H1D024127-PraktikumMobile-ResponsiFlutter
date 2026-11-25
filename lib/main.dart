// Tetap memakai facade Flutter agar proyek juga bisa dibuka di SDK sebelum 3.47.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/local_places.dart';
import 'data/open_meteo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  final local = LocalPlaces(await SharedPreferences.getInstance());
  runApp(LangitKota(api: OpenMeteo(http.Client()), local: local));
}
