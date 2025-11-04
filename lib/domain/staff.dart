import 'package:uuid/uuid.dart';
import 'overtime.dart';
enum Gender { male, female }
enum Role { doctor, nurse, administrationStaff }

class Staff {
  static final Uuid _uuid = Uuid();

  final String _staffId;
  final int _displayId;
  final String _name;
  final String _email;
  final String _phoneNum;
  final Gender _gender;
  final double _baseSalary;
  final double _bonusSalary;
  final int _experienceYear;
  final List<Overtime> _overtimeList = [];

  Staff({
    String? staffId,
    required int displayId,
    required String name,
    required String email,
    required String phoneNum,
    required Gender gender,
    required double baseSalary,
    required double bonusSalary,
    required int experienceYear,
  })  : _staffId = staffId ?? _uuid.v4(),
        _displayId = displayId,
        _name = name,
        _email = email,
        _phoneNum = phoneNum,
        _gender = gender,
        _baseSalary = baseSalary,
        _bonusSalary = bonusSalary,
        _experienceYear = experienceYear;

  // Getters
  String get staffId => _staffId;
  int get displayId => _displayId;
  String get name => _name;
  String get email => _email;
  String get phoneNum => _phoneNum;
  Gender get gender => _gender;
  double get baseSalary => _baseSalary;
  double get bonusSalary => _bonusSalary;
  int get experienceYear => _experienceYear;
  List<Overtime> get overtimeList => List.unmodifiable(_overtimeList);

  void addOvertime(Overtime ot) {
    _overtimeList.add(ot);
  }

  double calculateSalary() {
    double overtimePay = _overtimeList.fold(0.0, (sum, ot) => sum + ot.calculateOvertimePay());
    double experienceBonus = _experienceYear * 20;
    return _baseSalary + overtimePay + _bonusSalary + experienceBonus;
  }

  String displayInfo() {
    return "ID: $_staffId | Name: $_name | Salary: ${calculateSalary()}";
  }

  Map<String, dynamic> toJson() {
    return {
      'type': runtimeType.toString(),
      'staffId': _staffId,
      'displayId': _displayId,
      'name': _name,
      'email': _email,
      'phoneNum': _phoneNum,
      'gender': _gender.toString().split('.').last,
      'baseSalary': _baseSalary,
      'bonusSalary': _bonusSalary,
      'experienceYear': _experienceYear,
      'overtime': _overtimeList.map((ot) => ot.toJson()).toList(),
    };
  }

  factory Staff.fromJson(Map<String, dynamic> json) {
    final staff = Staff(
      staffId: json['staffId'] as String?,
      displayId: json['displayId'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNum: json['phoneNum'] as String,
      gender: (json['gender'] as String).toLowerCase() == 'male' ? Gender.male : Gender.female,
      baseSalary: (json['baseSalary'] as num).toDouble(),
      bonusSalary: (json['bonusSalary'] as num).toDouble(),
      experienceYear: json['experienceYear'] as int,
    );
    final otList = (json['overtime'] as List<dynamic>? ?? [])
        .map((e) => Overtime.fromJson(e as Map<String, dynamic>))
        .toList();
    for (final ot in otList) {
      staff.addOvertime(ot);
    }
    return staff;
  }
}