import 'staff.dart';
import 'overtime.dart';

class Doctor extends Staff {
  final String _specialization;

  Doctor({
    String? staffId,
    required String name,
    required String email,
    required String phoneNum,
    required Gender gender,
    required double baseSalary,
    required int experienceYear,
    String? departmentId,
    required String specialization,
  })  : _specialization = specialization,
        super(
          staffId: staffId,
          name: name,
          email: email,
          phoneNum: phoneNum,
          gender: gender,
          role: Role.doctor,
          baseSalary: baseSalary,
          experienceYear: experienceYear,
          departmentId: departmentId,
        );

  String get specialization => _specialization;

  @override
  String displayInfo() {
    final base = super.displayInfo();
    final sb = StringBuffer();
    sb.writeln(base.trim());
    sb.writeln('Specialty : $_specialization');
    return sb.toString();
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = 'doctor';
    json['specialization'] = _specialization;
    return json;
  }

  factory Doctor.fromJson(Map<String, dynamic> json) {
    final doctor = Doctor(
      staffId: json['staffId'] as String?,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNum: json['phoneNum'] as String,
      gender:
          (json['gender'] as String).toLowerCase() == 'male' ? Gender.male : Gender.female,
      baseSalary: (json['baseSalary'] as num).toDouble(),
      experienceYear: (json['experienceYear'] as num?)?.toInt() ?? 0,
      departmentId: json['departmentId'] as String?,
      specialization: json['specialization'] as String,
    );
    final otList = (json['overtime'] as List<dynamic>? ?? [])
        .map((e) => Overtime.fromJson(e as Map<String, dynamic>))
        .toList();
    for (final ot in otList) {
      doctor.addOvertime(ot);
    }
    // preserve bonus if present
    final bonus = (json['bonusSalary'] as num?)?.toDouble();
    if (bonus != null && bonus > 0) doctor.addBonus(bonus);
    return doctor;
  }
}