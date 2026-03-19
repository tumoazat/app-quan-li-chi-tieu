import '../domain/usecases/auto_categorize_usecase.dart';
import 'keyword_repository.dart';

/// Keyword-based auto categorization service.
/// Designed to be replaced with an ML model in the future.
class AutoCategoryService {
  final Map<String, String> _keywords;

  AutoCategoryService({Map<String, String>? keywords})
      : _keywords = keywords ?? keywordMap;

  /// Returns the best-matching [CategorySuggestion] for [input],
  /// or falls back to `expense_others` if no keyword matches.
  CategorySuggestion categorize(String input) {
    final lower = input.toLowerCase().trim();
    if (lower.isEmpty) {
      return const CategorySuggestion(
        categoryId: 'expense_others',
        confidence: 0,
        matchedKeyword: '',
      );
    }

    String bestKeyword = '';
    String bestCategory = 'expense_others';
    double bestScore = 0;

    for (final entry in _keywords.entries) {
      final keyword = entry.key;
      if (lower.contains(keyword)) {
        // Longer keyword → more specific → higher score
        final score = keyword.length.toDouble();
        if (score > bestScore) {
          bestScore = score;
          bestKeyword = keyword;
          bestCategory = entry.value;
        }
      }
    }

    final confidence = bestScore > 0 ? 0.8 : 0.0;

    return CategorySuggestion(
      categoryId: bestCategory,
      confidence: confidence,
      matchedKeyword: bestKeyword,
    );
  }
}
