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

  const ShoppingListItemModel({
    required this.id,
    required this.warehouseId,
    required this.productId,
    required this.suggestedQty,
    required this.isAuto,
    this.createdAt,
    this.product,
  });

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
  List<Object?> get props => [id, warehouseId, productId, suggestedQty, isAuto];
}
