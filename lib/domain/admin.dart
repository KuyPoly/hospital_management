import 'staff.dart';
import 'overtime.dart';

enum Position { accountant, receptionist }

class Admin extends Staff {
  final Position _position;

  Admin({
    super.staffId,
    required super.displayId,
    required super.name,
    required super.email,
    required super.phoneNum,
    required super.gender,
    required super.baseSalary,
    required super.bonusSalary,
    required super.experienceYear,
    required Position position,
  }) : _position = position;

  Position get position => _position;

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['position'] = _position.toString().split('.').last;
    return json;
  }

  factory Admin.fromJson(Map<String, dynamic> json) {
    final positionStr = json['position'] as String;
    final position = positionStr.toLowerCase() == 'accountant' 
        ? Position.accountant 
        : Position.receptionist;
    
    final admin = Admin(
      staffId: json['staffId'] as String?,
      displayId: json['displayId'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNum: json['phoneNum'] as String,
      gender: (json['gender'] as String).toLowerCase() == 'male' ? Gender.male : Gender.female,
      baseSalary: (json['baseSalary'] as num).toDouble(),
      bonusSalary: (json['bonusSalary'] as num).toDouble(),
      experienceYear: json['experienceYear'] as int,
      position: position,
    );
    final otList = (json['overtime'] as List<dynamic>? ?? [])
        .map((e) => Overtime.fromJson(e as Map<String, dynamic>))
        .toList();
    for (final ot in otList) {
      admin.addOvertime(ot);
    }
    return admin;
  }
}