import 'package:uuid/uuid.dart';
import 'staff.dart';

enum DepartmentType {
  emergencyCare,
  cardiology,
  generalSurgery,
  icu,
}

extension DepartmentTypeX on DepartmentType {
  String get displayName {
    switch (this) {
      case DepartmentType.emergencyCare:
        return 'Emergency Care';
      case DepartmentType.cardiology:
        return 'Cardiology';
      case DepartmentType.generalSurgery:
        return 'General Surgery';
      case DepartmentType.icu:
        return 'Intensive Care Unit (ICU)';
    }
  }

  String get value => toString().split('.').last;
}

class Department {
  static final Uuid _uuid = Uuid();

  final String _depId;
  final DepartmentType _type;
  final String _desc;
  final List<String> _staffIds = [];

  Department({
    String? depId,
    required DepartmentType type,
    required String desc,
  })  : _depId = depId ?? _uuid.v4(),
        _type = type,
        _desc = desc;

  String get depId => _depId;
  DepartmentType get type => _type;
  String get name => _type.displayName;
  String get desc => _desc;
  List<String> get staffIds => List.unmodifiable(_staffIds);

  // Add a staff to this department and set staff.departmentId
  void addStaff(Staff staff) {
    if (!_staffIds.contains(staff.staffId)) {
      _staffIds.add(staff.staffId);
      staff.departmentId = _depId;
    }
  }

  // Optionally remove staff
  void removeStaff(Staff staff) {
    if (_staffIds.remove(staff.staffId) && staff.departmentId == _depId) {
      staff.departmentId = null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'depId': _depId,
      'type': _type.value,
      'desc': _desc,
      'staffIds': _staffIds,
    };
  }

  factory Department.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] as String?) ?? DepartmentType.generalSurgery.value;
    final type = DepartmentType.values.firstWhere(
      (t) => t.value == typeStr,
      orElse: () => DepartmentType.generalSurgery,
    );
    final dep = Department(
      depId: json['depId'] as String?,
      type: type,
      desc: (json['desc'] as String?) ?? '',
    );
    final ids = (json['staffIds'] as List<dynamic>?)?.map((e) => e as String).toList();
    if (ids != null) {
      for (final id in ids) {
        if (!dep._staffIds.contains(id)) dep._staffIds.add(id);
      }
    }
    return dep;
  }

  /// Helper: return one department per DepartmentType (useful to seed UI)
  static List<Department> defaultDepartments([String desc = '']) {
    return DepartmentType.values
        .map((t) => Department(type: t, desc: desc))
        .toList();
  }
}