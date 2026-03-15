import 'package:equatable/equatable.dart';

class WarehouseModel extends Equatable {
  final int id;
  final String name;
  final int ownerId;
  final bool isShared;
  final String? createdAt;
  final String? updatedAt;
  final int? productCount;

  const WarehouseModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.isShared,
    this.createdAt,
    this.updatedAt,
    this.productCount,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) => WarehouseModel(
        id: json['id'] as int,
        name: json['name'] as String,
        ownerId: json['owner_id'] as int,
        isShared: json['is_shared'] as bool? ?? false,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
        productCount: (json['productCount'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'owner_id': ownerId,
        'is_shared': isShared,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  WarehouseModel copyWith({
    String? name,
    bool? isShared,
  }) =>
      WarehouseModel(
        id: id,
        name: name ?? this.name,
        ownerId: ownerId,
        isShared: isShared ?? this.isShared,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  @override
  List<Object?> get props => [id, name, ownerId, isShared];
}
