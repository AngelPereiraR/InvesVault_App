import 'package:equatable/equatable.dart';
import 'product_model.dart';

class ShoppingListItemModel extends Equatable {
  final int id;
  final int warehouseId;
  final int productId;
  final double suggestedQty;
  final bool isAuto;
  final String? createdAt;
  final ProductModel? product;
  // Live warehouse stock data for alert-gap computation
  final double? wpMinQuantity;
  final double? wpCurrentQty;
  // Store this product is normally bought at
  final int? storeId;
  final String? storeName;
  // Warehouse name (populated in cross-warehouse queries)
  final String? warehouseName;

  const ShoppingListItemModel({
    required this.id,
    required this.warehouseId,
    required this.productId,
    required this.suggestedQty,
    required this.isAuto,
    this.createdAt,
    this.product,
    this.wpMinQuantity,
    this.wpCurrentQty,
    this.storeId,
    this.storeName,
    this.warehouseName,
  });

  /// How many units are needed to cover the minimum-stock alert.
  /// Returns 0 when stock already meets or exceeds the minimum.
  double get alertGap {
    if (wpMinQuantity == null || wpCurrentQty == null) return 0;
    final gap = wpMinQuantity! - wpCurrentQty!;
    return gap > 0 ? gap : 0;
  }

  factory ShoppingListItemModel.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'] as Map<String, dynamic>?;
    return ShoppingListItemModel(
      id: json['id'] as int,
      warehouseId: json['warehouse_id'] as int,
      productId: json['product_id'] as int,
      suggestedQty:
          double.tryParse(json['suggested_qty'].toString()) ?? 0,
      isAuto: json['is_auto'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
      product: productJson != null ? ProductModel.fromJson(productJson) : null,
      wpMinQuantity: json['wp_min_quantity'] != null
          ? double.tryParse(json['wp_min_quantity'].toString())
          : null,
      wpCurrentQty: json['wp_current_qty'] != null
          ? double.tryParse(json['wp_current_qty'].toString())
          : null,
      storeId: json['wp_store_id'] != null
          ? int.tryParse(json['wp_store_id'].toString())
          : null,
      storeName: json['wp_store_name'] as String?,
      warehouseName: json['warehouse_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'warehouse_id': warehouseId,
        'product_id': productId,
        'suggested_qty': suggestedQty,
        'is_auto': isAuto,
      };

  @override
  List<Object?> get props => [id, warehouseId, productId, suggestedQty, isAuto, wpMinQuantity, wpCurrentQty, storeId, storeName, warehouseName];
}
