import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/weather_record.dart';
import '../services/open_meteo_service.dart';

final openMeteoServiceProvider = Provider<OpenMeteoService>((ref) {
  return OpenMeteoService();
});

final weatherProvider =
    StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
      final service = ref.watch(openMeteoServiceProvider);
      return WeatherNotifier(service);
    });

class WeatherState {
  const WeatherState({
    required this.isLoading,
    required this.error,
    required this.records,
  });

  final bool isLoading;
  final String? error;
  final List<WeatherRecord> records;

  factory WeatherState.initial() {
    return const WeatherState(isLoading: false, error: null, records: <WeatherRecord>[]);
  }

  WeatherState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<WeatherRecord>? records,
  }) {
    return WeatherState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      records: records ?? this.records,
    );
  }
}

class WeatherNotifier extends StateNotifier<WeatherState> {
  WeatherNotifier(this._service) : super(WeatherState.initial()) {
    Future<void>.microtask(loadWeather);
  }

  final OpenMeteoService _service;

  Future<void> loadWeather() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final json = await _service.fetchForecast();
      final records = _parseWeatherRecords(json);
      state = state.copyWith(
        isLoading: false,
        records: records,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadWeather();
  }

  List<WeatherRecord> _parseWeatherRecords(Map<String, dynamic> json) {
    final hourly = json['hourly'];
    if (hourly is! Map<String, dynamic>) {
      throw const FormatException('Missing "hourly" object in Open-Meteo response.');
    }

    final times = _toStringList(hourly['time']);
    final temperatures = _toDoubleList(hourly['temperature_2m']);
    final windSpeeds = _toDoubleList(hourly['wind_speed_10m']);
    final windGusts = _toDoubleList(hourly['wind_gusts_10m']);
    final windDirections = _toDoubleList(hourly['wind_direction_10m']);

    final count = [
      times.length,
      temperatures.length,
      windSpeeds.length,
      windGusts.length,
      windDirections.length,
    ].reduce((a, b) => a < b ? a : b);

    final records = <WeatherRecord>[];
    for (var i = 0; i < count; i++) {
      final direction = windDirections[i];
      records.add(
        WeatherRecord(
          dateTime: DateTime.parse(times[i]),
          temperature: temperatures[i],
          windSpeed: windSpeeds[i],
          windGust: windGusts[i],
          windDirection: direction,
          cardinalDirection: WeatherRecord.degreesToCardinal(direction),
        ),
      );
    }

    return records;
  }

  List<String> _toStringList(dynamic source) {
    if (source is! List) {
      throw const FormatException('Expected a list of String values.');
    }

    return source.map((e) => e.toString()).toList(growable: false);
  }

  List<double> _toDoubleList(dynamic source) {
    if (source is! List) {
      throw const FormatException('Expected a list of numeric values.');
    }

    return source.map((e) {
      if (e is num) {
        return e.toDouble();
      }
      return double.parse(e.toString());
    }).toList(growable: false);
  }
}
