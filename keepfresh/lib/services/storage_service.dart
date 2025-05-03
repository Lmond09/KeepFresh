
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fridge_item.dart';
import '../models/shopping_item.dart';

class StorageService {
  static Future<void> saveFridgeItems(String username, List<FridgeItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonItems = items.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('${username}_fridge_items', jsonItems);
  }

  static Future<List<FridgeItem>> loadFridgeItems(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonItems = prefs.getStringList('${username}_fridge_items') ?? [];
    return jsonItems.map((json) => FridgeItem.fromJson(jsonDecode(json))).toList();
  }

  static Future<void> saveShoppingItems(String username, List<ShoppingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonItems = items.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('${username}_shopping_items', jsonItems);
  }

  static Future<List<ShoppingItem>> loadShoppingItems(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonItems = prefs.getStringList('${username}_shopping_items') ?? [];
    return jsonItems.map((json) => ShoppingItem.fromJson(jsonDecode(json))).toList();
  }
}
