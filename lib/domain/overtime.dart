import 'package:uuid/uuid.dart';

class Overtime {
  static final Uuid _uuid = Uuid();

  final String _overtimeId;
  final int _hours;
  final double _rate;
  final DateTime _date;

  Overtime({
    String? overtimeId,
    required DateTime date,
    required int hours,
    required double rate,
  })  : _overtimeId = overtimeId ?? _uuid.v4(),
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

  Map<String, dynamic> toJson() {
    return {
      'overtimeId': _overtimeId,
      'date': _date.toIso8601String(),
      'hours': _hours,
      'rate': _rate,
    };
  }

  factory Overtime.fromJson(Map<String, dynamic> json) {
    return Overtime(
      overtimeId: json['overtimeId'] as String?,
      date: DateTime.parse(json['date'] as String),
      hours: json['hours'] as int,
      rate: (json['rate'] as num).toDouble(),
    );
  }
}