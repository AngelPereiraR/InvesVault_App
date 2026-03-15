import 'warehouse_model.dart';

/// Almacén con su conteo de productos garantizado (no nulo) — usado en el Dashboard.
class WarehouseSummary {
  final WarehouseModel warehouse;

  const WarehouseSummary({required this.warehouse});

  int get productCount => warehouse.productCount ?? 0;

  factory WarehouseSummary.fromJson(Map<String, dynamic> json) =>
      WarehouseSummary(warehouse: WarehouseModel.fromJson(json));
}
