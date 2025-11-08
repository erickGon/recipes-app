class Recipe {
  final String id;
  final String patientId;
  final String medication;
  final DateTime issuedAt;
  final String doctor;
  final String notes;

  Recipe({
    required this.id,
    required this.patientId,
    required this.medication,
    required this.issuedAt,
    required this.doctor,
    required this.notes,
  });
}


