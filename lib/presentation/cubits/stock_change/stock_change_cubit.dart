import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/stock_change_model.dart';
import '../../../data/repositories/stock_change_repository.dart';

part 'stock_change_state.dart';

class StockChangeCubit extends Cubit<StockChangeState> {
  final StockChangeRepository _repository;
  StockChangeCubit(this._repository) : super(const StockChangeInitial());

  Future<void> loadByProduct(int productId) async {
    emit(const StockChangeLoading());
    try {
      final changes = await _repository.getByProduct(productId);
      emit(StockChangeLoaded(changes));
    } catch (e) {
      emit(StockChangeError(e.toString()));
    }
  }

  Future<void> loadByWarehouse(int warehouseId) async {
    emit(const StockChangeLoading());
    try {
      final changes = await _repository.getByWarehouse(warehouseId);
      emit(StockChangeLoaded(changes));
    } catch (e) {
      emit(StockChangeError(e.toString()));
    }
  }

  Future<void> loadByUser(int userId) async {
    emit(const StockChangeLoading());
    try {
      final changes = await _repository.getByUser(userId);
      emit(StockChangeLoaded(changes));
    } catch (e) {
      emit(StockChangeError(e.toString()));
    }
  }
}
