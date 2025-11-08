import 'package:flutter_test/flutter_test.dart';
import 'package:recepies_app/features/recipes/domain/recipe.dart';

void main() {
  group('Date Filtering Logic', () {
    late List<Recipe> testRecipes;

    setUp(() {
      testRecipes = [
        Recipe(
          id: '1',
          patientId: 'patient-001',
          medication: 'Med A',
          issuedAt: DateTime(2023, 6, 1),
          doctor: 'Dr. A',
          notes: 'Notes A',
        ),
        Recipe(
          id: '2',
          patientId: 'patient-002',
          medication: 'Med B',
          issuedAt: DateTime(2023, 12, 15),
          doctor: 'Dr. B',
          notes: 'Notes B',
        ),
        Recipe(
          id: '3',
          patientId: 'patient-003',
          medication: 'Med C',
          issuedAt: DateTime(2024, 3, 10),
          doctor: 'Dr. C',
          notes: 'Notes C',
        ),
      ];
    });

    test('should filter recipes after start date', () {
      // Arrange
      final startDate = DateTime(2023, 10, 1);

      // Act
      final filtered = testRecipes.where((recipe) {
        return !recipe.issuedAt.isBefore(startDate);
      }).toList();

      // Assert
      expect(filtered.length, 2);
      expect(filtered.any((r) => r.id == '1'), false);
      expect(filtered.any((r) => r.id == '2'), true);
      expect(filtered.any((r) => r.id == '3'), true);
    });

    test('should filter recipes before end date', () {
      // Arrange
      final endDate = DateTime(2023, 12, 31, 23, 59, 59);

      // Act
      final filtered = testRecipes.where((recipe) {
        return !recipe.issuedAt.isAfter(endDate);
      }).toList();

      // Assert
      expect(filtered.length, 2);
      expect(filtered.any((r) => r.id == '1'), true);
      expect(filtered.any((r) => r.id == '2'), true);
      expect(filtered.any((r) => r.id == '3'), false);
    });

    test('should filter recipes within date range', () {
      // Arrange
      final startDate = DateTime(2023, 6, 1);
      final endDate = DateTime(2023, 12, 31, 23, 59, 59);

      // Act
      final filtered = testRecipes.where((recipe) {
        return !recipe.issuedAt.isBefore(startDate) &&
               !recipe.issuedAt.isAfter(endDate);
      }).toList();

      // Assert
      expect(filtered.length, 2);
      expect(filtered.any((r) => r.id == '1'), true);
      expect(filtered.any((r) => r.id == '2'), true);
      expect(filtered.any((r) => r.id == '3'), false);
    });

    test('should return all recipes when no date filter applied', () {
      // Act
      final filtered = testRecipes.where((recipe) => true).toList();

      // Assert
      expect(filtered.length, testRecipes.length);
    });
  });

  group('Medication Name Filtering', () {
    late List<Recipe> testRecipes;

    setUp(() {
      testRecipes = [
        Recipe(
          id: '1',
          patientId: 'patient-001',
          medication: 'Amoxicillin 500mg',
          issuedAt: DateTime(2023, 6, 1),
          doctor: 'Dr. A',
          notes: 'Notes',
        ),
        Recipe(
          id: '2',
          patientId: 'patient-002',
          medication: 'Ibuprofen 200mg',
          issuedAt: DateTime(2023, 7, 1),
          doctor: 'Dr. B',
          notes: 'Notes',
        ),
        Recipe(
          id: '3',
          patientId: 'patient-003',
          medication: 'Metformin 850mg',
          issuedAt: DateTime(2023, 8, 1),
          doctor: 'Dr. C',
          notes: 'Notes',
        ),
      ];
    });

    test('should filter recipes by medication name (case insensitive)', () {
      // Arrange
      const searchText = 'ibuprofen';

      // Act
      final filtered = testRecipes.where((recipe) {
        return recipe.medication.toLowerCase().contains(searchText.toLowerCase());
      }).toList();

      // Assert
      expect(filtered.length, 1);
      expect(filtered.first.medication, 'Ibuprofen 200mg');
    });

    test('should filter recipes by partial medication name', () {
      // Arrange
      const searchText = '500';

      // Act
      final filtered = testRecipes.where((recipe) {
        return recipe.medication.toLowerCase().contains(searchText.toLowerCase());
      }).toList();

      // Assert
      expect(filtered.length, 1);
      expect(filtered.first.medication, 'Amoxicillin 500mg');
    });

    test('should return empty list when no match found', () {
      // Arrange
      const searchText = 'NonExistentMedication';

      // Act
      final filtered = testRecipes.where((recipe) {
        return recipe.medication.toLowerCase().contains(searchText.toLowerCase());
      }).toList();

      // Assert
      expect(filtered, isEmpty);
    });

    test('should return all recipes when search is empty', () {
      // Arrange
      const searchText = '';

      // Act
      final filtered = testRecipes.where((recipe) {
        return searchText.isEmpty || 
               recipe.medication.toLowerCase().contains(searchText.toLowerCase());
      }).toList();

      // Assert
      expect(filtered.length, testRecipes.length);
    });
  });
}

