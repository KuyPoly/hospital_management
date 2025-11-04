class Overtime {
  final String overtimeId;
  final int hours;
  final double rate;
  final DateTime date;

  Overtime({
    required this.overtimeId, 
    required this.date, 
    required this.hours, 
    required this.rate,
  });

  double calculateOvertimePay(Overtime overtime) {
    return overtime.hours * overtime.rate;
  }
}