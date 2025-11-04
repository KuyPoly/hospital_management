import 'staff.dart';
import 'department.dart';
import 'overtime.dart';

class StaffManager {
  final List<Staff> _staffList = [];

  // Public read-only view of staff list
  List<Staff> get staffList => List.unmodifiable(_staffList);

  // Return display strings for UI to use (domain layer does not print)
  List<String> viewStaffInfo() {
    return _staffList.map((s) => s.displayInfo()).toList();
  }

  void addStaff(Staff staff) {
    _staffList.add(staff);
  }

  void removeStaff(Staff staff) {
    _staffList.remove(staff);
  }

  int getStaffCount() => _staffList.length;

  Staff? findStaffById(String id) {
    for (var s in _staffList) {
      if (s.staffId == id) return s;
    }
    return null;
  }

  // Improved department filter: attempts common field names then fallback to name matching
  List<Staff> filterStaffByDepartment(String deptName) {
    final q = deptName.toLowerCase();
    return _staffList.where((s) {
      try {
        final dep = (s as dynamic).department;
        if (dep != null) {
          final depName = (dep.name ?? dep.toString()).toString().toLowerCase();
          if (depName.contains(q)) return true;
        }
      } catch (_) {}
      try {
        final depNameField = (s as dynamic).departmentName;
        if (depNameField != null && depNameField.toString().toLowerCase().contains(q)) return true;
      } catch (_) {}
      return s.name.toLowerCase().contains(q);
    }).toList();
  }

  // Role-based lookup using Role enum; flexible checks for position/role fields or runtimeType
  List<Staff> findStaffByRole(Role role) {
    final q = role.toString().split('.').last.toLowerCase();
    return _staffList.where((s) {
      try {
        final p = (s as dynamic).position;
        if (p == role) return true;
        if (p != null && p.toString().toLowerCase().contains(q)) return true;
      } catch (_) {}
      try {
        final r = (s as dynamic).role;
        if (r != null && r.toString().toLowerCase().contains(q)) return true;
      } catch (_) {}
      final typeName = s.runtimeType.toString().toLowerCase();
      return typeName.contains(q);
    }).toList();
  }

  // Approve overtime without printing (domain should not produce console output)
  void approveOvertime(Staff staff, int hours) {
    final overtime = Overtime(
      overtimeId: "OT-${DateTime.now().millisecondsSinceEpoch}",
      date: DateTime.now(),
      hours: hours,
      rate: 5,
    );
    staff.addOvertime(overtime);
  }
}