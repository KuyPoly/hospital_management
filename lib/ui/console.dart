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
    for (final s in loaded) staffManager.addStaff(s);

    // load departments (merge into manager)
    final deps = await _deptRepo.loadAll();
    for (final d in deps) {
      staffManager.addDepartment(d);
    }

    while (true) {
      _clearConsole();
      _printMainMenu();
      final choice = _readMenuChoice(0, 10);
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
        case 10:
          await _updateDepartment();
          break;
      }
    }
  }

  // --- helpers ---

  void _printMainMenu() {
    print("================= STAFF MANAGEMENT =================");
    print("1. Add staff");
    print("2. Update staff (full edit)");
    print("3. Delete staff");
    print("4. View all staff");
    print("5. Find staff by ID");
    print("6. Find staff by department");
    print("7. Find staff by role");
    print("8. Approve overtime");
    print("9. View departments");
    print("10. Update / manage departments");
    print("0. Exit");
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

  Gender _readGender(String prompt) {
    while (true) {
      final v = _read(prompt).toLowerCase();
      if (v == 'male' || v == 'm') return Gender.male;
      if (v == 'female' || v == 'f') return Gender.female;
      print('Enter "male" or "female".');
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

  // Shift helpers for Nurse enum
  Shift _readShift(String prompt, {Shift? defaultShift}) {
    final choices = {
      '1': Shift.morning,
      '2': Shift.afternoon,
      '3': Shift.night,
      'morning': Shift.morning,
      'afternoon': Shift.afternoon,
      'night': Shift.night,
      'm': Shift.morning,
      'a': Shift.afternoon,
      'n': Shift.night,
    };
    final defaultPrompt = defaultShift != null ? ' [${defaultShift.displayName}]' : '';
    while (true) {
      final input = _read('$prompt$defaultPrompt: ', defaultValue: defaultShift?.value);
      final key = input.toLowerCase();
      if (choices.containsKey(key)) return choices[key]!;
      // also accept numeric tokens like "1", "2", "3"
      final mapped = choices[input.toLowerCase()];
      if (mapped != null) return mapped;
      print('Enter 1=Morning, 2=Afternoon, 3=Night (or name).');
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
    final gender = _readGender('Gender (male / female): ');
    final baseSalary = _readDouble('Base salary (>0): ', min: 0.01);
    final experienceYear = _readInt('Experience year (>=0): ', min: 0);

    Staff staff;
    if (type == 'doctor') {
      final spec = _readNonEmpty('Specialization: ');
      staff = Doctor(
        name: name,
        email: email,
        phoneNum: phone,
        gender: gender,
        baseSalary: baseSalary,
        experienceYear: experienceYear,
        specialization: spec,
      );
    } else if (type == 'nurse') {
      print('Choose shift: 1) Morning  2) Afternoon  3) Night');
      final shift = _readShift('Shift');
      staff = Nurse(
        name: name,
        email: email,
        phoneNum: phone,
        gender: gender,
        baseSalary: baseSalary,
        experienceYear: experienceYear,
        shift: shift,
      );
    } else {
      final pos = _readPosition();
      staff = Admin(
        name: name,
        email: email,
        phoneNum: phone,
        gender: gender,
        baseSalary: baseSalary,
        experienceYear: experienceYear,
        position: pos,
      );
    }

    staffManager.addStaff(staff);

    // Ask to assign department (enum)
    final assign = _read('Assign department now? (y/n): ').toLowerCase();
    if (assign == 'y' || assign == 'yes') {
      final dept = await _chooseDepartmentOrCreate();
      if (dept != null) {
        dept.addStaff(staff);
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
    print('Departments:');
    for (var i = 0; i < staffManager.departmentList.length; i++) {
      final d = staffManager.departmentList[i];
      print('$i) ${d.name} (${d.depId}) - ${d.desc} [staff: ${d.staffIds.length}]');
    }
    for (var i = 0; i < DepartmentType.values.length; i++) {
      print('t$i) ${DepartmentType.values[i].displayName}');
    }
    print('c) Create new department entry (choose type + desc)');
    print('x) Cancel');
    while (true) {
      final sel = _read('Choose department index, "t<idx>", "c" or "x": ').toLowerCase();
      if (sel == 'x') return null;
      if (sel == 'c') {
        final typeIndex = _readInt('Department type index: ', min: 0, max: DepartmentType.values.length - 1);
        final desc = _read('Description (optional): ');
        final dept = staffManager.createDepartmentIfMissing(DepartmentType.values[typeIndex], desc: desc);
        return dept;
      }
      if (sel.startsWith('t')) {
        final idx = int.tryParse(sel.substring(1));
        if (idx != null && idx >= 0 && idx < DepartmentType.values.length) {
          final chosen = DepartmentType.values[idx];
          final dept = staffManager.createDepartmentIfMissing(chosen, desc: '');
          return dept;
        }
      }
      final idx = int.tryParse(sel);
      if (idx != null && idx >= 0 && idx < staffManager.departmentList.length) {
        final chosen = staffManager.departmentList[idx];
        return chosen;
      }
      print('Invalid selection.');
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
    // validate email
    final emailRe = RegExp(r'^[\w\.\-]+@[A-Za-z0-9\.\-]+\.[A-Za-z]{2,}$');
    if (!emailRe.hasMatch(newEmail)) {
      print('Invalid email entered. Update aborted.');
      await _pauseAndClear();
      return;
    }
    final newPhone = _read('Phone [${old.phoneNum}]: ', defaultValue: old.phoneNum);
    final phoneRe = RegExp(r'^0\d{8,9}$');
    if (!phoneRe.hasMatch(newPhone)) {
      print('Invalid phone. Update aborted.');
      await _pauseAndClear();
      return;
    }
    final genderStr = _read('Gender (male/female) [${old.gender.toString().split('.').last}]: ',
        defaultValue: old.gender.toString().split('.').last);
    final newGender = (genderStr.toLowerCase() == 'male') ? Gender.male : Gender.female;
    final baseSalaryStr = _read('Base salary [${old.baseSalary}]: ', defaultValue: old.baseSalary.toString());
    final newBaseSalary = double.tryParse(baseSalaryStr);
    if (newBaseSalary == null || newBaseSalary <= 0) {
      print('Invalid base salary. Update aborted.');
      await _pauseAndClear();
      return;
    }
    final experienceStr = _read('Experience years [${old.experienceYear}]: ', defaultValue: old.experienceYear.toString());
    final newExperience = int.tryParse(experienceStr);
    if (newExperience == null || newExperience < 0) {
      print('Invalid experience year. Update aborted.');
      await _pauseAndClear();
      return;
    }

    // role specific input
    String? newSpec;
    Shift? newShift;
    Position? newPos;
    if (newRole == 'doctor') {
      if (old is Doctor) {
        newSpec = _read('Specialization [${old.specialization}]: ', defaultValue: old.specialization);
      } else {
        newSpec = _readNonEmpty('Specialization (required for doctor): ');
      }
    } else if (newRole == 'nurse') {
      if (old is Nurse) {
        print('Choose shift: 1) Morning 2) Afternoon 3) Night');
        newShift = _readShift('Shift', defaultShift: old.shift);
      } else {
        print('Choose shift: 1) Morning 2) Afternoon 3) Night');
        newShift = _readShift('Shift');
      }
    } else {
      if (old is Admin) {
        final posStr =
            _read('Position (accountant/receptionist) [${old.position.toString().split('.').last}]: ',
                defaultValue: old.position.toString().split('.').last);
        newPos = posStr.toLowerCase().contains('account') ? Position.accountant : Position.receptionist;
      } else {
        newPos = _readPosition();
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

    // create new instance preserving id, overtime, bonus
    Staff newStaff;
    if (newRole == 'doctor') {
      newStaff = Doctor(
        staffId: old.staffId,
        name: newName,
        email: newEmail,
        phoneNum: newPhone,
        gender: newGender,
        baseSalary: newBaseSalary,
        experienceYear: newExperience,
        departmentId: chosenDept?.depId,
        specialization: newSpec ?? '',
      );
    } else if (newRole == 'nurse') {
      newStaff = Nurse(
        staffId: old.staffId,
        name: newName,
        email: newEmail,
        phoneNum: newPhone,
        gender: newGender,
        baseSalary: newBaseSalary,
        experienceYear: newExperience,
        departmentId: chosenDept?.depId,
        shift: newShift ?? (old is Nurse ? old.shift : Shift.morning),
      );
    } else {
      newStaff = Admin(
        staffId: old.staffId,
        name: newName,
        email: newEmail,
        phoneNum: newPhone,
        gender: newGender,
        baseSalary: newBaseSalary,
        experienceYear: newExperience,
        departmentId: chosenDept?.depId,
        position: newPos ?? Position.receptionist,
      );
    }

    // copy overtime and bonus
    for (final ot in old.overtimeList) {
      newStaff.addOvertime(ot);
    }
    if (old.bonusSalary > 0) {
      newStaff.addBonus(old.bonusSalary);
    }

    // replace in manager
    staffManager.removeStaff(old);
    staffManager.addStaff(newStaff);

    // ensure department mapping
    if (chosenDept != null) {
      // remove old mapping from other departments if any
      for (final d in staffManager.departmentList) {
        if (d.staffIds.contains(newStaff.staffId) && d.depId != chosenDept.depId) {
          d.removeStaff(newStaff);
        }
      }
      chosenDept.addStaff(newStaff);
    }

    await _persist();
    print('Staff updated: ${newStaff.displayInfo()}');
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
        // lookup and show department details if present
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

    // Date input and immediate validation (not future, <=30 days)
    DateTime otDay;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    while (true) {
      final dateStr = _read('Date (YYYY-MM-DD) (or "x" to cancel): ');
      if (dateStr.toLowerCase() == 'x') {
        await _pauseAndClear();
        return;
      }
      try {
        final parsed = DateTime.parse(dateStr);
        otDay = DateTime(parsed.year, parsed.month, parsed.day); // normalize
      } catch (_) {
        print('Invalid date format. Use YYYY-MM-DD.');
        continue;
      }
      if (otDay.isAfter(today)) {
        print('Overtime date cannot be in the future.');
        continue;
      }
      final daysDifference = today.difference(otDay).inDays;
      if (daysDifference > 30) {
        print('Overtime date is older than 30 days.');
        continue;
      }
      break;
    }

    // Hours
    final hours = _readInt('Hours (1-16): ', min: 1, max: 16);

    // Compute default rate (same logic as domain percentages) and show to user
    final defaultPct = staff.role == Role.doctor
        ? 0.10
        : staff.role == Role.nurse
            ? 0.08
            : 0.08;
    double defaultRate = staff.baseSalary * defaultPct;
    final isWeekend = otDay.weekday == DateTime.saturday || otDay.weekday == DateTime.sunday;
    if (isWeekend) defaultRate *= 1.25;

    // Ask user to accept default or provide custom rate
    double? rate;
    while (true) {
      final input = _read('Default rate for this staff is ${defaultRate.toStringAsFixed(2)}. Enter custom rate or press Enter to use default (or "x" to cancel): ');
      if (input.toLowerCase() == 'x') {
        await _pauseAndClear();
        return;
      }
      if (input.trim().isEmpty) {
        rate = defaultRate;
        break;
      }
      final parsed = double.tryParse(input);
      if (parsed == null || parsed <= 0) {
        print('Invalid rate. Must be a positive number.');
        continue;
      }
      rate = parsed;
      break;
    }

    try {
      staffManager.approveOvertime(staff, date: otDay, hours: hours, rate: rate);
      // add bonus when overtime approved (10% of overtime pay)
      final lastOt = staff.overtimeList.isNotEmpty ? staff.overtimeList.last : null;
      if (lastOt != null) {
        final bonus = lastOt.calculateOvertimePay() * 0.10;
        staff.addBonus(bonus);
      }
      await _persist();
      print('Overtime approved for ${staff.name} on ${otDay.toIso8601String()} (hours: $hours, rate: ${rate.toStringAsFixed(2)})');
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

  Future<void> _updateDepartment() async {
    print('Departments:');
    for (var i = 0; i < staffManager.departmentList.length; i++) {
      final d = staffManager.departmentList[i];
      print('[$i] ${d.name} (${d.depId}) - ${d.desc}');
    }
    print('c) Create new department');
    print('x) Cancel');
    while (true) {
      final sel = _read('Choose index, "c" or "x": ').toLowerCase();
      if (sel == 'x') {
        await _pauseAndClear();
        return;
      }
      if (sel == 'c') {
        final typeIndex = _readInt('Department type index: ', min: 0, max: DepartmentType.values.length - 1);
        final desc = _read('Description (optional): ');
        final dept = staffManager.createDepartmentIfMissing(DepartmentType.values[typeIndex], desc: desc);
        print('Created/ensured department ${dept.name} (${dept.depId})');
        await _persist();
        await _pauseAndClear();
        return;
      }
      final idx = int.tryParse(sel);
      if (idx == null || idx < 0 || idx >= staffManager.departmentList.length) {
        print('Invalid selection.');
        continue;
      }
      final dept = staffManager.departmentList[idx];
      print('Selected ${dept.name} (${dept.depId})');
      print('1) Update description');
      print('2) Remove department (will clear departmentId from staff)');
      print('x) Cancel');
      final action = _read('Choose action: ').toLowerCase();
      if (action == '1') {
        final newDesc = _read('New description: ');
        try {
          staffManager.updateDepartmentDescription(dept.depId, newDesc);
          print('Description updated.');
          await _persist();
        } catch (e) {
          print('Failed to update department: $e');
        }
        await _pauseAndClear();
        return;
      } else if (action == '2') {
        final confirm = _read('Type "yes" to confirm removal: ').toLowerCase();
        if (confirm != 'yes') {
          print('Removal cancelled.');
          await _pauseAndClear();
          return;
        }
        final removed = staffManager.removeDepartment(dept.depId);
        if (removed) {
          await _persist();
          print('Department removed and assignments cleared.');
        } else {
          print('Department not found / already removed.');
        }
        await _pauseAndClear();
        return;
      } else {
        await _pauseAndClear();
        return;
      }
    }
  }
}