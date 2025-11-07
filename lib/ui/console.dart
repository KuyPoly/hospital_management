import "dart:io";
import 'dart:async';
import '../domain/staff_manager.dart';
import '../data/staff_repository.dart';
import '../data/department_repository.dart';
import '../domain/doctor.dart';
import '../domain/nurse.dart';
import '../domain/admin.dart';
import '../domain/staff.dart';
import '../domain/overtime.dart';
import '../domain/department.dart';
import '../service/staff_service.dart';

class Console {
  final StaffManager staffManager;
  final StaffRepository _repo;
  final DepartmentRepository _deptRepo;
  final String _dataPath;

  Console(this.staffManager, this._repo, this._deptRepo, {String dataPath = 'lib/data/data.json'})
      : _dataPath = dataPath;

  Future<void> start() async {
    // load existing data
    final loaded = await _repo.loadAll();
    for (final s in loaded){
      staffManager.addStaff(s);
    }

    // load departments (merge into manager)
    final deps = await _deptRepo.loadAll();
    for (final d in deps) {
      staffManager.addDepartment(d);
    }

    while (true) {
      _clearConsole();
      _printMainMenu();
      final choice = _readMenuChoice(0, 9);
      if (choice == 0) {
        print('Exiting...');
        break;
      }

      switch (choice) {
        case 1:
          await _addStaff();
          break;
        case 2:
          await _updateStaff();
          break;
        case 3:
          await _deleteStaff();
          break;
        case 4:
          await _viewAllStaff();
          break;
        case 5:
          await _findById();
          break;
        case 6:
          await _findByDep();
          break;
        case 7:
          await _findByRole();
          break;
        case 8:
          await _approveOvertime();
          break;
        case 9:
          await _viewDepartments();
          break;
      }
    }
  }

  // --- helpers ---

  void _printMainMenu() {
    printHeader("STAFF MANAGEMENT");
    printLine("1", "Add staff");
    printLine("2", "Update staff (full edit)");
    printLine("3", "Delete staff");
    printLine("4", "View all staff");
    printLine("5", "Find staff by ID");
    printLine("6", "Find staff by department");
    printLine("7", "Find staff by role");
    printLine("8", "Approve overtime");
    printLine("9", "View departments");
    printLine("0", "Exit");
  }

  // Clean header style
  void printHeader(String title) {
    print("====================================================");
    print("                     $title");
    print("====================================================");
  }

  // Clean section separator
  void printSection(String title) {
    print("----------------------------------------------------");
    print(" $title");
    print("----------------------------------------------------");
  }

  // Clean line for menu or info
  void printLine(String label, String value) {
    print("${label.padRight(1)} . $value");
  }

  void _clearConsole() {
    // ANSI clear; works on most terminals (Windows 10+ supports ANSI)
    stdout.write('\x1B[2J\x1B[0;0H');
  }

  Future<void> _pauseAndClear() async {
    stdout.write('\nPress Enter to continue...');
    stdin.readLineSync();
    _clearConsole();
  }

  String _read(String prompt, {String? defaultValue}) {
    stdout.write(prompt);
    final line = stdin.readLineSync();
    if (line == null || line.trim().isEmpty) {
      if (defaultValue != null) return defaultValue;
      return '';
    }
    return line.trim();
  }

  int _readMenuChoice(int min, int max) {
    while (true) {
      final input = _read('Enter choice: ');
      final parsed = int.tryParse(input);
      if (parsed == null || parsed < min || parsed > max) {
        print('Please enter a number between $min and $max.');
        continue;
      }
      return parsed;
    }
  }

  int _readInt(String prompt, {int? defaultValue, int? min, int? max}) {
    while (true) {
      final v = _read(prompt, defaultValue: defaultValue?.toString());
      final parsed = int.tryParse(v);
      if (parsed == null) {
        print('Please enter a valid integer.');
        continue;
      }
      if (min != null && parsed < min) {
        print('Value must be >= $min.');
        continue;
      }
      if (max != null && parsed > max) {
        print('Value must be <= $max.');
        continue;
      }
      return parsed;
    }
  }

