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
}