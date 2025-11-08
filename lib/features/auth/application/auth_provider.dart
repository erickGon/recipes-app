import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../domain/user.dart';

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(null) {
    _init();
  }

  final _auth = fb.FirebaseAuth.instance;
  
  // Configure secure storage with proper iOS options
  FlutterSecureStorage get _secureStorage => const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      accountName: 'recepies_app_auth',
    ),
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const _tokenKey = 'firebase_id_token';

  /// Gets the current user's ID token, refreshing if necessary
  Future<String?> getValidToken() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('No current user, cannot get token');
        return null;
      }

      // Force refresh to get a fresh token (Firebase handles caching internally)
      final token = await currentUser.getIdToken(true);
      
      if (token != null) {
        debugPrint('Token refreshed successfully');
        await _safeWriteToken(token);
      }
      
      return token;
    } catch (e) {
      debugPrint('Error getting valid token: $e');
      return null;
    }
  }

  /// Safely writes token to secure storage, handling iOS keychain duplicate errors
  Future<void> _safeWriteToken(String token) async {
    try {
      // First, try to read existing token
      final existingToken = await _secureStorage.read(key: _tokenKey);
      
      if (existingToken != null) {
        // Delete existing token
        await _secureStorage.delete(key: _tokenKey);
        // Wait for keychain to process the deletion
        await Future.delayed(const Duration(milliseconds: 150));
      }
      
      // Now write the new token
      await _secureStorage.write(key: _tokenKey, value: token);
    } catch (e) {
      debugPrint('Error in _safeWriteToken: $e');
      // If all else fails, just try to write anyway
      try {
        await _secureStorage.write(key: _tokenKey, value: token);
      } catch (finalError) {
        debugPrint('Final write attempt failed: $finalError');
      }
    }
  }

  Future<void> _init() async {
    // Keep Riverpod state in sync with Firebase Auth
    _auth.authStateChanges().listen((fbUser) async {
      
      if (fbUser == null) {
        state = null;
        try {
          await _secureStorage.delete(key: _tokenKey);
        } catch (e) {
          debugPrint('Error deleting token: $e');
        }
      } else {
        // Only update state, don't store token here
        // Token storage is handled by login() to avoid race conditions
        state = User(
          id: fbUser.uid,
          email: fbUser.email ?? '',
        );
        
      }
      
    });
  }

  Future<bool> login(String email, String password) async {
    
    try {
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final fbUser = credential.user;
      if (fbUser == null) {
        debugPrint('ERROR: Firebase user is null after login');
        return false;
      }
      
      try {
        final token = await fbUser.getIdToken();
        if (token != null) {
          await _safeWriteToken(token);
        }
      } catch (e) {
        debugPrint('Error storing token: $e');
        // Continue even if token storage fails
      }
      
      state = User(
        id: fbUser.uid,
        email: fbUser.email ?? email,
      );
      
      return true;
      
    } on fb.FirebaseAuthException catch (e) {
      
      return false;
    } catch (e) {
      debugPrint('Unexpected error during login: $e');
      return false;
    }
  }

  Future<void> logout() async {
    
    try {
      await _auth.signOut();
      await _secureStorage.delete(key: _tokenKey);
    } catch (e) {
      debugPrint('Error during logout: $e');
    } finally {
      state = null;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});


