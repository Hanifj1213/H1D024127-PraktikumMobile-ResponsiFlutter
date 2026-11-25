// Tetap memakai facade Flutter agar proyek juga bisa dibuka di SDK sebelum 3.47.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/local_places.dart';
import '../data/open_meteo.dart';
import '../models/place.dart';
import '../models/weather.dart';
import '../viewmodels/weather_model.dart';
import 'search_screen.dart';
import 'style.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({
    super.key,
    required this.model,
    required this.api,
    required this.local,
  });
  final WeatherModel model;
  final OpenMeteo api;
  final LocalPlaces local;

  Future<void> _openSearch(BuildContext context) async {
    final place = await Navigator.of(context).push<Place>(
      MaterialPageRoute(
        builder: (_) => SearchScreen(api: api, local: local),
      ),
    );
    if (context.mounted && place != null) await model.choose(place);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final place = model.place;
      final report = model.weather;
      return Scaffold(
        appBar: BrandBar(
          actions: [
            IconButton(
              tooltip: 'Perbarui cuaca',
              onPressed: model.loading ? null : model.refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton.filled(
              tooltip: 'Cari kota',
              onPressed: () => _openSearch(context),
              icon: const Icon(Icons.search_rounded),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: model.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Overline('01 / PANTAU CUACA'),
                        const SizedBox(height: 7),
                        Semantics(
                          header: true,
                          child: Text(
                            place.name,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                        ),
                        if (place.detail.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: muted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  place.detail,
                                  style: const TextStyle(color: muted),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 19),
                        if (model.loading && report != null)
                          const LinearProgressIndicator(),
                        if (model.storageError case final String text) ...[
                          Text(
                            text,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (model.error case final String text) ...[
                          StatusPanel(
                            icon: Icons.cloud_off_rounded,
                            title: 'Cuaca gagal dimuat',
                            message: report == null
                                ? text
                                : '$text Menampilkan data terakhir.',
                            onRetry: model.refresh,
                          ),
                          if (report != null) const SizedBox(height: 12),
                        ],
                        if (report != null)
                          _WeatherDashboard(report: report)
                        else if (model.loading)
                          const StatusPanel(
                            icon: Icons.cloud_outlined,
                            loading: true,
                            title: 'Memuat cuaca',
                            message: 'Mengambil data terbaru dari Open-Meteo.',
                          )
                        else if (model.empty)
                          StatusPanel(
                            icon: Icons.inbox_outlined,
                            title: 'Belum ada data cuaca',
                            message:
                                'Open-Meteo tidak mengirimkan data terkini untuk lokasi ini.',
                            onRetry: model.refresh,
                          ),
                        const SizedBox(height: 20),
                        const Text(
                          'Sumber: Open-Meteo  •  Waktu lokal kota',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _WeatherDashboard extends StatelessWidget {
  const _WeatherDashboard({required this.report});
  final WeatherReport report;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final overview = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WeatherHero(weather: report.current),
          const SizedBox(height: 18),
          const Overline('DETAIL HARI INI'),
          const SizedBox(height: 9),
          _Metrics(report: report),
        ],
      );
      final forecast = _Forecast(report: report);
      if (constraints.maxWidth < 760) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [overview, const SizedBox(height: 21), forecast],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: overview),
          const SizedBox(width: 20),
          Expanded(flex: 4, child: forecast),
        ],
      );
    },
  );
}

class _WeatherHero extends StatelessWidget {
  const _WeatherHero({required this.weather});
  final CurrentWeather weather;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF102D40), Color(0xFF15565D)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: _ContourPainter())),
        Padding(
          padding: const EdgeInsets.fromLTRB(19, 17, 17, 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Overline('CUACA TERKINI', color: Color(0xFFB5ECE6)),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _value(weather.temperature, '°', digits: 0),
                        style: const TextStyle(
                          fontSize: 75,
                          height: 1.02,
                          letterSpacing: -4.6,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ExcludeSemantics(
                    child: Icon(
                      _conditionIcon(weather.condition, weather.isDay),
                      size: 66,
                      color: const Color(0xFFBCEFE7),
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
              ),
              Text(
                weather.condition.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 13),
              const Divider(height: 1, color: Color(0x526BE0D9)),
              const SizedBox(height: 11),
              Text(
                '${DateFormat('EEEE, d MMM', 'id_ID').format(weather.time)}  •  ${DateFormat.Hm().format(weather.time)}',
                style: const TextStyle(
                  color: Color(0xFFD1EFED),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ContourPainter extends CustomPainter {
  const _ContourPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .87, size.height * .45);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 8; i++) {
      paint.color = const Color(0xFFACFFEA).withValues(alpha: .16 - i * .012);
      canvas.drawCircle(center, 44 + i * 15, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ContourPainter oldDelegate) => false;
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.report});
  final WeatherReport report;
  @override
  Widget build(BuildContext context) {
    final now = report.current;
    final cells = [
      (
        Icons.water_drop_outlined,
        'Kelembapan',
        _value(now.humidity, '%', digits: 0),
      ),
      (Icons.air_rounded, 'Angin', _value(now.wind, ' km/j')),
      (
        Icons.umbrella_outlined,
        'Peluang hujan',
        _value(report.todayRainChance, '%', digits: 0),
      ),
      (Icons.thermostat_rounded, 'Terasa seperti', _value(now.apparent, ' °C')),
      (Icons.grain_rounded, 'Curah hujan', _value(now.precipitation, ' mm')),
    ];
    return LayoutBuilder(
      builder: (context, bounds) {
        final count = bounds.maxWidth < 345 ? 2 : 3;
        const gap = 8.0;
        final width = (bounds.maxWidth - (count - 1) * gap) / count;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (icon, label, value) in cells)
              SizedBox(
                width: width,
                child: Panel(
                  padding: const EdgeInsets.fromLTRB(10, 8, 9, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: teal, size: 18),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                      Text(
                        value,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Forecast extends StatelessWidget {
  const _Forecast({required this.report});
  final WeatherReport report;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Overline('TREN HARIAN'),
      const SizedBox(height: 4),
      Semantics(
        header: true,
        child: Text(
          'Prakiraan 7 hari',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Kemungkinan hujan dan rentang suhu.',
        style: TextStyle(color: muted, fontSize: 13),
      ),
      const SizedBox(height: 10),
      if (report.days.isEmpty)
        const StatusPanel(
          icon: Icons.calendar_today_outlined,
          title: 'Prakiraan belum tersedia',
          message: 'Data harian tidak disertakan dalam respons.',
        )
      else
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: Column(
            children: [
              for (final (i, day) in report.days.indexed) ...[
                if (i != 0) const Divider(height: 1, color: line),
                _ForecastRow(
                  day: day,
                  today: DateUtils.isSameDay(day.date, report.current.time),
                ),
              ],
            ],
          ),
        ),
    ],
  );
}

class _ForecastRow extends StatelessWidget {
  const _ForecastRow({required this.day, required this.today});
  final DailyWeather day;
  final bool today;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                today
                    ? 'Hari ini'
                    : DateFormat('EEEE', 'id_ID').format(day.date),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                DateFormat('d MMM', 'id_ID').format(day.date),
                style: const TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ),
        Tooltip(
          message: day.condition.label,
          child: Icon(
            _conditionIcon(day.condition, true),
            size: 20,
            color: teal,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            _value(day.rainChance, '%', digits: 0),
            textAlign: TextAlign.center,
            semanticsLabel:
                'Peluang hujan ${_value(day.rainChance, '%', digits: 0)}',
            style: const TextStyle(color: teal, fontSize: 12),
          ),
        ),
        Flexible(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: _value(day.low, '°', digits: 0),
                    style: const TextStyle(color: muted),
                  ),
                  const TextSpan(text: ' / '),
                  TextSpan(
                    text: _value(day.high, '°', digits: 0),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13),
              semanticsLabel:
                  'Minimum ${_value(day.low, '°', digits: 0)}, maksimum ${_value(day.high, '°', digits: 0)}',
            ),
          ),
        ),
      ],
    ),
  );
}

String _value(num? value, String unit, {int digits = 1}) => value == null
    ? '—'
    : '${value.toStringAsFixed(digits).replaceAll('.', ',')}$unit';

IconData _conditionIcon(WeatherCondition condition, bool day) =>
    switch (condition) {
      WeatherCondition.clear =>
        day ? Icons.wb_sunny_rounded : Icons.nightlight_round,
      WeatherCondition.partlyCloudy =>
        day ? Icons.wb_cloudy_outlined : Icons.nights_stay_outlined,
      WeatherCondition.cloudy => Icons.cloud_rounded,
      WeatherCondition.fog => Icons.foggy,
      WeatherCondition.drizzle ||
      WeatherCondition.rain ||
      WeatherCondition.showers ||
      WeatherCondition.freezingRain => Icons.water_drop_rounded,
      WeatherCondition.snow => Icons.ac_unit_rounded,
      WeatherCondition.thunder => Icons.thunderstorm_rounded,
      WeatherCondition.unknown => Icons.help_outline_rounded,
    };
