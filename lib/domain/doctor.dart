import 'staff.dart';

class Doctor extends Staff {
  String specialization;

  Doctor({
    required super.staffId,
    required super.displayId,
    required super.name,
    required super.email,
    required super.phoneNum,
    required super.gender,
    required super.baseSalary,
    required super.bonusSalary,
    required super.experienceYear,
    required this.specialization,
  });
}