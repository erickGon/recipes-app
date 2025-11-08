import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/recipe.dart';
import '../domain/recipe_filters.dart';
import '../data/recipe_api_service.dart';

class RecipesPaginationState {
  final List<Recipe> recipes;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasError;
  final String? errorMessage;
  final bool hasMore;
  final int currentPage;
  final RecipeFilters filters;

  const RecipesPaginationState({
    this.recipes = const [],
    this.isLoading = false, // isLoading is true when the app is loading the recipes
    this.isLoadingMore = false, // isLoadingMore is true when the app is loading the next page of recipes
    this.hasError = false, // hasError is true when there is an error loading the recipes
    this.errorMessage, // errorMessage is the error message that is displayed to the user
    this.hasMore = true, // hasMore is true when there are more recipes to load
    this.currentPage = 0, // currentPage is the current page of recipes that are loaded
    this.filters = const RecipeFilters(), // filters are the filters that are applied to the recipes
  });

  RecipesPaginationState copyWith({
    List<Recipe>? recipes,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasError,
    String? errorMessage,
    bool? hasMore,
    int? currentPage,
    RecipeFilters? filters,
  }) {
    return RecipesPaginationState( // copyWith is a method that returns a new instance of the RecipesPaginationState with the new values
      recipes: recipes ?? this.recipes,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      filters: filters ?? this.filters,
    );
  }
}

// Provider for the API service
final recipeApiServiceProvider = Provider<RecipeApiService>((ref) {
  return RecipeApiService(ref); // RecipeApiService is the API service that is used to fetch the recipes
});

class RecipesPaginationNotifier extends StateNotifier<RecipesPaginationState> {
  RecipesPaginationNotifier(this._apiService)
      : super(const RecipesPaginationState());

  final RecipeApiService _apiService;
  static const int _pageSize = 10;
  bool _initialLoadDone = false;

  Future<void> loadInitial(RecipeFilters filters) async {
    state = state.copyWith(
      isLoading: true,
      hasError: false,
      errorMessage: null,
      recipes: const [],
      currentPage: 0,
      hasMore: true,
      filters: filters,
    );
    _initialLoadDone = false;

    try {
      final response = await _apiService.fetchRecipesPage(
        filters: filters,
        page: 1,
        limit: _pageSize,
      );

      state = state.copyWith(
        recipes: response.data,
        isLoading: false,
        hasError: false,
        errorMessage: null,
        hasMore: response.hasMore,
        currentPage: response.page,
        filters: filters,
      );
      _initialLoadDone = true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: e.toString(),
      );
      _initialLoadDone = false;
    }
  }

  Future<void> refresh() async {
    await loadInitial(state.filters);
  }

  Future<void> loadNextPage() async {
    if (!_initialLoadDone) {
      return;
    }
    if (state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, hasError: false); 

    try {
      final nextPage = state.currentPage + 1;
      final response = await _apiService.fetchRecipesPage(
        filters: state.filters,
        page: nextPage,
        limit: _pageSize,
      );

      final updatedRecipes = [...state.recipes, ...response.data];

      state = state.copyWith(
        recipes: updatedRecipes,
        isLoadingMore: false,
        hasMore: response.hasMore,
        currentPage: response.page,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        hasError: true,
        errorMessage: e.toString(),
      );
    }
  }
}

final recipesPaginationProvider =
    StateNotifierProvider<RecipesPaginationNotifier, RecipesPaginationState>((ref) {
  final apiService = ref.read(recipeApiServiceProvider);
  return RecipesPaginationNotifier(apiService);
});


