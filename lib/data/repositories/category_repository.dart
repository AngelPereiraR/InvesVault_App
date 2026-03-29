import '../datasources/category_remote_datasource.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final CategoryRemoteDatasource _datasource;
  CategoryRepository(this._datasource);

  Future<List<CategoryModel>> getCategories() => _datasource.getCategories();

  Future<CategoryModel> createCategory(String name) =>
      _datasource.createCategory(name);

  Future<CategoryModel> updateCategory(int id, String name) =>
      _datasource.updateCategory(id, name);

  Future<void> deleteCategory(int id) => _datasource.deleteCategory(id);
}
