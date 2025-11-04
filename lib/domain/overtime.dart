import 'package:uuid/uuid.dart';

class Overtime {
  static final Uuid _uuid = Uuid();

  final String _overtimeId;
  final int _hours;
  final double _rate;
  final DateTime _date;

  Overtime({
    required DateTime date,
    required int hours,
    required double rate,
  })  : _overtimeId = _uuid.v4(),
        _date = date,
        _hours = hours,
        _rate = rate;

  String get overtimeId => _overtimeId;
  int get hours => _hours;
  double get rate => _rate;
  DateTime get date => _date;

  double calculateOvertimePay() {
    return _hours * _rate;
  }
}