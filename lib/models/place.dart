class Place {
  const Place({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.region,
    this.country,
  });

  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String? region;
  final String? country;

  // Lokasi awal saja. Suhu dan kondisi tidak pernah ditanam di aplikasi.
  static const initial = Place(
    id: 1630328,
    name: 'Purwokerto',
    latitude: -7.42139,
    longitude: 109.23444,
    region: 'Jawa Tengah',
    country: 'Indonesia',
  );

  String get detail => [region, country]
      .whereType<String>()
      .where((s) => s.isNotEmpty && s.toLowerCase() != name.toLowerCase())
      .toSet()
      .join(', ');

  factory Place.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final lat = json['latitude'];
    final lon = json['longitude'];
    if (id is! int ||
        name is! String ||
        name.trim().isEmpty ||
        lat is! num ||
        !lat.isFinite ||
        lat.abs() > 90 ||
        lon is! num ||
        !lon.isFinite ||
        lon.abs() > 180) {
      throw const FormatException('Data lokasi tidak lengkap.');
    }
    return Place(
      id: id,
      name: name,
      latitude: lat.toDouble(),
      longitude: lon.toDouble(),
      region: json['admin1'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'admin1': region,
    'country': country,
  };
}
