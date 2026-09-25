import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../services/service_api.dart';

class CategoryState {
  final List<CategoryModel> categories;
  final bool isLoading;

  CategoryState({this.categories = const [], this.isLoading = false});
}

class CategoryNotifier extends Notifier<CategoryState> {
  @override
  CategoryState build() {
    Future.microtask(load);
    return CategoryState(isLoading: true);
  }

  Future<void> load() async {
    state = CategoryState(isLoading: true, categories: state.categories);
    try {
      final list = await ServiceApi().getCategories();
      state = CategoryState(isLoading: false, categories: list);
    } catch (e) {
      state = CategoryState(isLoading: false, categories: state.categories);
    }
  }
}

final categoryProvider = NotifierProvider<CategoryNotifier, CategoryState>(CategoryNotifier.new);
