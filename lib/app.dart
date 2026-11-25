// Tetap memakai facade Flutter agar proyek juga bisa dibuka di SDK sebelum 3.47.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import 'data/local_places.dart';
import 'data/open_meteo.dart';
import 'viewmodels/weather_model.dart';
import 'views/weather_screen.dart';
import 'views/style.dart';

class LangitKota extends StatefulWidget {
  const LangitKota({super.key, required this.api, required this.local});
  final OpenMeteo api;
  final LocalPlaces local;

  @override
  State<LangitKota> createState() => _LangitKotaState();
}

class _LangitKotaState extends State<LangitKota> {
  late final WeatherModel model;

  @override
  void initState() {
    super.initState();
    model = WeatherModel(widget.api, widget.local)..refresh();
  }

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'LangitKota',
    debugShowCheckedModeBanner: false,
    theme: langitTheme(),
    home: WeatherScreen(model: model, api: widget.api, local: widget.local),
  );
}
