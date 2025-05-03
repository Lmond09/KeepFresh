import 'package:flutter/material.dart';
import '../models/shopping_item.dart';
import '../services/storage_service.dart';

class ShoppingListPage extends StatefulWidget {
  final String username;

  const ShoppingListPage({super.key, required this.username});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  List<ShoppingItem> _items = [];
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

/// Load shopping items from storage for the current user
  Future<void> _loadItems() async {
    final items = await StorageService.loadShoppingItems(widget.username);
    setState(() {
      _items = items;
    });
  }

/// Save the current list of shopping items to storage
  Future<void> _saveItems() async {
    await StorageService.saveShoppingItems(widget.username, _items);
  }

 /// Add a new item to the shopping list
  void _addItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _items.add(ShoppingItem(
          name: _nameController.text.trim(),
          quantity: int.parse(_quantityController.text),
          isChecked: false,
        ));
      });
      await _saveItems();
      _resetForm();
      Navigator.of(context).pop();
    }
  }

  void _resetForm() {
    _nameController.clear();
    _quantityController.clear();
  }

  void _deleteItem(int index) async {
    setState(() {
      _items.removeAt(index);
    });
    await _saveItems();
  }

  void _clearCheckedItems() async {
    setState(() {
      _items.removeWhere((item) => item.isChecked);
    });
    await _saveItems();
  }


/// Suggest shopping items based on low stock or near expiry items in the fridge
  void _generateSuggestions() async {
    final allStock = await StorageService.loadFridgeItems(widget.username);
    final now = DateTime.now();
    int addedCount = 0;

    for (var item in allStock) {
      bool isLowStock = item.quantity < 2;
      bool isNearExpiry = item.expirationDate.difference(now).inDays <= 5;
      bool alreadyInList = _items.any((i) => i.name == item.name);

      if ((isLowStock || isNearExpiry) && !alreadyInList) {
        _items.add(ShoppingItem(name: item.name, quantity: 1, isChecked: false));
        addedCount++;
      }
    }

    await _saveItems();
    setState(() {});

    // Show a snackbar message if widget is still mounted
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$addedCount item(s) suggested and added.')),
      );
    }
  }

  /// Display a dialog form to add a new shopping item
  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Shopping Item'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final n = int.tryParse(value ?? '');
                  if (n == null || n <= 0) return 'Enter a valid number';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _addItem,
            child: const Text('Add'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sort unchecked items first
    final sortedItems = [..._items];
    sortedItems.sort((a, b) {
      if (a.isChecked == b.isChecked) return 0;
      return a.isChecked ? 1 : -1;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        backgroundColor: const Color(0xFF26A69A),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            tooltip: 'Generate Suggestions',
            onPressed: _generateSuggestions,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_checked') {
                _clearCheckedItems();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'clear_checked',
                child: Text('Clear Checked Items'),
              ),
            ],
          ),
        ],
      ),
      body: sortedItems.isEmpty
          ? const Center(child: Text('No shopping items yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedItems.length,
              itemBuilder: (context, index) {
                final item = sortedItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(

                    // Checkbox to mark item as purchased
                    leading: Checkbox(
                      value: item.isChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          item.isChecked = value ?? false;
                        });
                        _saveItems();
                      },
                    ),
                    // Display item name with strikethrough if checked
                    title: Text(
                      item.name,
                      style: TextStyle(
                        decoration: item.isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(
                      'Quantity: ${item.quantity}',
                      style: TextStyle(
                        decoration: item.isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),

                    // Delete button for removing the item
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteItem(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: const Color(0xFFFF7043),
        child: const Icon(Icons.add),
      ),
    );
  }
}
