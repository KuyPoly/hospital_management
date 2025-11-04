import 'staff.dart';
import 'department.dart';
import 'overtime.dart';

class StaffManager {
  List<Staff> staffList = [];

  void viewStaff() {
    for (var s in staffList) {
      s.displayInfo();
    }
  }

  void addStaff(Staff staff) {
    staffList.add(staff);
    print("${staff.name} added successfully!");
  }

  void removeStaff(Staff staff) {
    staffList.remove(staff);
    print("${staff.name} removed successfully!");
  }

  int getStaffCount() => staffList.length;

  Staff? findStaffById(String id) {
    return staffList.firstWhere((s) => s.staffId == id, orElse: () => null);
  }

  List<Staff> filterStaffByDepartment(String deptName) {
    return staffList.where((s) => s.name.contains(deptName)).toList();
  }

  List<Staff> findStaffByRole(Position pos) {
    return staffList.whereType<Admin>().where((a) => a.position == pos).toList();
  }

  void approveOvertime(Staff staff, int h) {
    var overtime = Overtime(
      overtimeId: "OT-${DateTime.now().millisecondsSinceEpoch}",
      hour: h,
      rate: 5,
      date: DateTime.now(),
    );
    staff.addOvertime(overtime);
    print("Approved $h overtime hours for ${staff.name}");
  }
}