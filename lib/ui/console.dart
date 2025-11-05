import "dart:io";
import '../domain/admin.dart';
import '../domain/department.dart';
import '../domain/doctor.dart';
import '../domain/nurse.dart';
import '../domain/overtime.dart';
import '../domain/staff.dart';
import '../domain/staff_manager.dart';

class Console {
  final StaffManager staffManager;

  void start(){
    int choice = -1;
    while(choice != 0){
      print("================= STAFF MANAGEMENT =================");
      print("1. Add staff");
      print("2. Update staff");
      print("3. Delete staff");
      print("4. View all staff");
      print("5. Find staff by ID");
      print("6. Find staff by department");
      print("7. Find staff by role");
      print("8. Approve overtime");
      print("9. Assign department");
      print("0. Exit");
      stdout.write('Enter choice: ');
      choice = int.tryParse(stdin.readLineSync() ?? '') ?? -1;

      switch(choice){
        case 1:
          addStaff();
          break;
        case 2:
          updateStaff();
          break;
        case 3:
          deleteStaff();
          break;
        case 4:
          viewAllStaff();
          break;
        case 5:
          findById();
          break;
        case 6:
          findByDep();
          break;
        case 7:
          findByRole();
          break;
        case 8:
          approveOvertime();
          break;
        case 9:
          assignDep();
          break;
        default:
          print("Invalid input!");
      }
    }
  }
}