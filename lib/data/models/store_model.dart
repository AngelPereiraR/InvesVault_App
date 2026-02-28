import 'package:equatable/equatable.dart';

class StoreModel extends Equatable {
  final int id;
  final String name;
  final String? location;

  const StoreModel({required this.id, required this.name, this.location});

  factory StoreModel.fromJson(Map<String, dynamic> json) => StoreModel(
        id: json['id'] as int,
        name: json['name'] as String,
        location: json['location'] as String?,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'location': location};

  @override
  List<Object?> get props => [id, name, location];
}
