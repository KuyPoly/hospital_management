import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../domain/department.dart';

class DepartmentRepository {
  final String filePath;

  DepartmentRepository({String? path})
      : filePath = path ?? p.join('lib', 'data', 'departments.json');

  Future<List<Department>> loadAll() async {
    final file = File(filePath);
    if (!await file.exists()) return <Department>[];
    final text = await file.readAsString();
    if (text.trim().isEmpty) return <Department>[];
    final data = json.decode(text) as List<dynamic>;
    final List<Department> out = [];
    for (final item in data) {
      try {
        out.add(Department.fromJson(item as Map<String, dynamic>));
      } catch (e) {
        stderr.writeln('Failed to parse department entry: $e');
      }
    }
    return out;
  }

  Future<void> saveAll(List<Department> list) async {
    final file = File(filePath);
    final arr = list.map((d) => d.toJson()).toList();
    await file.create(recursive: true);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(arr));
  }
}