import 'package:intl/intl.dart';

class RecipeFilters {
  final String? medicationName;
  final DateTime? startDate;
  final DateTime? endDate;

  const RecipeFilters({
    this.medicationName,
    this.startDate,
    this.endDate,
  });

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    final name = medicationName?.trim();
    if (name != null && name.isNotEmpty) {
      params['medicationName'] = name;
    }
    if (startDate != null) {
      params['startDate'] = DateFormat('yyyy-MM-dd').format(startDate!);
    }
    if (endDate != null) {
      params['endDate'] = DateFormat('yyyy-MM-dd').format(endDate!);
    }
    return params;
  }

  bool get hasFilters =>
      (medicationName != null && medicationName!.trim().isNotEmpty) ||
      startDate != null ||
      endDate != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecipeFilters &&
        other.medicationName == medicationName &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(medicationName, startDate, endDate);
}


