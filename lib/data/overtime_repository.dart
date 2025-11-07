import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../domain/overtime.dart';

class OvertimeRepository {
  final String filePath;

  OvertimeRepository({String? path})
      : filePath = path ?? p.join('lib', 'data', 'overtime.json');

  //Load raw overtime entries 
  Future<List<Map<String, dynamic>>> loadAllRaw() async {
    final file = File(filePath);
    if (!await file.exists()) return <Map<String, dynamic>>[];
    final text = await file.readAsString();
    if (text.trim().isEmpty) return <Map<String, dynamic>>[];
    final data = json.decode(text) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  //Save a list of raw overtime maps
  Future<void> saveAllRaw(List<Map<String, dynamic>> raw) async {
    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(raw));
  }

  //convert domain Overtime + staffId into raw map
  static Map<String, dynamic> makeEntry(String staffId, Overtime ot) {
    return {
      'staffId': staffId,
      'date': ot.date.toIso8601String(),
      'hours': ot.hours,
      'rate': ot.rate,
    };
  }

  //build an Overtime from raw map (does not attach to staff)
  static Overtime overtimeFromRaw(Map<String, dynamic> raw) {
    return Overtime(
      date: DateTime.parse(raw['date'] as String),
      hours: (raw['hours'] as num).toInt(),
      rate: (raw['rate'] as num).toDouble(),
    );
  }
}