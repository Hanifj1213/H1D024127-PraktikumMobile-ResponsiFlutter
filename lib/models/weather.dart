enum WeatherCondition {
  clear('Cerah'),
  partlyCloudy('Cerah berawan'),
  cloudy('Berawan'),
  fog('Berkabut'),
  drizzle('Gerimis'),
  rain('Hujan'),
  showers('Hujan lokal'),
  freezingRain('Hujan beku'),
  snow('Salju'),
  thunder('Badai petir'),
  unknown('Tidak diketahui');

  const WeatherCondition(this.label);
  final String label;

  static WeatherCondition fromCode(int? code) => switch (code) {
    0 => clear,
    1 || 2 => partlyCloudy,
    3 => cloudy,
    45 || 48 => fog,
    51 || 53 || 55 => drizzle,
    61 || 63 || 65 => rain,
    80 || 81 || 82 => showers,
    56 || 57 || 66 || 67 => freezingRain,
    71 || 73 || 75 || 77 || 85 || 86 => snow,
    95 || 96 || 99 => thunder,
    _ => unknown,
  };
}

class NoWeatherData implements Exception {
  const NoWeatherData();
}

class CurrentWeather {
  const CurrentWeather({
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.apparent,
    required this.precipitation,
    required this.wind,
    required this.condition,
    required this.isDay,
  });

  final DateTime time;
  final double temperature;
  final double? humidity, apparent, precipitation, wind;
  final WeatherCondition condition;
  final bool isDay;

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    final time = DateTime.tryParse(
      json['time'] is String ? json['time'] as String : '',
    );
    final temperature = _number(json['temperature_2m']);
    if (time == null || temperature == null) throw const NoWeatherData();
    return CurrentWeather(
      time: time,
      temperature: temperature,
      humidity: _number(json['relative_humidity_2m']),
      apparent: _number(json['apparent_temperature']),
      precipitation: _number(json['precipitation']),
      wind: _number(json['wind_speed_10m']),
      condition: WeatherCondition.fromCode(
        _number(json['weather_code'])?.toInt(),
      ),
      isDay: json['is_day'] != 0,
    );
  }
}

class DailyWeather {
  const DailyWeather({
    required this.date,
    required this.high,
    required this.low,
    required this.rainChance,
    required this.condition,
  });
  final DateTime date;
  final double? high, low;
  final int? rainChance;
  final WeatherCondition condition;

  factory DailyWeather.at(Map<String, dynamic> json, int index, DateTime date) {
    double? value(String key) {
      final values = json[key];
      return values is List && index < values.length
          ? _number(values[index])
          : null;
    }

    return DailyWeather(
      date: date,
      high: value('temperature_2m_max'),
      low: value('temperature_2m_min'),
      rainChance: value('precipitation_probability_max')?.round(),
      condition: WeatherCondition.fromCode(value('weather_code')?.toInt()),
    );
  }
}

class WeatherReport {
  WeatherReport({
    required this.current,
    required List<DailyWeather> days,
    this.timezone,
  }) : days = List.unmodifiable(days);
  final CurrentWeather current;
  final List<DailyWeather> days;
  final String? timezone;

  int? get todayRainChance {
    for (final day in days) {
      if (day.date.year == current.time.year &&
          day.date.month == current.time.month &&
          day.date.day == current.time.day) {
        return day.rainChance;
      }
    }
    return null;
  }

  factory WeatherReport.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    if (current is! Map<String, dynamic>) throw const NoWeatherData();
    final daily = json['daily'];
    final days = <DailyWeather>[];
    if (daily is Map<String, dynamic> && daily['time'] is List) {
      final dates = daily['time'] as List;
      for (var index = 0; index < dates.length; index++) {
        final raw = dates[index];
        final date = raw is String ? DateTime.tryParse(raw) : null;
        if (date != null) days.add(DailyWeather.at(daily, index, date));
      }
    }
    return WeatherReport(
      current: CurrentWeather.fromJson(current),
      days: days,
      timezone: json['timezone'] as String?,
    );
  }
}

double? _number(Object? value) =>
    value is num && value.isFinite ? value.toDouble() : null;
