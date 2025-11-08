import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/recipe.dart';
import '../domain/recipe_filters.dart';
import '../../auth/application/auth_provider.dart';
import '../application/recipes_provider.dart';
import '../../../core/theme/theme_provider.dart';
import 'widgets/recipe_card.dart';
import 'widgets/recipe_filter_section.dart';

class RecipesListScreen extends ConsumerStatefulWidget {
  const RecipesListScreen({super.key});

  @override
  ConsumerState<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends ConsumerState<RecipesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  RecipeFilters _appliedFilters = const RecipeFilters();
  late final ScrollController _scrollController;

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (!position.hasPixels || !position.hasContentDimensions) return;

    final threshold = position.maxScrollExtent * 0.8;
    if (position.pixels >= threshold) {
      ref.read(recipesPaginationProvider.notifier).loadNextPage();
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recipesPaginationProvider.notifier).loadInitial(_appliedFilters);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  RecipeFilters _currentFilters() {
    final text = _searchController.text.trim();
    return RecipeFilters(
      medicationName: text.isEmpty ? null : text,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  bool _hasPendingChanges() {
    return _currentFilters() != _appliedFilters;
  }

  Future<void> _applyFilters() async {
    final filters = _currentFilters();
    setState(() {
      _appliedFilters = filters;
    });
    FocusScope.of(context).unfocus();
    _scrollController.jumpTo(0);
    await ref.read(recipesPaginationProvider.notifier).loadInitial(filters);
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _startDate = null;
      _endDate = null;
      _appliedFilters = const RecipeFilters();
    });
    ref.read(recipesPaginationProvider.notifier).loadInitial(_appliedFilters);
  }

  @override
  Widget build(BuildContext context) {
    final paginationState = ref.watch(recipesPaginationProvider);
    final themeNotifier = ref.watch(themeProvider.notifier);
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescriptions'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDarkMode ? 'Light Mode' : 'Dark Mode',
            onPressed: () {
              themeNotifier.toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: _buildBody(paginationState),
    );
  }

  Widget _buildBody(RecipesPaginationState state) {
    if (state.isLoading && state.recipes.isEmpty) {
      return _buildLoadingState();
    }

    if (state.hasError && state.recipes.isEmpty) {
      return _buildErrorState(state.errorMessage ?? 'Unknown error');
    }

    return _buildRecipesList(state);
  }

  Widget _buildRecipesList(RecipesPaginationState state) {
    final hasFilters = _appliedFilters.hasFilters;

    return Column(
      children: [
        RecipeFilterSection(
          searchController: _searchController,
          startDate: _startDate,
          endDate: _endDate,
          onClearFilters: _clearFilters,
          onSelectStartDate: _selectStartDate,
          onSelectEndDate: _selectEndDate,
          onSearchChanged: () => setState(() {}),
          onApplyFilters: _applyFilters,
          isApplyEnabled: _hasPendingChanges(),
        ),
        if (state.hasError && state.recipes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.errorMessage ?? 'Error loading more prescriptions',
                    style: TextStyle(color: Colors.red[400]),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(recipesPaginationProvider.notifier).loadNextPage();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(recipesPaginationProvider.notifier).refresh();
            },
            child: state.recipes.isEmpty
                ? _buildEmptyState(hasFilters)
                : _buildRecipesListView(
                    state.recipes,
                    state.isLoadingMore,
                    state.hasMore,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool filtered) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height - 300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medication,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  filtered ? 'No prescriptions match the filters' : 'No prescriptions yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pull down to refresh',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipesListView(
      List<Recipe> recipes, bool isLoadingMore, bool hasMore) {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length + (isLoadingMore || hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= recipes.length) {
          if (!hasMore) {
            return const SizedBox.shrink();
          }
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return RecipeCard(recipe: recipes[index]);
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading recipes...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading recipes',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await ref.read(recipesPaginationProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

