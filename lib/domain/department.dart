import 'package:uuid/uuid.dart';
import 'staff.dart';

class Department {
  static final Uuid _uuid = Uuid();

  final String _depId;
  final String _name;
  final String _desc;
  final List<Staff> _staffList = [];

  Department({
    String? depId,
    required String name,
    required String desc,
  })  : _depId = depId ?? _uuid.v4(),
        _name = name,
        _desc = desc;

  String get depId => _depId;
  String get name => _name;
  String get desc => _desc;
  List<Staff> get staffList => List.unmodifiable(_staffList);

  // Adds staff to the given department
  void assignDepartment(Staff staff, Department dept) {
    dept._staffList.add(staff);
  }
}