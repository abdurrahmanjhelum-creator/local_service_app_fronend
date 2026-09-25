class CategoryModel {
  final String id;
  final String name;
  final String iconName;

  CategoryModel({
    required this.id,
    required this.name,
    this.iconName = '',
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      iconName: json['iconName'] ?? '',
    );
  }
}
