import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'ui/console.dart';
import 'data/staff_repository.dart';
import 'domain/staff_manager.dart';
import 'data/department_repository.dart';

Future<void> main() async {
  final manager = StaffManager();

  // Use a data path relative to the package root (matches Console default)
  final dataPath = p.join('lib', 'data', 'data.json');
  final repo = StaffRepository();
  final deptRepo = DepartmentRepository();
  final console = Console(manager, repo, deptRepo, dataPath: dataPath);

  try {
    await console.start();
  } catch (e, st) {
    // Top-level error handling for the console app
    stderr.writeln('Fatal error: $e');
    stderr.writeln(st);
  }
}