  double _readDouble(String prompt, {double? defaultValue, double? min}) {
    while (true) {
      final v = _read(prompt, defaultValue: defaultValue?.toString());
      final parsed = double.tryParse(v);
      if (parsed == null) {
        print('Please enter a valid number.');
        continue;
      }
      if (min != null && parsed < min) {
        print('Value must be >= $min.');
        continue;
      }
      return parsed;
    }
  }

  String _readNonEmpty(String prompt) {
    while (true) {
      final v = _read(prompt);
      if (v.isEmpty) {
        print('Value cannot be empty.');
        continue;
      }
      return v;
    }
  }

  String _readEmail(String prompt) {
    final emailRe = RegExp(r'^[\w\.\-]+@[A-Za-z0-9\.\-]+\.[A-Za-z]{2,}$');
    while (true) {
      final v = _readNonEmpty(prompt);
      if (!emailRe.hasMatch(v)) {
        print('Invalid email format.');
        continue;
      }
      return v;
    }
  }

  String _readPhone(String prompt) {
    final phoneRe = RegExp(r'^0\d{8,9}$'); // starts with 0, total 9 or 10 digits
    while (true) {
      final v = _readNonEmpty(prompt);
      if (!phoneRe.hasMatch(v)) {
        print('Phone must start with 0 and be 9 or 10 digits long.');
        continue;
      }
      return v;
    }
  }

  String _readStaffType(String prompt) {
    while (true) {
      final v = _read(prompt).toLowerCase();
      if (v.contains('doctor') || v == '1' || v == 'd') return 'doctor';
      if (v.contains('nurse') || v == '2' || v == 'n') return 'nurse';
      if (v.contains('admin') || v.contains('administration') || v == '3' || v == 'a') return 'admin';
      print('Enter "doctor", "nurse" or "admin".');
    }
  }

  String _readStaffTypeWithDefault(String prompt, String currentRole) {
    while (true) {
      final v = _read(prompt, defaultValue: currentRole).toLowerCase();
      if (v.contains('doctor') || v == '1' || v == 'd') return 'doctor';
      if (v.contains('nurse') || v == '2' || v == 'n') return 'nurse';
      if (v.contains('admin') || v.contains('administration') || v == '3' || v == 'a') return 'admin';
      print('Enter "doctor", "nurse" or "admin".');
    }
  }


  Future<void> _persist() async {
    try {
      await _repo.saveAll(staffManager.staffList);
      await _deptRepo.saveAll(staffManager.departmentList);
    } catch (e) {
      stderr.writeln('Failed to save data: $e');
    }
  }

  // --- menu actions ---

  Future<void> _addStaff() async {
    final type = _readStaffType('Enter type (doctor / nurse / admin): ');

    final name = _readNonEmpty('Name: ');
    final email = _readEmail('Email: ');
    final phone = _readPhone('Phone: ');
    final gender = _read('Gender (male / female): ');
    final baseSalary = _readDouble('Base salary (>0): ', min: 0.01);
    final experienceYear = _readInt('Experience year (>=0): ', min: 0);

    // role-specific raw inputs (UI only)
    String? specialization;
    String? shiftStr;
    String? positionStr;
    if (type == 'doctor') {
      specialization = _readNonEmpty('Specialization: ');
    } else if (type == 'nurse') {
      print('Choose shift: 1) Morning  2) Afternoon  3) Night');
      shiftStr = _read('Shift (1/2/3 or morning/afternoon/night): ');
    } else {
      final pos = _readPosition();
      positionStr = pos.toString().split('.').last;
    }

    Staff staff;
    try {
      staff = StaffService.createStaff(
        type: type,
        name: name,
        email: email,
        phone: phone,
        genderStr: gender,
        baseSalary: baseSalary,
        experienceYear: experienceYear,
        specialization: specialization,
        shiftStr: shiftStr,
        positionStr: positionStr,
      );
      staffManager.addStaff(staff);
    } catch (e) {
      print('Failed to add staff: $e');
      await _pauseAndClear();
      return;
    }

    // Ask to assign department (enum)
    final assign = _read('Assign department now? (y/n): ').toLowerCase();
    if (assign == 'y' || assign == 'yes') {
      final dept = await _chooseDepartmentOrCreate();
      if (dept != null) {
        // Avoid duplicate assignment if already present
        if (!dept.staffIds.contains(staff.staffId)) {
          dept.addStaff(staff);
        } else {
          print('Staff already assigned to department ${dept.name}.');
        }
        // Ensure staff record references the department
        staff.departmentId = dept.depId;
      }
    }

    await _persist();
    print('Staff added: ${staff.displayInfo()}');
    await _pauseAndClear();
  }

