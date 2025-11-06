import 'staff.dart';
import 'overtime.dart';

enum Position { accountant, receptionist }

class Admin extends Staff {
  final Position _position;

  Admin({
    String? staffId,
    required String name,
    required String email,
    required String phoneNum,
    required Gender gender,
    required double baseSalary,
    required int experienceYear,
    String? departmentId,
    required Position position,
  })  : _position = position,
        super(
          staffId: staffId,
          name: name,
          email: email,
          phoneNum: phoneNum,
          gender: gender,
          role: Role.administrationStaff,
          baseSalary: baseSalary,
          experienceYear: experienceYear,
          departmentId: departmentId,
        );

  Position get position => _position;

  @override
  String displayInfo() {
    final base = super.displayInfo();
    final sb = StringBuffer();
    sb.writeln(base.trim());
    sb.writeln('Position  : ${_position.toString().split(".").last}');
    return sb.toString();
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['type'] = 'admin';
    json['position'] = _position.toString().split('.').last;
    return json;
  }

  factory Admin.fromJson(Map<String, dynamic> json) {
    final positionStr = json['position'] as String? ?? 'receptionist';
    final position = positionStr.toLowerCase() == 'accountant'
        ? Position.accountant
        : Position.receptionist;

    final admin = Admin(
      staffId: json['staffId'] as String?,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNum: json['phoneNum'] as String,
      gender:
          (json['gender'] as String).toLowerCase() == 'male' ? Gender.male : Gender.female,
      baseSalary: (json['baseSalary'] as num).toDouble(),
      experienceYear: (json['experienceYear'] as num?)?.toInt() ?? 0,
      departmentId: json['departmentId'] as String?,
      position: position,
    );
    final otList = (json['overtime'] as List<dynamic>? ?? [])
        .map((e) => Overtime.fromJson(e as Map<String, dynamic>))
        .toList();
    for (final ot in otList) {
      admin.addOvertime(ot);
    }
    final bonus = (json['bonusSalary'] as num?)?.toDouble();
    if (bonus != null && bonus > 0) admin.addBonus(bonus);
    return admin;
  }
}