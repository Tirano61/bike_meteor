import 'package:flutter/material.dart';

import '../models/weather_record.dart';

class WeatherCondition {
  const WeatherCondition({
    required this.icon,
    required this.color,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String description;

  /// Traduce un código WMO de Open-Meteo (`weather_code`) a ícono, color y
  /// descripción. https://open-meteo.com/en/docs#weather_variable_documentation
  static WeatherCondition fromCode(int code, {required bool isDay}) {
    switch (code) {
      case 0:
      case 1:
        return WeatherCondition(
          icon: isDay ? Icons.wb_sunny : Icons.nightlight_round,
          color: isDay ? Colors.amber.shade700 : Colors.indigo.shade300,
          description: code == 0 ? 'Despejado' : 'Mayormente despejado',
        );
      case 2:
        return WeatherCondition(
          icon: isDay ? Icons.filter_drama : Icons.nights_stay,
          color: isDay ? Colors.blueGrey.shade400 : Colors.indigo.shade300,
          description: 'Parcialmente nublado',
        );
      case 3:
        return WeatherCondition(
          icon: Icons.cloud,
          color: Colors.grey.shade600,
          description: 'Nublado',
        );
      case 45:
      case 48:
        return WeatherCondition(
          icon: Icons.foggy,
          color: Colors.grey.shade500,
          description: 'Niebla',
        );
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return WeatherCondition(
          icon: Icons.grain,
          color: Colors.lightBlue.shade400,
          description: 'Llovizna',
        );
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
        return WeatherCondition(
          icon: Icons.water_drop,
          color: Colors.blue.shade600,
          description: 'Lluvia',
        );
      case 80:
      case 81:
      case 82:
        return WeatherCondition(
          icon: Icons.water_drop,
          color: Colors.blue.shade600,
          description: 'Chaparrones',
        );
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return WeatherCondition(
          icon: Icons.ac_unit,
          color: Colors.cyan.shade300,
          description: 'Nieve',
        );
      case 95:
        return WeatherCondition(
          icon: Icons.thunderstorm,
          color: Colors.deepPurple.shade400,
          description: 'Tormenta',
        );
      case 96:
      case 99:
        return WeatherCondition(
          icon: Icons.thunderstorm,
          color: Colors.deepPurple.shade400,
          description: 'Tormenta con granizo',
        );
      default:
        return WeatherCondition(
          icon: Icons.help_outline,
          color: Colors.grey.shade500,
          description: 'Desconocido',
        );
    }
  }
}

class WeatherIcon extends StatelessWidget {
  const WeatherIcon({super.key, required this.record, this.size = 20});

  final WeatherRecord record;
  final double size;

  @override
  Widget build(BuildContext context) {
    final condition = WeatherCondition.fromCode(
      record.weatherCode,
      isDay: record.isDay,
    );

    return Tooltip(
      message: condition.description,
      child: Icon(condition.icon, color: condition.color, size: size),
    );
  }
}
