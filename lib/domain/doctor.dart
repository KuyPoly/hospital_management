import 'staff.dart';

class Doctor extends Staff {
  final String _specialization;

  Doctor({
    super.staffId,
    required super.displayId,
    required super.name,
    required super.email,
    required super.phoneNum,
    required super.gender,
    required super.baseSalary,
    required super.bonusSalary,
    required super.experienceYear,
    required String specialization,
  }) : _specialization = specialization;

  String get specialization => _specialization;
}