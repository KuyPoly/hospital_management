import 'staff.dart';
import 'overtime.dart';

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

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['shift'] = _shift;
    return json;
  }

  factory Nurse.fromJson(Map<String, dynamic> json) {
    final nurse = Nurse(
      staffId: json['staffId'] as String?,
      displayId: json['displayId'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNum: json['phoneNum'] as String,
      gender: (json['gender'] as String).toLowerCase() == 'male' ? Gender.male : Gender.female,
      baseSalary: (json['baseSalary'] as num).toDouble(),
      bonusSalary: (json['bonusSalary'] as num).toDouble(),
      experienceYear: json['experienceYear'] as int,
      shift: json['shift'] as String,
    );
    final otList = (json['overtime'] as List<dynamic>? ?? [])
        .map((e) => Overtime.fromJson(e as Map<String, dynamic>))
        .toList();
    for (final ot in otList) {
      nurse.addOvertime(ot);
    }
    return nurse;
  }
}