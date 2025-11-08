import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../domain/recipe.dart';
import '../domain/recipe_filters.dart';
import '../../auth/application/auth_provider.dart';

const String _defaultBaseUrl = 'http://localhost:3000';

/// Compile-time override:
/// `--dart-define=API_BASE_URL=https://your-api.com`
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: _defaultBaseUrl,
);

/// Compile-time override:
/// `--dart-define=USE_MOCK_DATA=true`
const bool useMockData = bool.fromEnvironment(
  'USE_MOCK_DATA',
  defaultValue: false,
);

class RecipeApiService {
  RecipeApiService(this._ref);
  
  final Ref _ref;
  
  // Update this base URL to your actual API endpoint
  static const String baseUrl = apiBaseUrl;
  
  /// Gets a valid (potentially refreshed) authentication token
  Future<String?> _getAuthToken() async {
    try {
      final authNotifier = _ref.read(authProvider.notifier);
      final token = await authNotifier.getValidToken();
      
      return token;
    } catch (e) {
      return null;
    }
  }
  
  Future<PaginatedRecipesResponse> fetchRecipesPage({
    required RecipeFilters filters,
    required int page,
    int limit = 10,
  }) async {
    final queryParams = {
      ...filters.toQueryParameters(),
      'page': page.toString(),
      'limit': limit.toString(),
    };

    try {
      if (useMockData) {
        final response = await _fetchMockPaginated(queryParams);
        return response;
      }

      final response = await _fetchFromApi(queryParams);
      return response;
    } catch (e) {
      throw Exception('Failed to fetch recipes: $e');
    }
  }
  
  /// Loads recipes from the mock JSON file and applies pagination/filtering
  Future<PaginatedRecipesResponse> _fetchMockPaginated(
      Map<String, String> queryParams) async {
    try {
      final String jsonString = await rootBundle.loadString('assets/mock_recipes.json');
      final List<dynamic> data = json.decode(jsonString);
      var recipes = data.map((json) => _recipeFromJson(json)).toList();

      // Apply filters
      recipes = _filterRecipes(recipes, queryParams);

      final total = recipes.length;
      final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
      final limit = int.tryParse(queryParams['limit'] ?? '10') ?? 10;
      final totalPages = (total / limit).ceil().clamp(1, double.infinity).toInt();

      final startIndex = (page - 1) * limit;
      var endIndex = startIndex + limit;
      if (startIndex >= recipes.length) {
        return PaginatedRecipesResponse(
          data: const [],
          total: total,
          page: page,
          limit: limit,
          totalPages: totalPages,
        );
      }
      endIndex = endIndex.clamp(0, recipes.length);
      final pagedData = recipes.sublist(startIndex, endIndex);

      return PaginatedRecipesResponse(
        data: pagedData,
        total: total,
        page: page,
        limit: limit,
        totalPages: totalPages,
      );
    } catch (e) {
      throw Exception('Failed to load mock recipes: $e');
    }
  }
  
  /// Fetches recipes from the real API
  Future<PaginatedRecipesResponse> _fetchFromApi(
      Map<String, String> queryParams) async {
    final uri = Uri.parse('$baseUrl/recipes').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    
    // Get authentication token
    final token = await _getAuthToken();
    
    // Build headers with token if available
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    final response = await http.get(
      uri,
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonBody = json.decode(response.body);
      final List<dynamic> data = jsonBody['data'] as List<dynamic>? ?? [];

      final recipes = data.map((item) => _recipeFromJson(item)).toList();

      final total = jsonBody['total'] as int? ?? recipes.length;
      final page = jsonBody['page'] as int? ?? 1;
      final limit = jsonBody['limit'] as int? ?? recipes.length;
      final totalPages = jsonBody['totalPages'] as int? ?? 1;

      return PaginatedRecipesResponse(
        data: recipes,
        total: total,
        page: page,
        limit: limit,
        totalPages: totalPages,
      );
    } else if (response.statusCode == 401) {
      // Token expired or invalid - try refreshing token and retry once
      final newToken = await _getAuthToken();
      if (newToken != null && newToken != token) {
        
        final retryHeaders = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $newToken',
        };
        
        final retryResponse = await http.get(uri, headers: retryHeaders);
        
        if (retryResponse.statusCode == 200) {
          final Map<String, dynamic> jsonBody = json.decode(retryResponse.body);
          final List<dynamic> data = jsonBody['data'] as List<dynamic>? ?? [];
          final recipes = data.map((item) => _recipeFromJson(item)).toList();

          return PaginatedRecipesResponse(
            data: recipes,
            total: jsonBody['total'] as int? ?? recipes.length,
            page: jsonBody['page'] as int? ?? 1,
            limit: jsonBody['limit'] as int? ?? recipes.length,
            totalPages: jsonBody['totalPages'] as int? ?? 1,
          );
        } else {
          throw Exception('Unauthorized: ${retryResponse.statusCode}');
        }
      } else {
        throw Exception('Unauthorized: Token expired');
      }
    } else {
      throw Exception('Failed to load recipes: ${response.statusCode}');
    }
  }
  
  /// Filters recipes based on query parameters
  List<Recipe> _filterRecipes(List<Recipe> recipes, Map<String, String> queryParams) {
    return recipes.where((recipe) {
      for (var entry in queryParams.entries) {
        final key = entry.key.toLowerCase();
        final value = entry.value.toLowerCase();
        
        switch (key) {
          case 'patientid':
            if (!recipe.patientId.toLowerCase().contains(value)) return false;
            break;
          case 'medication':
            if (!recipe.medication.toLowerCase().contains(value)) return false;
            break;
          case 'medicationname':
            if (!recipe.medication.toLowerCase().contains(value)) return false;
            break;
          case 'doctor':
            if (!recipe.doctor.toLowerCase().contains(value)) return false;
            break;
          case 'notes':
            if (!recipe.notes.toLowerCase().contains(value)) return false;
            break;
          case 'startdate':
            final start = DateTime.tryParse(entry.value);
            if (start != null && recipe.issuedAt.isBefore(start)) return false;
            break;
          case 'enddate':
            final end = DateTime.tryParse(entry.value);
            if (end != null) {
              final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
              if (recipe.issuedAt.isAfter(endOfDay)) return false;
            }
            break;
        }
      }
      return true;
    }).toList();
  }
  
  /// Converts JSON to Recipe object
  Recipe _recipeFromJson(Map<String, dynamic> json) {
    try {
      return Recipe(
        id: json['id'] as String,
        patientId: json['patientId'] as String,
        medication: json['medication'] as String,
        issuedAt: DateTime.parse(json['issuedAt'] as String),
        doctor: json['doctor'] as String,
        notes: json['notes'] as String,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Converts Recipe object to JSON
  Map<String, dynamic> _recipeToJson(Recipe recipe) {
    return {
      'id': recipe.id,
      'patientId': recipe.patientId,
      'medication': recipe.medication,
      'issuedAt': recipe.issuedAt.toIso8601String(),
      'doctor': recipe.doctor,
      'notes': recipe.notes,
    };
  }
}

class PaginatedRecipesResponse {
  final List<Recipe> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PaginatedRecipesResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;
}

