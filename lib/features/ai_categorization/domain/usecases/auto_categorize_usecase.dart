/// Result of automatic category suggestion.
class CategorySuggestion {
  final String categoryId;
  final double confidence;
  final String matchedKeyword;

  const CategorySuggestion({
    required this.categoryId,
    required this.confidence,
    required this.matchedKeyword,
  });
}
