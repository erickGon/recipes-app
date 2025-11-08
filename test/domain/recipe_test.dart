import 'package:flutter_test/flutter_test.dart';
import 'package:recepies_app/features/recipes/domain/recipe.dart';

void main() {
  group('Recipe Model', () {
    test('should create a Recipe with all required fields', () {
      // Arrange
      final issuedDate = DateTime(2024, 1, 15);

      // Act
      final recipe = Recipe(
        id: '123',
        patientId: 'patient-001',
        medication: 'Amoxicillin 500mg',
        issuedAt: issuedDate,
        doctor: 'Dr. Smith',
        notes: 'Take twice daily',
      );

      // Assert
      expect(recipe.id, '123');
      expect(recipe.patientId, 'patient-001');
      expect(recipe.medication, 'Amoxicillin 500mg');
      expect(recipe.issuedAt, issuedDate);
      expect(recipe.doctor, 'Dr. Smith');
      expect(recipe.notes, 'Take twice daily');
    });

    test('should handle DateTime correctly', () {
      // Arrange
      final now = DateTime.now();

      // Act
      final recipe = Recipe(
        id: '1',
        patientId: 'patient-001',
        medication: 'Test Med',
        issuedAt: now,
        doctor: 'Dr. Test',
        notes: 'Test notes',
      );

      // Assert
      expect(recipe.issuedAt, now);
      expect(recipe.issuedAt.year, now.year);
      expect(recipe.issuedAt.month, now.month);
      expect(recipe.issuedAt.day, now.day);
    });
  });
}

