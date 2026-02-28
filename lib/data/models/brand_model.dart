import 'package:equatable/equatable.dart';

class BrandModel extends Equatable {
  final int id;
  final String name;

  const BrandModel({required this.id, required this.name});

  factory BrandModel.fromJson(Map<String, dynamic> json) => BrandModel(
        id: json['id'] as int,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  List<Object?> get props => [id, name];
}
