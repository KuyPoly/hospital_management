import 'staff.dart';

class Department {
  String depId;
  String name;
  String desc;
  List<Staff> staffList = [];

  Department({
    required this.depId,
    required this.name,
    required this.desc,
  });

  void assignDepartment(Staff staff, Department dept) {
    dept.staffList.add(staff);
    print("${staff.name} has been assigned to ${dept.name}");
  }
}