  Position _readPosition() {
    while (true) {
      final posStr = _read('Position (accountant / receptionist): ').toLowerCase();
      if (posStr.contains('account')) return Position.accountant;
      if (posStr.contains('recept')) return Position.receptionist;
      print('Enter "accountant" or "receptionist".');
    }
  }

  Future<Department?> _chooseDepartmentOrCreate() async {
    final deps = staffManager.departmentList;
    if (deps.isEmpty) {
      print('No departments available to assign. You can assign later from the domain or add departments outside this UI.');
      return null;
    }

    print('Departments:');
    for (var i = 0; i < deps.length; i++) {
      final d = deps[i];
      print('$i) ${d.name} (${d.depId}) - ${d.desc} [staff: ${d.staffIds.length}]');
    }
    print('x) Cancel');

    while (true) {
      final sel = _read('Choose department index or "x": ').toLowerCase();
      if (sel == 'x') return null;
      final idx = int.tryParse(sel);
      if (idx != null && idx >= 0 && idx < deps.length) {
        return deps[idx];
      }
      print('Invalid selection. Enter a department index or "x" to cancel.');
    }
  }

  Future<void> _updateStaff() async {
    final id = _readNonEmpty('Enter staff ID to update (or "x" to cancel): ');
    if (id.toLowerCase() == 'x') {
      await _pauseAndClear();
      return;
    }
    final old = staffManager.findStaffById(id);
    if (old == null) {
      print('Staff not found.');
      await _pauseAndClear();
      return;
    }

    // collect new values (blank = keep current)
    final currentRoleStr = old.role.toString().split('.').last;
    final newRole = _readStaffTypeWithDefault('Role ($currentRoleStr) : ', currentRoleStr);
    final newName = _read('Name [${old.name}]: ', defaultValue: old.name);
    final newEmail = _read('Email [${old.email}]: ', defaultValue: old.email);
    final newPhone = _read('Phone [${old.phoneNum}]: ', defaultValue: old.phoneNum);
    final genderStr = _read('Gender (male/female) [${old.gender.toString().split('.').last}]: ',
        defaultValue: old.gender.toString().split('.').last);
    final baseSalaryStr = _read('Base salary [${old.baseSalary}]: ', defaultValue: old.baseSalary.toString());
    final experienceStr = _read('Experience years [${old.experienceYear}]: ', defaultValue: old.experienceYear.toString());

    // role specific input
    String? newSpec;
    String? newShiftStr;
    String? newPosStr;
    if (newRole == 'doctor') {
      if (old is Doctor) {
        newSpec = _read('Specialization [${old.specialization}]: ', defaultValue: old.specialization);
      } else {
        newSpec = _readNonEmpty('Specialization (required for doctor): ');
      }
    } else if (newRole == 'nurse') {
      if (old is Nurse) {
        print('Choose shift: 1) Morning 2) Afternoon 3) Night');
        newShiftStr = _read('Shift (1/2/3 or morning/afternoon/night): ', defaultValue: old.shift.value);
      } else {
        print('Choose shift: 1) Morning 2) Afternoon 3) Night');
        newShiftStr = _read('Shift (1/2/3 or morning/afternoon/night): ');
      }
    } else {
      if (old is Admin) {
        final posStr =
            _read('Position (accountant/receptionist) [${old.position.toString().split('.').last}]: ',
                defaultValue: old.position.toString().split('.').last);
        newPosStr = posStr;
      } else {
        final pos = _readPosition();
        newPosStr = pos.toString().split('.').last;
      }
    }

    // department
    final assign = _read('Change/assign department? (y/n): ').toLowerCase();
    Department? chosenDept;
    if (assign == 'y' || assign == 'yes') {
      chosenDept = await _chooseDepartmentOrCreate();
    } else {
      // keep existing mapping
      if (old.departmentId != null) {
        final idx = staffManager.departmentList.indexWhere((d) => d.depId == old.departmentId);
        if (idx != -1) {
          chosenDept = staffManager.departmentList[idx];
        } else {
          chosenDept = null;
        }
      }
    }

    // delegate construction/validation to service
    final parsedBase = double.tryParse(baseSalaryStr) ?? -1.0;
    final parsedExp = int.tryParse(experienceStr) ?? -1;
    Staff updated;
    try {
      updated = StaffService.updateStaff(
        old,
        newRole: newRole,
        name: newName,
        email: newEmail,
        phone: newPhone,
        genderStr: genderStr,
        baseSalary: parsedBase,
        experienceYear: parsedExp,
        specialization: newSpec,
        shiftStr: newShiftStr,
        positionStr: newPosStr,
        departmentId: chosenDept?.depId ?? old.departmentId,
      );
    } catch (e) {
      print('Failed to update staff: $e');
      await _pauseAndClear();
      return;
    }

    staffManager.removeStaff(old);
    staffManager.addStaff(updated);

    if (chosenDept != null) {
      // remove old mapping from other departments if any
      for (final d in staffManager.departmentList) {
        if (d.staffIds.contains(updated.staffId) && d.depId != chosenDept.depId) {
          d.removeStaff(updated);
        }
      }
      // Add only if not already present and set reference on staff
      if (!chosenDept.staffIds.contains(updated.staffId)) {
        chosenDept.addStaff(updated);
      }
      updated.departmentId = chosenDept.depId;
    } else if (updated.departmentId != null) {
      // If user did not change department, re-attach the updated staff to the existing dept
      // remove old Staff may have removed the id from the department list
      final idx = staffManager.departmentList.indexWhere((d) => d.depId == updated.departmentId);
      if (idx != -1) {
        final existingDept = staffManager.departmentList[idx];
        if (!existingDept.staffIds.contains(updated.staffId)) {
          existingDept.addStaff(updated);
        }
      }
    }

    await _persist();
    print('Staff updated: ${updated.displayInfo()}');
    await _pauseAndClear();
  }

