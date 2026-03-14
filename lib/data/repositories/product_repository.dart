import '../datasources/product_remote_datasource.dart';
import '../models/product_model.dart';
import '../../core/models/filter_params.dart';

class ProductRepository {
  final ProductRemoteDatasource _datasource;
  ProductRepository(this._datasource);

  Future<List<ProductModel>> getProducts([FilterParams params = FilterParams.empty]) =>
      _datasource.getProducts(params);

  Future<ProductModel> getProductById(int id) =>
      _datasource.getProductById(id);

  Future<ProductModel> createProduct(Map<String, dynamic> data) =>
      _datasource.createProduct(data);

  Future<ProductModel> updateProduct(int id, Map<String, dynamic> data) =>
      _datasource.updateProduct(id, data);

  Future<void> deleteProduct(int id) => _datasource.deleteProduct(id);
}
