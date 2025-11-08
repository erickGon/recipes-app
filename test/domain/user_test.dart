import 'package:flutter_test/flutter_test.dart';
import 'package:recepies_app/features/auth/domain/user.dart';

void main() {
  group('User Model', () {
    test('should create a User with all required fields', () {
      // Act
      final user = User(
        id: 'user-123',
        email: 'test@example.com',
      );

      // Assert
      expect(user.id, 'user-123');
      expect(user.email, 'test@example.com');
    });

    test('should handle email variations correctly', () {
      // Arrange & Act
      final user1 = User(
        id: '1',
        email: 'user@domain.com',
      );
      final user2 = User(
        id: '2',
        email: 'another.user@example.co.uk',
      );

      // Assert
      expect(user1.email, 'user@domain.com');
      expect(user2.email, 'another.user@example.co.uk');
    });

    test('should extract name from email', () {
      // Arrange
      final user = User(
        id: '1',
        email: 'testuser@example.com',
      );
      
      // Act
      final name = user.email.split('@').first;
      
      // Assert
      expect(name, 'testuser');
    });
  });
}

