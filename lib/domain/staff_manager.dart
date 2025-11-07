import 'staff.dart';
import 'department.dart';
import 'overtime.dart';
import 'doctor.dart';
import 'nurse.dart';
import 'admin.dart';

class StaffManager {
  final List<Staff> _staffList = [];
  final List<Department> _departmentList = [];

  // read-only views
  List<Staff> get staffList => List.unmodifiable(_staffList);
  List<Department> get departmentList => List.unmodifiable(_departmentList);

  void addStaff(Staff staff) => _staffList.add(staff);
  void removeStaff(Staff staff) => _staffList.remove(staff);
  int getStaffCount() => _staffList.length;

  Staff? findStaffById(String id) {
    for (final s in _staffList) {
      if (s.staffId == id) return s;
    }
    return null;
  }

  // department helpers
  void addDepartment(Department dept) {
    if (!_departmentList.any((d) => d.depId == dept.depId)) {
      _departmentList.add(dept);
    }
  }

  Department? findDepartmentByType(DepartmentType type) {
    for (final d in _departmentList) {
      if (d.type == type) return d;
    }
    return null;
  }

  Department createDepartmentIfMissing(DepartmentType type, {String desc = ''}) {
    final existing = findDepartmentByType(type);
    if (existing != null) return existing;
    final d = Department(type: type, desc: desc);
    addDepartment(d);
    return d;
  }

  /// Replace the department's description (preserves staff assignments).
  /// Throws ArgumentError if department not found.
  void updateDepartmentDescription(String depId, String newDesc) {
    final idx = _departmentList.indexWhere((d) => d.depId == depId);
    if (idx == -1) {
      throw ArgumentError('Department not found: $depId');
    }
    final old = _departmentList[idx];
    final replaced = Department(depId: old.depId, type: old.type, desc: newDesc);
    // preserve staff assignment using public API
    for (final sid in old.staffIds) {
      final s = findStaffById(sid);
      if (s != null) {
        replaced.addStaff(s);
      }
    }
    _departmentList[idx] = replaced;
  }

  /// Remove a department entry and clear departmentId from all associated staff.
  /// Returns true if removed, false if not found.
  bool removeDepartment(String depId) {
    final idx = _departmentList.indexWhere((d) => d.depId == depId);
    if (idx == -1) return false;
    final dept = _departmentList.removeAt(idx);
    for (final sid in dept.staffIds) {
      final s = findStaffById(sid);
      if (s != null && s.departmentId == depId) {
        s.departmentId = null;
      }
    }
    return true;
  }

  // department filters using departmentId and departmentList (no dynamic)
  List<Staff> filterStaffByDepartmentId(String depId) {
    return _staffList.where((s) => s.departmentId == depId).toList();
  }

  List<Staff> filterStaffByDepartmentName(String name) {
    final q = name.toLowerCase();
    final matches = _departmentList.where((d) => d.name.toLowerCase().contains(q));
    if (matches.isEmpty) {
      return [];
    }
    final dept = matches.first;
    return filterStaffByDepartmentId(dept.depId);
  }

  // role-based lookup using Role enum (no dynamic)
  List<Staff> findStaffByRole(Role role) {
    return _staffList.where((s) => s.role == role).toList();
  }

  // doctor -> 8%  nurse -> 5%  administrationStaff -> 5%
  void approveOvertime(Staff staff, {required DateTime date, required int hours, double? rate}) {
    if (hours <= 0) {
      throw ArgumentError('Overtime hours must be > 0');
    }
    if (hours > 16) {
      throw ArgumentError('Overtime hours cannot exceed 16');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final otDay = DateTime(date.year, date.month, date.day);

    if (otDay.isAfter(today)) {
      throw ArgumentError('Overtime date cannot be in future');
    }

    final daysDifference = today.difference(otDay).inDays;
    if (daysDifference > 30) {
      throw ArgumentError('Overtime date older than 30 days');
    }

    final hasSameDay = staff.overtimeList.any((ot) {
      final d = ot.date;
      return d.year == otDay.year && d.month == otDay.month && d.day == otDay.day;
    });
    if (hasSameDay) {
      throw StateError('Overtime already approved for this date');
    }

    double resolvedRate;
    if (rate != null && rate > 0) {
      resolvedRate = rate;
    } else {
      // compute default as percentage of baseSalary
      final pct = staff.role == Role.doctor
          ? 0.08
          : staff.role == Role.nurse
              ? 0.05
              : 0.05;
      resolvedRate = staff.baseSalary * pct;
    }

    final overtime = Overtime(date: otDay, hours: hours, rate: resolvedRate);
    staff.addOvertime(overtime);

    // Domain policy (Option B): treat the approved overtime as a bonus equal to
    // the overtime pay so total salary includes the overtime amount exactly once.
    final overtimePay = overtime.calculateOvertimePay();
    staff.addBonus(overtimePay);
  }
}
