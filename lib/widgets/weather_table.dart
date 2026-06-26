import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weather_record.dart';

class WeatherTable extends StatelessWidget {
  WeatherTable({
    super.key,
    required this.records,
    required this.selectedRecord,
    required this.onRecordSelected,
  });

  final List<WeatherRecord> records;
  final WeatherRecord? selectedRecord;
  final ValueChanged<WeatherRecord> onRecordSelected;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Fecha')),
              DataColumn(label: Text('Hora')),
              DataColumn(label: Text('Temperatura')),
              DataColumn(label: Text('Viento')),
              DataColumn(label: Text('Direccion')),
            ],
            rows: records.map((item) {
              final isSelected =
                  selectedRecord?.dateTime.isAtSameMomentAs(item.dateTime) ?? false;

              return DataRow(
                selected: isSelected,
                onSelectChanged: (_) => onRecordSelected(item),
                cells: [
                  DataCell(Text(_dateFormat.format(item.dateTime))),
                  DataCell(Text(_timeFormat.format(item.dateTime))),
                  DataCell(Text('${item.temperature.toStringAsFixed(1)} C')),
                  DataCell(Text('${item.windSpeed.toStringAsFixed(1)} km/h')),
                  DataCell(
                    Text(
                      '${item.windDirection.toStringAsFixed(0)}° ${item.cardinalDirection}',
                    ),
                  ),
                ],
              );
            }).toList(growable: false),
          ),
        ),
      ),
    );
  }
}
