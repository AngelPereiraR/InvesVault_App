import 'package:equatable/equatable.dart';

class WarehouseUserModel extends Equatable {
  final int id;
  final int warehouseId;
  final int userId;
  final String role;
  final String? joinedAt;
  final String? userName;
  final String? userEmail;

  const WarehouseUserModel({
    required this.id,
    required this.warehouseId,
    required this.userId,
    required this.role,
    this.joinedAt,
    this.userName,
    this.userEmail,
  });

  factory WarehouseUserModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return WarehouseUserModel(
      id: json['id'] as int,
      warehouseId: json['warehouse_id'] as int,
      userId: json['user_id'] as int,
      role: json['role'] as String,
      joinedAt: json['joined_at'] as String?,
      userName: user?['name'] as String?,
      userEmail: user?['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'warehouse_id': warehouseId,
        'user_id': userId,
        'role': role,
        'joined_at': joinedAt,
      };

  @override
  List<Object?> get props => [id, warehouseId, userId, role];
}
