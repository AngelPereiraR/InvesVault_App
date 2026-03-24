import 'package:equatable/equatable.dart';

class BatchModel extends Equatable {
  final int id;
  final int warehouseProductId;
  final double quantity;
  final String? expiryDate; // ISO date string "YYYY-MM-DD" or null
  final String? notes;
  final String? createdAt;

  const BatchModel({
    required this.id,
    required this.warehouseProductId,
    required this.quantity,
    this.expiryDate,
    this.notes,
    this.createdAt,
  });

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      id: json['id'] as int,
      warehouseProductId: json['warehouse_product_id'] as int,
      quantity: double.tryParse(json['quantity'].toString()) ?? 0,
      expiryDate: json['expiry_date'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'warehouse_product_id': warehouseProductId,
        'quantity': quantity,
        if (expiryDate != null) 'expiry_date': expiryDate,
        if (notes != null) 'notes': notes,
      };

  BatchModel copyWith({
    int? id,
    int? warehouseProductId,
    double? quantity,
    String? expiryDate,
    String? notes,
    String? createdAt,
  }) =>
      BatchModel(
        id: id ?? this.id,
        warehouseProductId: warehouseProductId ?? this.warehouseProductId,
        quantity: quantity ?? this.quantity,
        expiryDate: expiryDate ?? this.expiryDate,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Returns true if this batch has an expiry date within the next 7 days.
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final expiry = DateTime.tryParse(expiryDate!);
    if (expiry == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = expiry.difference(today).inDays;
    return diff >= 0 && diff <= 7;
  }

  @override
  List<Object?> get props => [id, warehouseProductId, quantity, expiryDate, notes];
}
