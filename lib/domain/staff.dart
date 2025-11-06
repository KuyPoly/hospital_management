import 'package:uuid/uuid.dart';
import 'overtime.dart';

enum Gender { male, female }
enum Role { doctor, nurse, administrationStaff }

class Staff {
  static final Uuid _uuid = Uuid();

  final String _staffId;
  final String _name;
  final String _email;
  final String _phoneNum;
  final Gender _gender;
  final Role _role;
  final double _baseSalary;
  double _bonusSalary = 0; // mutable, initialized 0
  final int _experienceYear;
  final List<Overtime> _overtimeList = [];
  String? _departmentId;

  Staff({
    String? staffId,
    required String name,
    required String email,
    required String phoneNum,
    required Gender gender,
    required Role role,
    required double baseSalary,
    int experienceYear = 0,
    String? departmentId,
    double? bonusSalary,
  })  : _staffId = staffId ?? _uuid.v4(),
        _name = name,
        _email = email,
        _phoneNum = phoneNum,
        _gender = gender,
        _role = role,
        _baseSalary = baseSalary,
        _experienceYear = experienceYear {
    if (bonusSalary != null) _bonusSalary = bonusSalary;
  }

  // Getters
  String get staffId => _staffId;
  String get name => _name;
  String get email => _email;
  String get phoneNum => _phoneNum;
  Gender get gender => _gender;
  Role get role => _role;
  double get baseSalary => _baseSalary;
  double get bonusSalary => _bonusSalary;
  int get experienceYear => _experienceYear;
  List<Overtime> get overtimeList => List.unmodifiable(_overtimeList);
  String? get departmentId => _departmentId;
  set departmentId(String? value) => _departmentId = value;

  void addOvertime(Overtime ot) {
    _overtimeList.add(ot);
  }

  void addBonus(double amount) {
    if (amount <= 0) return;
    _bonusSalary += amount;
  }

  /// Total overtime pay (sum of each overtime.calculateOvertimePay())
  double totalOvertimePay() {
    return _overtimeList.fold(0.0, (sum, ot) => sum + ot.calculateOvertimePay());
  }

  double calculateSalary() {
    final overtimePay =
        _overtimeList.fold(0.0, (sum, ot) => sum + ot.calculateOvertimePay());
    final experienceBonus = _experienceYear * 20;
    return _baseSalary + overtimePay + _bonusSalary + experienceBonus;
  }

  // Domain should not print; return info string
  String displayInfo() {
    final roleStr = _role.toString().split('.').last;
    final genderStr = _gender.toString().split('.').last;
    final deptStr = _departmentId ?? 'Unassigned';
    final base = _baseSalary.toStringAsFixed(2);
    final bonus = _bonusSalary.toStringAsFixed(2);
    final otCount = _overtimeList.length;
    final otPay = totalOvertimePay().toStringAsFixed(2);
    final total = calculateSalary().toStringAsFixed(2);

    final sb = StringBuffer();
    sb.writeln('ID        : $_staffId');
    sb.writeln('Name      : $_name');
    sb.writeln('Role      : $roleStr');
    sb.writeln('Email     : $_email');
    sb.writeln('Phone     : $_phoneNum');
    sb.writeln('Gender    : $genderStr');
    sb.writeln('Department: $deptStr');
    sb.writeln('Experience: $_experienceYear year(s)');
    sb.writeln('Base pay  : \$$base');
    sb.writeln('Bonus     : \$$bonus');
    sb.writeln('Overtime  : count=$otCount  total=\$$otPay');
    sb.writeln('Total pay : \$$total');
    return sb.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'staff',
      'staffId': _staffId,
      'name': _name,
      'email': _email,
      'phoneNum': _phoneNum,
      'gender': _gender.toString().split('.').last,
      'role': _role.toString().split('.').last,
      'baseSalary': _baseSalary,
      'bonusSalary': _bonusSalary,
      'experienceYear': _experienceYear,
      'departmentId': _departmentId,
      'overtime': _overtimeList.map((o) => o.toJson()).toList(),
    };
  }

  factory Staff.fromJson(Map<String, dynamic> json) {
    final genderStr = (json['gender'] as String?) ?? 'male';
    final roleStr = (json['role'] as String?) ?? 'administrationStaff';
    final staff = Staff(
      staffId: json['staffId'] as String?,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNum: json['phoneNum'] as String,
      gender: genderStr.toLowerCase() == 'male' ? Gender.male : Gender.female,
      role: roleStr.toLowerCase() == 'doctor'
          ? Role.doctor
          : roleStr.toLowerCase() == 'nurse'
              ? Role.nurse
              : Role.administrationStaff,
      baseSalary: (json['baseSalary'] as num).toDouble(),
      experienceYear: (json['experienceYear'] as num?)?.toInt() ?? 0,
      departmentId: json['departmentId'] as String?,
      bonusSalary: (json['bonusSalary'] as num?)?.toDouble(),
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