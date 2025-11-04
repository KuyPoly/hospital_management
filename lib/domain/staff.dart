import 'overtime.dart';
enum Gender { male, female }
enum Role { Doctor, Nurse, Administration_staff }

class Staff {
  String staffId;
  int displayId;
  String name;
  String email;
  String phoneNum;
  Gender gender;
  double baseSalary;
  double bonusSalary;
  int experienceYear;
  List<Overtime> overtimeList = [];

  Staff({
    required this.staffId,
    required this.displayId,
    required this.name,
    required this.email,
    required this.phoneNum,
    required this.gender,
    required this.baseSalary,
    required this.bonusSalary,
    required this.experienceYear,
  });

  void addOvertime(Overtime ot) {
    overtimeList.add(ot);
  }

  double calculateSalary() {
    double overtimePay = overtimeList.fold(0, (sum, ot) => sum + ot.calculateOvertimePay());
    double experienceBonus = experienceYear * 20;
    return baseSalary + overtimePay + bonusSalary + experienceBonus;
  }

  void displayInfo() {
    print("ID: $staffId | Name: $name | Salary: ${calculateSalary()}");
  }
}