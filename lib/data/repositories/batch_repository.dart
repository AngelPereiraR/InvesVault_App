import '../datasources/batch_remote_datasource.dart';
import '../models/batch_model.dart';

class BatchRepository {
  final BatchRemoteDatasource _datasource;
  BatchRepository(this._datasource);

  Future<List<BatchModel>> getBatches(int warehouseProductId) =>
      _datasource.getBatches(warehouseProductId);

  Future<BatchModel> createBatch(
          int warehouseProductId, Map<String, dynamic> data) =>
      _datasource.createBatch(warehouseProductId, data);

  Future<BatchModel> updateBatch(int id, Map<String, dynamic> data) =>
      _datasource.updateBatch(id, data);

  Future<void> deleteBatch(int id) => _datasource.deleteBatch(id);
}
