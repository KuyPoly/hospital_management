import 'staff.dart';

class Nurse extends Staff {
  final String _shift;

  Nurse({
    super.staffId,
    required super.displayId,
    required super.name,
    required super.email,
    required super.phoneNum,
    required super.gender,
    required super.baseSalary,
    required super.bonusSalary,
    required super.experienceYear,
    required String shift,
  }) : _shift = shift;

  String get shift => _shift;
}