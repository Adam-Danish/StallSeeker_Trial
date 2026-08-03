class MenuItemModel {
  final String itemId;
  final String name;
  final double price;
  final String
      status; // 'available' (Green), 'low_stock' (Yellow), 'out_of_stock' (Red)

  MenuItemModel({
    required this.itemId,
    required this.name,
    required this.price,
    this.status = 'available',
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'price': price,
      'status': status,
    };
  }

  factory MenuItemModel.fromMap(Map<String, dynamic> map, String id) {
    return MenuItemModel(
      itemId: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'available',
    );
  }
}
