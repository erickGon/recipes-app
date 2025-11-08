import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Email Validation', () {
    String? validateEmail(String? value) {
      if (value == null || value.isEmpty) {
        return 'Please enter your email';
      }
      
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      
      if (!emailRegex.hasMatch(value.trim())) {
        return 'Please enter a valid email.';
      }
      
      return null;
    }

    test('should return error when email is empty', () {
      expect(validateEmail(''), 'Please enter your email');
      expect(validateEmail(null), 'Please enter your email');
    });

    test('should return error for invalid email formats', () {
      expect(validateEmail('invalid'), 'Please enter a valid email.');
      expect(validateEmail('invalid@'), 'Please enter a valid email.');
      expect(validateEmail('invalid@domain'), 'Please enter a valid email.');
      expect(validateEmail('@domain.com'), 'Please enter a valid email.');
      expect(validateEmail('user@.com'), 'Please enter a valid email.');
    });

    test('should return null for valid email formats', () {
      expect(validateEmail('user@example.com'), null);
      expect(validateEmail('test.user@example.co.uk'), null);
      expect(validateEmail('user+tag@domain.com'), null);
      expect(validateEmail('123@domain.com'), null);
    });

    test('should handle emails with whitespace', () {
      expect(validateEmail(' user@example.com '), null);
      expect(validateEmail('user@example.com '), null);
    });
  });

  group('Password Validation', () {
    String? validatePassword(String? value) {
      if (value == null || value.isEmpty) {
        return 'Please enter your password';
      }
      
      if (value.length < 6) {
        return 'Password must be at least 6 characters';
      }
      
      if (!value.contains(RegExp(r'[A-Z]'))) {
        return 'Password must contain at least one uppercase letter';
      }
      
      if (!value.contains(RegExp(r'[a-z]'))) {
        return 'Password must contain at least one lowercase letter';
      }
      
      if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
        return 'Password must contain at least one special character';
      }
      
      return null;
    }

    test('should return error when password is empty', () {
      expect(validatePassword(''), 'Please enter your password');
      expect(validatePassword(null), 'Please enter your password');
    });

    test('should return error when password is too short', () {
      expect(validatePassword('Te1!'), 'Password must be at least 6 characters');
      expect(validatePassword('Aa1!'), 'Password must be at least 6 characters');
    });

    test('should return error when password has no uppercase letter', () {
      expect(
        validatePassword('test123!'),
        'Password must contain at least one uppercase letter',
      );
    });

    test('should return error when password has no lowercase letter', () {
      expect(
        validatePassword('TEST123!'),
        'Password must contain at least one lowercase letter',
      );
    });

    test('should return error when password has no special character', () {
      expect(
        validatePassword('Test1234'),
        'Password must contain at least one special character',
      );
    });

    test('should return null for valid passwords', () {
      expect(validatePassword('Test123!'), null);
      expect(validatePassword('MyP@ssw0rd'), null);
      expect(validatePassword('Secure#Pass1'), null);
      expect(validatePassword('Valid&Pass123'), null);
    });

    test('should handle passwords with multiple special characters', () {
      expect(validatePassword(r'Test@#$123'), null);
      expect(validatePassword('P@ssw0rd!'), null);
    });
  });
}

