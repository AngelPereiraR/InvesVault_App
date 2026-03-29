import 'package:equatable/equatable.dart';
import '../../../core/utils/error_messages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/category_model.dart';
import '../../../data/repositories/category_repository.dart';

part 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepository _repository;

  CategoryCubit(this._repository) : super(const CategoryInitial());

  Future<void> load() async {
    emit(const CategoryLoading());
    try {
      final categories = await _repository.getCategories();
      emit(CategoryLoaded(categories));
    } catch (e) {
      emit(CategoryError(friendlyError(e)));
    }
  }

  Future<void> create(String name) async {
    try {
      await _repository.createCategory(name);
      await load();
    } catch (e) {
      emit(CategoryError(friendlyError(e)));
    }
  }

  Future<void> update(int id, String name) async {
    try {
      await _repository.updateCategory(id, name);
      await load();
    } catch (e) {
      emit(CategoryError(friendlyError(e)));
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repository.deleteCategory(id);
      await load();
    } catch (e) {
      emit(CategoryError(friendlyError(e)));
    }
  }

  Future<void> deleteItems(List<int> ids) async {
    emit(const CategoryDeleting());
    try {
      for (final id in ids) {
        await _repository.deleteCategory(id);
      }
    } catch (e) {
      emit(CategoryError(friendlyError(e)));
      return;
    }
    await load();
  }
}
