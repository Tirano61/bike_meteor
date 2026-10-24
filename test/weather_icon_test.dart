import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:Biker/widgets/weather_icon.dart';

void main() {
  group('WeatherCondition.fromCode', () {
    test('despejado de día muestra sol', () {
      final c = WeatherCondition.fromCode(0, isDay: true);
      expect(c.icon, Icons.wb_sunny);
      expect(c.description, 'Despejado');
    });

    test('despejado de noche muestra luna', () {
      final c = WeatherCondition.fromCode(0, isDay: false);
      expect(c.icon, Icons.nightlight_round);
    });

    test('parcialmente nublado distingue día y noche', () {
      expect(
        WeatherCondition.fromCode(2, isDay: true).icon,
        Icons.filter_drama,
      );
      expect(
        WeatherCondition.fromCode(2, isDay: false).icon,
        Icons.nights_stay,
      );
    });

    test('nublado', () {
      expect(WeatherCondition.fromCode(3, isDay: true).icon, Icons.cloud);
    });

    test('lluvia', () {
      final c = WeatherCondition.fromCode(61, isDay: true);
      expect(c.icon, Icons.water_drop);
      expect(c.description, 'Lluvia');
    });

    test('tormenta', () {
      expect(
        WeatherCondition.fromCode(95, isDay: false).icon,
        Icons.thunderstorm,
      );
    });

    test('código desconocido', () {
      final c = WeatherCondition.fromCode(42, isDay: true);
      expect(c.icon, Icons.help_outline);
      expect(c.description, 'Desconocido');
    });
  });
}
