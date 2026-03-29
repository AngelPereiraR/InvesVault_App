import 'package:equatable/equatable.dart';
import 'brand_model.dart';
import 'category_model.dart';

class ProductModel extends Equatable {
  final int id;
  final String name;
  final String? barcode;
  final int? brandId;
  final String defaultUnit;
  final int? createdBy;
  final String? imageUrl;
  final String? createdAt;
  final BrandModel? brand;
  final List<CategoryModel> categories;

  const ProductModel({
    required this.id,
    required this.name,
    this.barcode,
    this.brandId,
    required this.defaultUnit,
    this.createdBy,
    this.imageUrl,
    this.createdAt,
    this.brand,
    this.categories = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final brandJson = json['brand'] as Map<String, dynamic>?;
    final categoriesJson = json['categories'] as List<dynamic>?;
    return ProductModel(
      id: json['id'] as int,
      name: json['name'] as String,
      barcode: json['barcode'] as String?,
      brandId: json['brand_id'] as int?,
      defaultUnit: json['default_unit'] as String? ?? 'pcs',
      createdBy: json['created_by'] as int?,
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] as String?,
      brand: brandJson != null ? BrandModel.fromJson(brandJson) : null,
      categories: categoriesJson
              ?.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'barcode': barcode,
        'brand_id': brandId,
        'default_unit': defaultUnit,
        'created_by': createdBy,
        'image_url': imageUrl,
      };

  @override
  List<Object?> get props => [id, name, barcode, brandId, defaultUnit, categories];
}