  Future<void> _deleteStaff() async {
    final id = _readNonEmpty('Enter staff ID to delete (or "x" to cancel): ');
    if (id.toLowerCase() == 'x') {
      await _pauseAndClear();
      return;
    }
    final staff = staffManager.findStaffById(id);
    if (staff == null) {
      print('Staff not found.');
      await _pauseAndClear();
      return;
    }
    final confirm = _read('Type "yes" to confirm deletion: ').toLowerCase();
    if (confirm != 'yes') {
      print('Deletion cancelled.');
      await _pauseAndClear();
      return;
    }
    staffManager.removeStaff(staff);
    await _persist();
    print('Deleted staff ${staff.name} (${staff.staffId})');
    await _pauseAndClear();
  }

  Future<void> _viewAllStaff() async {
    final list = staffManager.staffList;
    if (list.isEmpty) {
      print('No staff found.');
    } else {
      for (final s in list) {
        // show full staff info
        print(s.displayInfo());
        if (s.departmentId != null) {
          final idx = staffManager.departmentList.indexWhere((d) => d.depId == s.departmentId);
          if (idx != -1) {
            final dept = staffManager.departmentList[idx];
            print('Department: ${dept.name} (${dept.depId})');
            print('Description: ${dept.desc}');
          } else {
            print('Department: (ID ${s.departmentId}) — not found in departments.json');
          }
        }
        print('---');
      }
    }
    await _pauseAndClear();
  }

