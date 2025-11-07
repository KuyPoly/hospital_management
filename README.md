# Hospital Management — CLI (Dart)

This project is a simple console-based Hospital Management System built with Dart. It handles staff management (including doctors, nurses, and administrators) through CRUD operations, supports staff filtering for easier searching, provides department viewing, and tracks overtime with role-based bonuses.

## Features
- Add / update / delete staff 
- Assign staff to departments
- Approve overtime with validation and bonus pay calculation
- Salary calculation 
- JSON-backed persistence 
- Unit tests for core domain and service logic

## Project layout
- lib/
  - ui/console.dart — interactive console UI (prompts, formatting)
  - service/staff_service.dart — input parsing & validation, factories
  - domain/*.dart — entities and business rules (Staff, Doctor, Nurse, Admin, Department, Overtime, StaffManager)
  - data/*_repository.dart — read/write JSON files
  - data/*.json — runtime data (staff.json, departments.json)
- test/ — unit tests
- pubspec.yaml — package config


## How to run
1. clone this project
  - https://github.com/KuyPoly/hospital_management.git

2. nevigate to the project
  - cd hospital_management

3. run the main program
  - dart run

4. to run unit test
  - dart test

## Running tests
- Run all tests:
  - dart test


## Data format examples
Staff :
```json
{
  "type": "doctor",
  "staffId": "93bf70a6-573c-4b98-80e1-ea47bdbbd82e",
  "name": "Kuy Poly",
  "email": "ly@gmail.com",
  "phoneNum": "0123456789",
  "gender": "male",
  "role": "doctor",
  "specialization": "Bone",
  "overtime": [
    { "overtimeId":"...", "date":"2025-11-06", "hours":2, "rate":80.0 }
  ]
}
```

Department :
```json
{
  "depId": "fa80a709-4d21-4033-a89f-614cb29f3eb1",
  "type": "cardiology",
  "desc": "Heart care unit",
  "staffIds": []
}
```
