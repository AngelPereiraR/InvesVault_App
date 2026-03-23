import 'package:equatable/equatable.dart';
import 'product_model.dart';
import 'store_model.dart';

class WarehouseProductModel extends Equatable {
  final int id;
  final int warehouseId;
  final int productId;
  final double quantity;
  final double? minQuantity;
  final double? pricePerUnit;
  final int? storeId;
  final String? lastUpdated;
  final ProductModel? product;
  final StoreModel? store;
  final String? warehouseName;

  const WarehouseProductModel({
    required this.id,
    required this.warehouseId,
    required this.productId,
    required this.quantity,
    this.minQuantity,
    this.pricePerUnit,
    this.storeId,
    this.lastUpdated,
    this.product,
    this.store,
    this.warehouseName,
  });

  bool get isLowStock =>
      minQuantity != null && quantity < minQuantity!;

  factory WarehouseProductModel.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'] as Map<String, dynamic>?;
    final storeJson = json['last_store'] as Map<String, dynamic>?;
    return WarehouseProductModel(
      id: json['id'] as int,
      warehouseId: json['warehouse_id'] as int,
      productId: json['product_id'] as int,
      quantity: double.tryParse(json['quantity'].toString()) ?? 0,
      minQuantity: json['min_quantity'] != null
          ? double.tryParse(json['min_quantity'].toString())
          : null,
      pricePerUnit: json['price_per_unit'] != null
          ? double.tryParse(json['price_per_unit'].toString())
          : null,
      storeId: json['store_id'] as int?,
      lastUpdated: json['last_updated'] as String?,
      product: productJson != null ? ProductModel.fromJson(productJson) : null,
      store: storeJson != null ? StoreModel.fromJson(storeJson) : null,
      warehouseName: (json['warehouse'] as Map<String, dynamic>?)?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'warehouse_id': warehouseId,
        'product_id': productId,
        'quantity': quantity,
        'min_quantity': minQuantity,
        'price_per_unit': pricePerUnit,
        'store_id': storeId,
      };

  WarehouseProductModel copyWith({double? quantity, double? minQuantity, String? warehouseName}) =>
      WarehouseProductModel(
        id: id,
        warehouseId: warehouseId,
        productId: productId,
        quantity: quantity ?? this.quantity,
        minQuantity: minQuantity ?? this.minQuantity,
        pricePerUnit: pricePerUnit,
        storeId: storeId,
        lastUpdated: lastUpdated,
        product: product,
        store: store,
        warehouseName: warehouseName ?? this.warehouseName,
      );

  @override
  List<Object?> get props => [id, warehouseId, productId, quantity, minQuantity, warehouseName];
}
