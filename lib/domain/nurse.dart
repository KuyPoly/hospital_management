import 'staff.dart';
import 'overtime.dart';

enum Shift { morning, afternoon, night }

extension ShiftX on Shift {
  String get displayName {
    switch (this) {
      case Shift.morning:
        return 'Morning';
      case Shift.afternoon:
        return 'Afternoon';
      case Shift.night:
        return 'Night';
    }
  }

  String get value => toString().split('.').last;
}

class Nurse extends Staff {
  final Shift _shift;

  Nurse({
    String? staffId,
    required String name,
    required String email,
    required String phoneNum,
    required Gender gender,
    required double baseSalary,
    required int experienceYear,
    String? departmentId,
    required Shift shift,
  })  : _shift = shift,
        super(
          staffId: staffId,
          name: name,
          email: email,
          phoneNum: phoneNum,
          gender: gender,
          role: Role.nurse,
          baseSalary: baseSalary,
          experienceYear: experienceYear,
          departmentId: departmentId,
        );

  Shift get shift => _shift;

  @override
  String displayInfo() {
    final base = super.displayInfo();
    final sb = StringBuffer();
    sb.writeln(base.trim());
    sb.writeln('Shift     : ${_shift.displayName}');
    return sb.toString();
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = 'nurse';
    json['shift'] = _shift.value;
    return json;
  }

  factory Nurse.fromJson(Map<String, dynamic> json) {
    final shiftStr = (json['shift'] as String?) ?? Shift.morning.value;
    final shift = Shift.values.firstWhere((s) => s.value == shiftStr, orElse: () => Shift.morning);
    final nurse = Nurse(
      staffId: json['staffId'] as String?,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNum: json['phoneNum'] as String,
      gender:
          (json['gender'] as String).toLowerCase() == 'male' ? Gender.male : Gender.female,
      baseSalary: (json['baseSalary'] as num).toDouble(),
      experienceYear: (json['experienceYear'] as num?)?.toInt() ?? 0,
      departmentId: json['departmentId'] as String?,
      shift: shift,
    );
    final otList = (json['overtime'] as List<dynamic>? ?? [])
        .map((e) => Overtime.fromJson(e as Map<String, dynamic>))
        .toList();
    for (final ot in otList) {
      nurse.addOvertime(ot);
    }
    final bonus = (json['bonusSalary'] as num?)?.toDouble();
    if (bonus != null && bonus > 0) nurse.addBonus(bonus);
    return nurse;
  }
}
