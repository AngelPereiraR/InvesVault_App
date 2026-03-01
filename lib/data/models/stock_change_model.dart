import 'package:equatable/equatable.dart';

class StockChangeModel extends Equatable {
  final int id;
  final int productId;
  final int warehouseId;
  final int changeQuantity;
  final String changeType; // inbound | outbound | adjustment
  final String? reason;
  final int? userId;
  final String? createdAt;
  final String? productName;
  final String? warehouseName;
  final String? userName;

  const StockChangeModel({
    required this.id,
    required this.productId,
    required this.warehouseId,
    required this.changeQuantity,
    required this.changeType,
    this.reason,
    this.userId,
    this.createdAt,
    this.productName,
    this.warehouseName,
    this.userName,
  });

  factory StockChangeModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final warehouse = json['warehouse'] as Map<String, dynamic>?;
    final user = json['user'] as Map<String, dynamic>?;
    return StockChangeModel(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      warehouseId: json['warehouse_id'] as int,
      changeQuantity: json['change_quantity'] as int,
      changeType: json['change_type'] as String,
      reason: json['reason'] as String?,
      userId: json['user_id'] as int?,
      createdAt: json['created_at'] as String?,
      productName: product?['name'] as String?,
      warehouseName: warehouse?['name'] as String?,
      userName: user?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'warehouse_id': warehouseId,
        'change_quantity': changeQuantity,
        'change_type': changeType,
        'reason': reason,
        'user_id': userId,
      };

  @override
  List<Object?> get props =>
      [id, productId, warehouseId, changeQuantity, changeType, createdAt, userName];
}
