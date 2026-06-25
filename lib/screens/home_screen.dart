import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/weather_record.dart';
import '../providers/weather_provider.dart';
import '../widgets/weather_table.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const Map<String, List<int>> _hourProfiles = <String, List<int>>{
    'MTB': <int>[16, 17, 18],
    'Mañana': <int>[8, 9, 10],
    'Tarde': <int>[15, 16, 17, 18, 19],
  };

  final Set<String> _selectedDayKeys = <String>{};
  final Set<int> _selectedHours = <int>{};

  static final DateFormat _dayLabelFormat = DateFormat('dd/MM/yyyy');

  String _dayKey(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';
  }

  DateTime _dayFromKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  List<String> _availableDayKeys(List<WeatherRecord> records) {
    final days = records
        .map((r) => _dayKey(r.dateTime))
        .toSet()
        .toList(growable: false)
      ..sort();
    return days;
  }

  List<int> _availableHours(List<WeatherRecord> records) {
    final hours = records.map((r) => r.dateTime.hour).toSet().toList(growable: false)
      ..sort();
    return hours;
  }

  List<WeatherRecord> _filteredRecords(List<WeatherRecord> records) {
    return records.where((record) {
      final matchesDay = _selectedDayKeys.isEmpty ||
          _selectedDayKeys.contains(_dayKey(record.dateTime));
      final matchesHour =
          _selectedHours.isEmpty || _selectedHours.contains(record.dateTime.hour);
      return matchesDay && matchesHour;
    }).toList(growable: false);
  }

  void _sanitizeSelections(List<String> dayKeys, List<int> hours) {
    final daySet = dayKeys.toSet();
    final hourSet = hours.toSet();

    _selectedDayKeys.removeWhere((key) => !daySet.contains(key));
    _selectedHours.removeWhere((hour) => !hourSet.contains(hour));
  }

  void _applyHourProfile(String profileName, List<int> availableHours) {
    final profileHours = _hourProfiles[profileName] ?? const <int>[];
    final availableSet = availableHours.toSet();

    final selected = profileHours
        .where((hour) => availableSet.contains(hour))
        .toSet();

    setState(() {
      _selectedHours
        ..clear()
        ..addAll(selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(weatherProvider);

    if (!state.isLoading && state.error == null && state.records.isNotEmpty) {
      _sanitizeSelections(
        _availableDayKeys(state.records),
        _availableHours(state.records),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bike Meteor'),
        actions: [
          IconButton(
            onPressed: state.isLoading
                ? null
                : () => ref.read(weatherProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WeatherState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Text(
          'Error: ${state.error}',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (state.records.isEmpty) {
      return const Center(child: Text('Sin datos disponibles'));
    }

    final dayKeys = _availableDayKeys(state.records);
    final hours = _availableHours(state.records);
    final filtered = _filteredRecords(state.records);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Datos cargados: ${state.records.length} registros'),
        const SizedBox(height: 8),
        Text('Mostrando: ${filtered.length} registros'),
        const SizedBox(height: 12),
        Text('Días'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: dayKeys.map((key) {
            final date = _dayFromKey(key);
            final isSelected = _selectedDayKeys.contains(key);

            return FilterChip(
              label: Text(_dayLabelFormat.format(date)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDayKeys.add(key);
                  } else {
                    _selectedDayKeys.remove(key);
                  }
                });
              },
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: 16),
        Text('Horas'),
        const SizedBox(height: 8),
        Text('Perfiles rápidos'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _hourProfiles.keys.map((profileName) {
            final profileHours = _hourProfiles[profileName] ?? const <int>[];
            final isSelected =
                profileHours.isNotEmpty &&
                profileHours.every((hour) => _selectedHours.contains(hour));

            return FilterChip(
              label: Text(profileName),
              selected: isSelected,
              onSelected: (_) => _applyHourProfile(profileName, hours),
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: hours.map((hour) {
            final isSelected = _selectedHours.contains(hour);

            return FilterChip(
              label: Text('${hour.toString().padLeft(2, '0')}:00'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedHours.add(hour);
                  } else {
                    _selectedHours.remove(hour);
                  }
                });
              },
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        Expanded(
          child: WeatherTable(records: filtered),
        ),
      ],
    );
  }
}
