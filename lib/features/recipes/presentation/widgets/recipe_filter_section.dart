import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecipeFilterSection extends StatelessWidget {
  final TextEditingController searchController;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onClearFilters;
  final Function(BuildContext) onSelectStartDate;
  final Function(BuildContext) onSelectEndDate;
  final VoidCallback onSearchChanged;
  final VoidCallback onApplyFilters;
  final bool isApplyEnabled;

  const RecipeFilterSection({
    super.key,
    required this.searchController,
    required this.startDate,
    required this.endDate,
    required this.onClearFilters,
    required this.onSelectStartDate,
    required this.onSelectEndDate,
    required this.onSearchChanged,
    required this.onApplyFilters,
    required this.isApplyEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = searchController.text.isNotEmpty || 
                             startDate != null || 
                             endDate != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: 'Search by medication name',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => onSearchChanged(),
          ),
          const SizedBox(height: 12),
          // Date filters
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onSelectStartDate(context),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    startDate != null
                        ? DateFormat('MMM d, yyyy').format(startDate!)
                        : 'Start Date',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onSelectEndDate(context),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    endDate != null
                        ? DateFormat('MMM d, yyyy').format(endDate!)
                        : 'End Date',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear Filters'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isApplyEnabled ? onApplyFilters : null,
                  icon: const Icon(Icons.filter_alt, size: 18),
                  label: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

