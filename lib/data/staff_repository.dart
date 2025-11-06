import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../domain/staff.dart';
import '../domain/doctor.dart';
import '../domain/nurse.dart';
import '../domain/admin.dart';
import '../domain/overtime.dart';

class StaffRepository {
  final String filePath;

  StaffRepository({String? path})
      : filePath = path ?? p.join('lib', 'data', 'staff.json');

  Future<List<Staff>> loadAll() async {
    final file = File(filePath);
    if (!await file.exists()) return <Staff>[];
    final text = await file.readAsString();
    if (text.trim().isEmpty) return <Staff>[];
    final data = json.decode(text) as List<dynamic>;
    final List<Staff> out = [];
    for (final item in data) {
      final map = item as Map<String, dynamic>;
      final type = (map['type'] as String?) ?? 'staff';
      try {
        if (type == 'doctor') {
          out.add(Doctor.fromJson(map));
        } else if (type == 'nurse') {
          out.add(Nurse.fromJson(map));
        } else if (type == 'admin') {
          out.add(Admin.fromJson(map));
        } else {
          // fallback to base Staff if present
          out.add(Staff.fromJson(map));
        }
      } catch (e) {
        stderr.writeln('Failed to parse staff entry: $e');
      }
    }
    return out;
  }

  Future<void> saveAll(List<Staff> staffList) async {
    final file = File(filePath);
    final arr = staffList.map((s) => s.toJson()).toList();
    await file.create(recursive: true);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(arr));
  }
}