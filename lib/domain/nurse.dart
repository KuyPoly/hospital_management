import 'staff.dart';

class Nurse extends Staff {
  String shift;

  Nurse({
    required super.staffId,
    required super.displayId,
    required super.name,
    required super.email,
    required super.phoneNum,
    required super.gender,
    required super.baseSalary,
    required super.bonusSalary,
    required super.experienceYear,
    required this.shift,
  });
}