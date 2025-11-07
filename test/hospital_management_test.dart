import 'package:test/test.dart';
import 'package:hospital_management/service/staff_service.dart';
import 'package:hospital_management/domain/doctor.dart';
import 'package:hospital_management/domain/nurse.dart';
import 'package:hospital_management/domain/admin.dart';
import 'package:hospital_management/domain/staff.dart';
import 'package:hospital_management/domain/overtime.dart';
import 'package:hospital_management/domain/staff_manager.dart';
import 'package:hospital_management/domain/department.dart';

void main() {
  group('StaffService.createStaff', () {
    test('creates a doctor with valid input', () {
      final s = StaffService.createStaff(
        type: 'doctor',
        name: 'Dr Who',
        email: 'drwho@example.com',
        phone: '0123456789',
        genderStr: 'male',
        baseSalary: 1500.0,
        experienceYear: 5,
        specialization: 'Cardiology',
      );
      expect(s, isA<Doctor>());
      final d = s as Doctor;
      expect(d.name, equals('Dr Who'));
      expect(d.specialization, equals('Cardiology'));
    });

    test('creates a nurse with invalid phone number', () {
      expect(
        () => StaffService.createStaff(
          type: 'admin',
          name: 'Alice',
          email: 'alice@gmail.com',
          phone: '012345',
          genderStr: 'female',
          baseSalary: 800.0,
          experienceYear: 1,
          positionStr: 'accountant',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws on invalid email', () {
      expect(
        () => StaffService.createStaff(
          type: 'admin',
          name: 'Alice',
          email: 'not-an-email',
          phone: '0123456789',
          genderStr: 'female',
          baseSalary: 800.0,
          experienceYear: 1,
          positionStr: 'accountant',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Staff.displayInfo', () {
    test('doctor display includes specialty and totals', () {
      final doc = Doctor(
        name: 'Doc',
        email: 'doc@example.com',
        phoneNum: '0123456789',
        gender: Gender.male,
        baseSalary: 1200.0,
        experienceYear: 3,
        specialization: 'Neurology',
      );
      doc.addOvertime(Overtime(date: DateTime(2025, 1, 1), hours: 2, rate: 50.0));
      final info = doc.displayInfo();
      expect(info, contains('Name      : Doc'));
      expect(info, contains('Specialty'));
      expect(info, contains('Neurology'));
      expect(info, contains('Overtime'));
      expect(info, contains('Total pay'));
    });

  });

  group('StaffManager domain tests', () {
    test('approveOvertime adds an overtime entry and computes pay', () {
      final manager = StaffManager();

      final doc = Doctor(
        name: 'Dr Test',
        email: 'drtest@example.com',
        phoneNum: '0123456789',
        gender: Gender.male,
        baseSalary: 1200.0,
        experienceYear: 2,
        specialization: 'General',
      );

      manager.addStaff(doc);

      final otDate = DateTime(2025, 11, 01);
      manager.approveOvertime(doc, date: otDate, hours: 3, rate: 60.0);

      expect(doc.overtimeList.length, equals(1));
      final ot = doc.overtimeList.first;
      expect(ot.date, equals(DateTime(2025, 11, 01)));
      expect(ot.hours, equals(3));
      expect(ot.rate, equals(60.0));
      expect(doc.totalOvertimePay(), closeTo(180.0, 0.001));
    });

    test('filterStaffByDepartmentId and filterStaffByDepartmentName work', () {
      final manager = StaffManager();

      final dep = Department(type: DepartmentType.cardiology, desc: 'Heart care unit');
      // ensure department is known to manager
      manager.addDepartment(dep);

      final nurse = Nurse(
        name: 'Nurse Dept',
        email: 'nurse@example.com',
        phoneNum: '0987654321',
        gender: Gender.female,
        baseSalary: 800.0,
        experienceYear: 1,
        departmentId: dep.depId,
        shift: Shift.morning,
      );

      manager.addStaff(nurse);
      // also ensure department mapping includes staff id (some flows add staff->dept separately)
      dep.addStaff(nurse);

      final byId = manager.filterStaffByDepartmentId(dep.depId);
      expect(byId.length, equals(1));
      expect(byId.first.staffId, equals(nurse.staffId));

      final byName = manager.filterStaffByDepartmentName('cardio');
      expect(byName.length, equals(1));
      expect(byName.first.staffId, equals(nurse.staffId));
    });
  });
}