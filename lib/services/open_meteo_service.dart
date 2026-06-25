import 'package:dio/dio.dart';

class OpenMeteoService {
  OpenMeteoService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const String _endpoint = 'https://api.open-meteo.com/v1/forecast';

  Future<Map<String, dynamic>> fetchForecast() async {
    final response = await _dio.get<Map<String, dynamic>>(
      _endpoint,
      queryParameters: <String, dynamic>{
        'latitude': -33.7456,
        'longitude': -61.9688,
        'hourly': 'temperature_2m,wind_speed_10m,wind_direction_10m',
        'forecast_days': 10,
        'timezone': 'America/Argentina/Cordoba',
      },
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Open-Meteo response is empty');
    }

    return data;
  }
}