  Future<void> _findById() async {
    final id = _readNonEmpty('Enter staff ID (or "x" to cancel): ');
    if (id.toLowerCase() == 'x') {
      await _pauseAndClear();
      return;
    }
    final staff = staffManager.findStaffById(id);
    if (staff == null) {
      print('Staff not found.');
    } else {
      print(staff.displayInfo());
    }
    await _pauseAndClear();
  }

  Future<void> _findByDep() async {
    final q = _read('Search by department name or id (or "x" to cancel): ');
    if (q.toLowerCase() == 'x') {
      await _pauseAndClear();
      return;
    }
    if (q.isEmpty) {
      print('Empty query.');
      await _pauseAndClear();
      return;
    }
    // try id first
    final byId = staffManager.filterStaffByDepartmentId(q);
    if (byId.isNotEmpty) {
      for (final s in byId) {
        print(s.displayInfo());
      }
      await _pauseAndClear();
      return;
    }
    final byName = staffManager.filterStaffByDepartmentName(q);
    if (byName.isEmpty) {
      print('No staff found for department.');
    } else {
      for (final s in byName) {
        print(s.displayInfo());
      }
    }
    await _pauseAndClear();
  }

  Future<void> _findByRole() async {
    final r = _read('Enter role (doctor / nurse / administrationStaff) (or "x" to cancel): ').toLowerCase();
    if (r == 'x') {
      await _pauseAndClear();
      return;
    }
    final role = r.contains('doctor')
        ? Role.doctor
        : r.contains('nurse')
            ? Role.nurse
            : Role.administrationStaff;
    final results = staffManager.findStaffByRole(role);
    if (results.isEmpty) {
      print('No staff with role $role');
    } else {
      for (final s in results) {
        print(s.displayInfo());
      }
    }
    await _pauseAndClear();
  }

  Future<void> _approveOvertime() async {
    final id = _readNonEmpty('Enter staff ID (or "x" to cancel): ');
    if (id.toLowerCase() == 'x') {
      await _pauseAndClear();
      return;
    }
    final staff = staffManager.findStaffById(id);
    if (staff == null) {
      print('Staff not found.');
      await _pauseAndClear();
      return;
    }

    // Delegate parsing/validation to service + manager
    final dateStr = _read('Date (YYYY-MM-DD) (or "x" to cancel): ');
    if (dateStr.toLowerCase() == 'x') { await _pauseAndClear(); return; }
    final hours = _readInt('Hours (1-16): ', min: 1, max: 16);
    final rateInput = _read('Rate (leave empty to use default) (or "x" to cancel): ');
    if (rateInput.toLowerCase() == 'x') { await _pauseAndClear(); return; }

    try {
      StaffService.approveOvertimeFromInput(
        staffManager,
        staff,
        dateStr: dateStr,
        hours: hours,
        rateStr: rateInput.trim().isEmpty ? null : rateInput,
      );

      // Bonus is handled by StaffManager.approveOvertime 
      await _persist();
      print('Overtime approved for ${staff.name}');
    } catch (e) {
      print('Failed to approve overtime: $e');
    }
    await _pauseAndClear();
  }

  Future<void> _viewDepartments() async {
    final deps = staffManager.departmentList;
    if (deps.isEmpty) {
      print('No departments.');
    } else {
      for (var i = 0; i < deps.length; i++) {
        final d = deps[i];
        print('[$i] ${d.name} (${d.depId}) - ${d.desc} - staff: ${staffManager.filterStaffByDepartmentId(d.depId).length}');
      }
    }
    await _pauseAndClear();
  }

}