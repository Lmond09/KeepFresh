class FridgeItem {
  final String name;
  final int quantity;
  final DateTime expirationDate;
  final String storageType;

  FridgeItem({
    required this.name,
    required this.quantity,
    required this.expirationDate,
    required this.storageType,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'expirationDate': expirationDate.toIso8601String(),
        'storageType': storageType,
      };

  factory FridgeItem.fromJson(Map<String, dynamic> json) => FridgeItem(
        name: json['name'],
        quantity: json['quantity'],
        expirationDate: DateTime.parse(json['expirationDate']),
        storageType: json['storageType'],
      );
}
