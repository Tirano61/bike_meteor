class WeatherRecord {
  WeatherRecord({
    required this.dateTime,
    required this.temperature,
    required this.windSpeed,
    required this.windGust,
    required this.windDirection,
    required this.cardinalDirection,
    required this.weatherCode,
    required this.isDay,
  });

  final DateTime dateTime;
  final double temperature;
  final double windSpeed;
  final double windGust;
  final double windDirection;
  final String cardinalDirection;
  final int weatherCode;
  final bool isDay;

  factory WeatherRecord.fromJson(Map<String, dynamic> json) {
    final direction = _toDouble(json['windDirection']);

    return WeatherRecord(
      dateTime: DateTime.parse(json['dateTime'] as String),
      temperature: _toDouble(json['temperature']),
      windSpeed: _toDouble(json['windSpeed']),
      windGust: _toDouble(json['windGust']),
      windDirection: direction,
      cardinalDirection: json['cardinalDirection'] as String? ??
          WeatherRecord.degreesToCardinal(direction),
      weatherCode: (json['weatherCode'] as num?)?.toInt() ?? 0,
      isDay: json['isDay'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dateTime': dateTime.toIso8601String(),
      'temperature': temperature,
      'windSpeed': windSpeed,
      'windGust': windGust,
      'windDirection': windDirection,
      'cardinalDirection': cardinalDirection,
      'weatherCode': weatherCode,
      'isDay': isDay,
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
