import 'dart:core';
import '../domain/staff_manager.dart';
import '../domain/staff.dart';
import '../domain/doctor.dart';
import '../domain/nurse.dart';
import '../domain/admin.dart';
import '../domain/department.dart';
import '../domain/overtime.dart';

class StaffService {
  static final RegExp _emailRe = RegExp(r'^[\w\.\-]+@[A-Za-z0-9\.\-]+\.[A-Za-z]{2,}$');
  static final RegExp _phoneRe = RegExp(r'^0\d{8,9}$');

  // Validate basic fields and build a Staff instance
  static Staff createStaff({
    required String type, // 'doctor' | 'nurse' | 'admin'
    required String name,
    required String email,
    required String phone,
    required String genderStr,
    required double baseSalary,
    required int experienceYear,
    String? specialization,
    String? shiftStr,
    String? positionStr,
    String? departmentId,
  }) {
    if (name.trim().isEmpty) throw ArgumentError('Name cannot be empty');
    if (!_emailRe.hasMatch(email)) throw ArgumentError('Invalid email');
    if (!_phoneRe.hasMatch(phone)) throw ArgumentError('Invalid phone');
    final gender = _parseGender(genderStr);
    if (baseSalary <= 0) throw ArgumentError('Base salary must be > 0');
    if (experienceYear < 0) throw ArgumentError('Experience must be >= 0');

    if (type.toLowerCase() == 'doctor') {
      final spec = (specialization ?? '').trim();
      if (spec.isEmpty) throw ArgumentError('Specialization required for doctor');
      return Doctor(
        name: name,
        email: email,
        phoneNum: phone,
        gender: gender,
        baseSalary: baseSalary,
        experienceYear: experienceYear,
        departmentId: departmentId,
        specialization: spec,
      );
    } else if (type.toLowerCase() == 'nurse') {
      final Shift shift = _parseShift(shiftStr) ??
          (throw ArgumentError('Shift required for nurse'));
      return Nurse(
        name: name,
        email: email,
        phoneNum: phone,
        gender: gender,
        baseSalary: baseSalary,
        experienceYear: experienceYear,
        departmentId: departmentId,
        shift: shift,
      );
    } else {
      final Position pos = _parsePosition(positionStr) ??
          (throw ArgumentError('Position required for admin'));
      return Admin(
        name: name,
        email: email,
        phoneNum: phone,
        gender: gender,
        baseSalary: baseSalary,
        experienceYear: experienceYear,
        departmentId: departmentId,
        position: pos,
      );
    }
  }

  // Update existing staff (returns new instance) - keeps id, overtime, bonus
  static Staff updateStaff(
    Staff old, {
    required String newRole, // 'doctor'|'nurse'|'admin'
    required String name,
    required String email,
    required String phone,
    required String genderStr,
    required double baseSalary,
    required int experienceYear,
    String? specialization,
    String? shiftStr,
    String? positionStr,
    String? departmentId,
  }) {
    // validate basic same as create
    if (name.trim().isEmpty) throw ArgumentError('Name cannot be empty');
    if (!_emailRe.hasMatch(email)) throw ArgumentError('Invalid email');
    if (!_phoneRe.hasMatch(phone)) throw ArgumentError('Invalid phone');
    final gender = _parseGender(genderStr);
    if (baseSalary <= 0) throw ArgumentError('Base salary must be > 0');
    if (experienceYear < 0) throw ArgumentError('Experience must be >= 0');

    Staff newStaff;
    if (newRole == 'doctor') {
      final spec = (specialization ?? '').trim();
      if (spec.isEmpty && (old is! Doctor)) throw ArgumentError('Specialization required for doctor');
      newStaff = Doctor(
        staffId: old.staffId,
        name: name,
        email: email,
        phoneNum: phone,
        gender: gender,
        baseSalary: baseSalary,
        experienceYear: experienceYear,
        departmentId: departmentId,
        specialization: spec.isEmpty && old is Doctor ? old.specialization : spec,
      );
    } else if (newRole == 'nurse') {
      final Shift resolvedShift = _parseShift(shiftStr) ??
          (old is Nurse ? old.shift : (throw ArgumentError('Shift required for nurse')));
      newStaff = Nurse(
        staffId: old.staffId,
        name: name,
        email: email,
        phoneNum: phone,
        gender: gender,
        baseSalary: baseSalary,
        experienceYear: experienceYear,
        departmentId: departmentId,
        shift: resolvedShift,
      );
    } else {
      final Position resolvedPos = _parsePosition(positionStr) ??
          (old is Admin ? old.position : (throw ArgumentError('Position required for admin')));
      newStaff = Admin(
        staffId: old.staffId,
        name: name,
        email: email,
        phoneNum: phone,
        gender: gender,
        baseSalary: baseSalary,
        experienceYear: experienceYear,
        departmentId: departmentId,
        position: resolvedPos,
      );
    }

    // copy overtime and bonus
    for (final ot in old.overtimeList) {
      newStaff.addOvertime(ot);
    }
    if (old.bonusSalary > 0) newStaff.addBonus(old.bonusSalary);
    return newStaff;
  }

  // Approve overtime using string input for date and optional rate string
  static void approveOvertimeFromInput(StaffManager manager, Staff staff,
      {required String dateStr, required int hours, String? rateStr}) {
    final date = _parseDate(dateStr);
    if (hours <= 0 || hours > 16) throw ArgumentError('Hours must be 1..16');

    double? rate;
    if (rateStr != null && rateStr.trim().isNotEmpty) {
      final parsed = double.tryParse(rateStr);
      if (parsed == null || parsed <= 0) throw ArgumentError('Invalid rate');
      rate = parsed;
    }

    // delegate to manager (which contains domain checks like duplicate date, range)
    manager.approveOvertime(staff, date: date, hours: hours, rate: rate);
  }

  // Helper utilities
  static Gender _parseGender(String s) {
    final v = s.trim().toLowerCase();
    if (v == 'male' || v == 'm') return Gender.male;
    if (v == 'female' || v == 'f') return Gender.female;
    throw ArgumentError('Invalid gender');
  }

  static Shift? _parseShift(String? s) {
    if (s == null) return null;
    final v = s.trim().toLowerCase();
    if (v == '1' || v == 'morning' || v == 'm') return Shift.morning;
    if (v == '2' || v == 'afternoon' || v == 'a') return Shift.afternoon;
    if (v == '3' || v == 'night' || v == 'n') return Shift.night;
    return null;
  }

  static Position? _parsePosition(String? s) {
    if (s == null) return null;
    final v = s.trim().toLowerCase();
    if (v.contains('account')) return Position.accountant;
    if (v.contains('recept')) return Position.receptionist;
    return null;
  }

  static DateTime _parseDate(String s) {
    try {
      final parsed = DateTime.parse(s);
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (e) {
      throw ArgumentError('Invalid date format. Use YYYY-MM-DD');
    }
  }
}