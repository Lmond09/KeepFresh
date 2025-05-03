class ShoppingItem {
  String name;
  int quantity;
  bool isChecked;

  ShoppingItem({
    required this.name,
    required this.quantity,
    this.isChecked = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'isChecked': isChecked,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        name: json['name'],
        quantity: json['quantity'],
        isChecked: json['isChecked'] ?? false,
      );
}
