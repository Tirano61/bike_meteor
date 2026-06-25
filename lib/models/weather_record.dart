class WeatherRecord {
  WeatherRecord({
    required this.dateTime,
    required this.temperature,
    required this.windSpeed,
    required this.windDirection,
    required this.cardinalDirection,
  });

  final DateTime dateTime;
  final double temperature;
  final double windSpeed;
  final double windDirection;
  final String cardinalDirection;

  factory WeatherRecord.fromJson(Map<String, dynamic> json) {
    final direction = _toDouble(json['windDirection']);

    return WeatherRecord(
      dateTime: DateTime.parse(json['dateTime'] as String),
      temperature: _toDouble(json['temperature']),
      windSpeed: _toDouble(json['windSpeed']),
      windDirection: direction,
      cardinalDirection: json['cardinalDirection'] as String? ??
          WeatherRecord.degreesToCardinal(direction),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dateTime': dateTime.toIso8601String(),
      'temperature': temperature,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'cardinalDirection': cardinalDirection,
    };
  }

  static String degreesToCardinal(double degrees) {
    final normalized = ((degrees % 360) + 360) % 360;

    if (normalized >= 337.5 || normalized < 22.5) return 'N';
    if (normalized < 67.5) return 'NE';
    if (normalized < 112.5) return 'E';
    if (normalized < 157.5) return 'SE';
    if (normalized < 202.5) return 'S';
    if (normalized < 247.5) return 'SO';
    if (normalized < 292.5) return 'O';
    return 'NO';
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.parse(value);
    }

    throw FormatException('Cannot parse "$value" to double.');
  }
}
