import 'staff.dart';

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
}