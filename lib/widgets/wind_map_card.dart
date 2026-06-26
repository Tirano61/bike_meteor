import 'package:flutter/material.dart';

import '../models/weather_record.dart';

class WindMapCard extends StatelessWidget {
  const WindMapCard({super.key, required this.record});

  final WeatherRecord record;

  double get _windToDirection {
    final normalizedFrom = ((record.windDirection % 360) + 360) % 360;
    return (normalizedFrom + 180) % 360;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Text(
              'Venado Tuerto | Viento en superficie',
              style: theme.textTheme.titleMedium,
            ),
          ),
          SizedBox(
            height: 220,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/venado_tuerto_map.png',
                  fit: BoxFit.cover,
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.north, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Text('Norte', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: AnimatedRotation(
                        turns: _windToDirection / 360,
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeInOutCubic,
                        child: const Icon(
                          Icons.navigation,
                          color: Colors.lightBlueAccent,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Text(
              'Viento desde ${record.windDirection.toStringAsFixed(0)}° ${record.cardinalDirection} | ${record.windSpeed.toStringAsFixed(1)} km/h',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
