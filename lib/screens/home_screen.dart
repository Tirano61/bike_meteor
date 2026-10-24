import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/weather_record.dart';
import '../providers/weather_provider.dart';
import '../widgets/weather_table.dart';
import '../widgets/wind_map_card.dart';

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

  String? _selectedDayKey;
  final Set<int> _selectedHours = <int>{};
  WeatherRecord? _selectedRecord;

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
      final matchesDay =
          _selectedDayKey == null || _selectedDayKey == _dayKey(record.dateTime);
      final matchesHour =
          _selectedHours.isEmpty || _selectedHours.contains(record.dateTime.hour);
      return matchesDay && matchesHour;
    }).toList(growable: false);
  }

  WeatherRecord? _latestRecord(List<WeatherRecord> records) {
    if (records.isEmpty) {
      return null;
    }

    return records.reduce(
      (current, next) =>
          next.dateTime.isAfter(current.dateTime) ? next : current,
    );
  }

  bool _containsRecord(List<WeatherRecord> records, WeatherRecord? selected) {
    if (selected == null) {
      return false;
    }

    return records.any(
      (record) => record.dateTime.isAtSameMomentAs(selected.dateTime),
    );
  }

  void _sanitizeSelections(List<String> dayKeys, List<int> hours) {
    final daySet = dayKeys.toSet();
    final hourSet = hours.toSet();

    if (_selectedDayKey != null && !daySet.contains(_selectedDayKey)) {
      _selectedDayKey = null;
    }
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildBody(context, state),
          ),
        ),
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
    final tableDayKeys = filtered
      .map((record) => _dayKey(record.dateTime))
      .toSet()
      .toList(growable: false)
      ..sort();
    final tableDateTitle = tableDayKeys.isEmpty
      ? 'Sin datos'
      : tableDayKeys.length == 1
      ? _dayLabelFormat.format(_dayFromKey(tableDayKeys.first))
      : 'Varias fechas';
    final hasSelectedInFilter = _containsRecord(filtered, _selectedRecord);
    final activeRecord =
        hasSelectedInFilter ? _selectedRecord : _latestRecord(filtered);

    if (!hasSelectedInFilter && _selectedRecord != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedRecord = null;
          });
        }
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableHeight = (constraints.maxHeight * 0.38).clamp(180.0, 320.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                primary: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Datos cargados: ${state.records.length} registros'),
                    const SizedBox(height: 8),
                    Text('Mostrando: ${filtered.length} registros'),
                    if (activeRecord != null) ...[
                      const SizedBox(height: 12),
                      WindMapCard(record: activeRecord),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: _selectedDayKey,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Fecha',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todas las fechas'),
                        ),
                        ...dayKeys.map((key) {
                          final date = _dayFromKey(key);
                          return DropdownMenuItem<String?>(
                            value: key,
                            child: Text(_dayLabelFormat.format(date)),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDayKey = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ExpansionTile(
                        title: const Text('Horas'),
                        subtitle: Text(
                          _selectedHours.isEmpty
                              ? 'Sin filtro horario'
                              : '${_selectedHours.length} hora(s) seleccionada(s)',
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Perfiles rápidos'),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _hourProfiles.keys.map((profileName) {
                              final profileHours =
                                  _hourProfiles[profileName] ?? const <int>[];
                              final isSelected =
                                  profileHours.isNotEmpty &&
                                  profileHours.every(
                                    (hour) => _selectedHours.contains(hour),
                                  );

                              return FilterChip(
                                label: Text(profileName),
                                selected: isSelected,
                                onSelected: (
                                  _,
                                ) => _applyHourProfile(profileName, hours),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Tabla de horas - $tableDateTitle',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: tableHeight,
              child: WeatherTable(
                records: filtered,
                selectedRecord: activeRecord,
                onRecordSelected: (record) {
                  setState(() {
                    _selectedRecord = record;
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
