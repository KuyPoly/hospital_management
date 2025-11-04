import 'staff.dart';
import 'overtime.dart';

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

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['specialization'] = _specialization;
    return json;
  }

  factory Doctor.fromJson(Map<String, dynamic> json) {
    final doctor = Doctor(
      staffId: json['staffId'] as String?,
      displayId: json['displayId'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNum: json['phoneNum'] as String,
      gender: (json['gender'] as String).toLowerCase() == 'male' ? Gender.male : Gender.female,
      baseSalary: (json['baseSalary'] as num).toDouble(),
      bonusSalary: (json['bonusSalary'] as num).toDouble(),
      experienceYear: json['experienceYear'] as int,
      specialization: json['specialization'] as String,
    );
    final otList = (json['overtime'] as List<dynamic>? ?? [])
        .map((e) => Overtime.fromJson(e as Map<String, dynamic>))
        .toList();
    for (final ot in otList) {
      doctor.addOvertime(ot);
    }
    return doctor;
  }
}