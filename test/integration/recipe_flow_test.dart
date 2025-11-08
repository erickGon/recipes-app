import 'package:flutter_test/flutter_test.dart';
import 'package:recepies_app/features/recipes/domain/recipe.dart';

void main() {
  group('Recipe Flow Integration', () {
    test('should create and manage recipe list', () {
      // Arrange
      final recipes = <Recipe>[];
      final newRecipe = Recipe(
        id: '1',
        patientId: 'patient-001',
        medication: 'Test Med 100mg',
        issuedAt: DateTime(2024, 1, 15),
        doctor: 'Dr. Test',
        notes: 'Test notes',
      );

      // Act - Add recipe
      recipes.add(newRecipe);

      // Assert
      expect(recipes.length, 1);
      expect(recipes.first.id, '1');
      expect(recipes.first.medication, 'Test Med 100mg');
    });

    test('should remove recipe from list by id', () {
      // Arrange
      final recipes = [
        Recipe(
          id: '1',
          patientId: 'patient-001',
          medication: 'Med A',
          issuedAt: DateTime(2024, 1, 15),
          doctor: 'Dr. A',
          notes: 'Notes A',
        ),
        Recipe(
          id: '2',
          patientId: 'patient-002',
          medication: 'Med B',
          issuedAt: DateTime(2024, 1, 16),
          doctor: 'Dr. B',
          notes: 'Notes B',
        ),
      ];

      // Act
      final updatedRecipes = recipes.where((recipe) => recipe.id != '1').toList();

      // Assert
      expect(updatedRecipes.length, 1);
      expect(updatedRecipes.first.id, '2');
    });

    test('should handle multiple filters on recipe list', () {
      // Arrange
      final recipes = [
        Recipe(
          id: '1',
          patientId: 'patient-001',
          medication: 'Amoxicillin 500mg',
          issuedAt: DateTime(2023, 6, 1),
          doctor: 'Dr. Smith',
          notes: 'Take twice daily',
        ),
        Recipe(
          id: '2',
          patientId: 'patient-002',
          medication: 'Ibuprofen 200mg',
          issuedAt: DateTime(2023, 12, 15),
          doctor: 'Dr. Johnson',
          notes: 'As needed',
        ),
        Recipe(
          id: '3',
          patientId: 'patient-001',
          medication: 'Metformin 850mg',
          issuedAt: DateTime(2024, 1, 10),
          doctor: 'Dr. Smith',
          notes: 'Take with food',
        ),
      ];

      // Act - Filter by patient and date
      final filtered = recipes.where((recipe) {
        final matchesPatient = recipe.patientId == 'patient-001';
        final afterDate = !recipe.issuedAt.isBefore(DateTime(2023, 1, 1));
        return matchesPatient && afterDate;
      }).toList();

      // Assert
      expect(filtered.length, 2);
      expect(filtered.every((r) => r.patientId == 'patient-001'), true);
    });

    test('should sort recipes by date', () {
      // Arrange
      final recipes = [
        Recipe(
          id: '1',
          patientId: 'patient-001',
          medication: 'Med A',
          issuedAt: DateTime(2024, 3, 1),
          doctor: 'Dr. A',
          notes: 'Notes',
        ),
        Recipe(
          id: '2',
          patientId: 'patient-002',
          medication: 'Med B',
          issuedAt: DateTime(2024, 1, 1),
          doctor: 'Dr. B',
          notes: 'Notes',
        ),
        Recipe(
          id: '3',
          patientId: 'patient-003',
          medication: 'Med C',
          issuedAt: DateTime(2024, 2, 1),
          doctor: 'Dr. C',
          notes: 'Notes',
        ),
      ];

      // Act - Sort by date descending (newest first)
      recipes.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));

      // Assert
      expect(recipes[0].id, '1'); // March
      expect(recipes[1].id, '3'); // February
      expect(recipes[2].id, '2'); // January
    });
  });
}

