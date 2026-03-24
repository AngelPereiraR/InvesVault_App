import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final int id;
  final int userId;
  final int productId;
  final int warehouseId;
  final String message;
  final bool isRead;
  final String? createdAt;
  final String? productName;
  final String? warehouseName;
  final String type;
  final int? batchId;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.warehouseId,
    required this.message,
    required this.isRead,
    this.createdAt,
    this.productName,
    this.warehouseName,
    this.type = 'low_stock',
    this.batchId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final warehouse = json['warehouse'] as Map<String, dynamic>?;
    return NotificationModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      productId: json['product_id'] as int,
      warehouseId: json['warehouse_id'] as int,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      productName: product?['name'] as String?,
      warehouseName: warehouse?['name'] as String?,
      type: json['type'] as String? ?? 'low_stock',
      batchId: json['batch_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'product_id': productId,
        'warehouse_id': warehouseId,
        'message': message,
        'is_read': isRead,
        'type': type,
        'batch_id': batchId,
      };

  NotificationModel copyWith({bool? isRead, String? type, int? batchId}) => NotificationModel(
        id: id,
        userId: userId,
        productId: productId,
        warehouseId: warehouseId,
        message: message,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        productName: productName,
        warehouseName: warehouseName,
        type: type ?? this.type,
        batchId: batchId ?? this.batchId,
      );

  @override
  List<Object?> get props => [id, userId, productId, warehouseId, isRead, type, batchId];
}
