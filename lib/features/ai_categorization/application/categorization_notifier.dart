import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auto_category_service.dart';
import '../domain/usecases/auto_categorize_usecase.dart';

final autoCategoryServiceProvider = Provider<AutoCategoryService>((ref) {
  return AutoCategoryService();
});

/// Holds the current [CategorySuggestion] for the note being typed.
final categorizationNotifierProvider =
    StateNotifierProvider.autoDispose<CategorizationNotifier, CategorySuggestion?>(
  (ref) => CategorizationNotifier(ref.read(autoCategoryServiceProvider)),
);

class CategorizationNotifier extends StateNotifier<CategorySuggestion?> {
  final AutoCategoryService _service;

  CategorizationNotifier(this._service) : super(null);

  void analyze(String text) {
    if (text.trim().isEmpty) {
      state = null;
      return;
    }
    final suggestion = _service.categorize(text);
    // Only surface if there's a real match (confidence > 0)
    state = suggestion.confidence > 0 ? suggestion : null;
  }

  void dismiss() => state = null;
}
