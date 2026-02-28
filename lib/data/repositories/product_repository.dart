import '../datasources/product_remote_datasource.dart';
import '../models/product_model.dart';

class ProductRepository {
  final ProductRemoteDatasource _datasource;
  ProductRepository(this._datasource);

  Future<List<ProductModel>> getProducts() => _datasource.getProducts();

  Future<ProductModel> getProductById(int id) =>
      _datasource.getProductById(id);

  Future<ProductModel> createProduct(Map<String, dynamic> data) =>
      _datasource.createProduct(data);

  Future<ProductModel> updateProduct(int id, Map<String, dynamic> data) =>
      _datasource.updateProduct(id, data);

  Future<void> deleteProduct(int id) => _datasource.deleteProduct(id);
}
