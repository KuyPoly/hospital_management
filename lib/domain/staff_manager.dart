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

  // Approve overtime with validation on date and hours, and sensible rate defaults
  void approveOvertime(
    Staff staff,
    {
      required DateTime date,
      required int hours,
      double? rate,
    }
  ) {
    // Basic hours validation
    if (hours <= 0) {
      throw ArgumentError('Overtime hours must be greater than 0');
    }
    if (hours > 16) {
      throw ArgumentError('Overtime hours cannot exceed 16 hours per day');
    }

    // Date validations: not in future, not older than 30 days
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final otDay = DateTime(date.year, date.month, date.day);

    if (otDay.isAfter(today)) {
      throw ArgumentError('Overtime date cannot be in the future');
    }

    final daysDifference = today.difference(otDay).inDays;
    if (daysDifference > 30) {
      throw ArgumentError('Overtime date is older than 30 days');
    }

    // Prevent duplicate overtime entries for the same staff on the same date
    final hasSameDay = staff.overtimeList.any((ot) {
      final d = ot.date;
      return d.year == otDay.year && d.month == otDay.month && d.day == otDay.day;
    });
    if (hasSameDay) {
      throw StateError('Overtime already approved for this date');
    }

    // Determine rate: allow override via parameter; otherwise choose a sensible default
    double resolvedRate;
    if (rate != null && rate > 0) {
      resolvedRate = rate;
    } else {
      // Simple role-based defaults via runtimeType
      final typeName = staff.runtimeType.toString().toLowerCase();
      if (typeName.contains('doctor')) {
        resolvedRate = 15.0;
      } else if (typeName.contains('nurse')) {
        resolvedRate = 10.0;
      } else {
        // admin or others
        resolvedRate = 8.0;
      }
      // Weekend premium +25%
      final isWeekend = otDay.weekday == DateTime.saturday || otDay.weekday == DateTime.sunday;
      if (isWeekend) {
        resolvedRate = resolvedRate * 1.25;
      }
    }

    final overtime = Overtime(
      date: otDay,
      hours: hours,
      rate: resolvedRate,
    );
    staff.addOvertime(overtime);
  }
}