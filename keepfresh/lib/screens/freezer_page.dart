import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fridge_item.dart';
import '../services/storage_service.dart';
import '../widgets/item_dialog.dart';
import '../controllers/food_controller.dart';
import '../services/image_service.dart';

enum SortOption { name, quantity }

class FreezerPage extends StatefulWidget {
  final String username;

  const FreezerPage({super.key, required this.username});

  @override
  State<FreezerPage> createState() => _FreezerPageState();
}

class _FreezerPageState extends State<FreezerPage> {
  List<FridgeItem> _items = [];
  List<FridgeItem> _filteredItems = [];
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _searchController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedStorageType = 'Freezer';
  bool _isEditing = false;
  int _editingIndex = -1;
  bool _sortAscending = true;
  SortOption _sortOption = SortOption.quantity;

  @override
  void initState() {
    super.initState();
    _loadSortPreferences();
    _loadItems();
    _searchController.addListener(_filterItems);
  }

/// Loads user-defined sorting preferences 
  Future<void> _loadSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sortOption = SortOption.values[prefs.getInt('${widget.username}_freezer_sortOption') ?? 1];
      _sortAscending = prefs.getBool('${widget.username}_freezer_sortAscending') ?? true;
    });
  }
 /// Saves the current sorting preferences
  Future<void> _saveSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${widget.username}_freezer_sortOption', _sortOption.index);
    await prefs.setBool('${widget.username}_freezer_sortAscending', _sortAscending);
  }
  /// Loads all items from storage
  Future<void> _loadItems() async {
    final allItems = await StorageService.loadFridgeItems(widget.username);
    setState(() {
      _items = allItems.where((item) => item.storageType == 'Freezer').toList();
      _filterItems();
    });
  }
/// Filters items based on the search query entered in the search field
  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _items.where((item) {
        return item.name.toLowerCase().contains(query);
      }).toList();
      _sortItems();
    });
  }
 /// Sorts the currently filtered items based on user-selected sorting criteria and direction.
  void _sortItems() {
    _filteredItems.sort((a, b) {
      if (_sortOption == SortOption.quantity) {
        return _sortAscending ? a.quantity.compareTo(b.quantity) : b.quantity.compareTo(a.quantity);
      } else {
        return _sortAscending ? a.name.compareTo(b.name) : b.name.compareTo(a.name);
      }
    });
  }
 /// Toggles the sorting direction (ascending/descending) and updates preferences.
  void _toggleSortDirection() {
    setState(() {
      _sortAscending = !_sortAscending;
      _sortItems();
      _saveSortPreferences();
    });
  }
  /// Updates the sort option (by name or quantity) and refreshes preferences.
  void _setSortOption(SortOption? option) {
    if (option != null) {
      setState(() {
        _sortOption = option;
        _sortItems();
        _saveSortPreferences();
      });
    }
  }
  /// Resets the form state to its initial values (used before showing the dialog).
  void _resetForm() {
    _nameController.clear();
    _quantityController.clear();
    _selectedDate = null;
    _selectedStorageType = 'Freezer';
    _isEditing = false;
    _editingIndex = -1;
  }
   /// Adds a new item
  void _addItem() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final allItems = await StorageService.loadFridgeItems(widget.username);
      allItems.add(FridgeItem(
        name: _nameController.text.trim(),
        quantity: int.parse(_quantityController.text),
        expirationDate: _selectedDate!,
        storageType: _selectedStorageType!,
      ));
      await StorageService.saveFridgeItems(widget.username, allItems);
      _loadItems();
      Navigator.of(context).pop();
      _resetForm();
    }
  }
/// Edit items
  void _editItem() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final allItems = await StorageService.loadFridgeItems(widget.username);
      final editingItem = _items[_editingIndex];
      final allIndex = allItems.indexWhere((item) =>
          item.name == editingItem.name &&
          item.expirationDate == editingItem.expirationDate &&
          item.storageType == editingItem.storageType);

      if (allIndex != -1) {
        allItems[allIndex] = FridgeItem(
          name: _nameController.text.trim(),
          quantity: int.parse(_quantityController.text),
          expirationDate: _selectedDate!,
          storageType: _selectedStorageType!,
        );
      }

      await StorageService.saveFridgeItems(widget.username, allItems);
      _loadItems();
      Navigator.of(context).pop();
      _resetForm();
    }
  }
/// Delete item
  void _deleteItem(int index) async {
    final allItems = await StorageService.loadFridgeItems(widget.username);
    final targetItem = _items[index];
    allItems.removeWhere((item) =>
        item.name == targetItem.name &&
        item.expirationDate == targetItem.expirationDate &&
        item.storageType == targetItem.storageType);
    await StorageService.saveFridgeItems(widget.username, allItems);
    _loadItems();
  }
/// Shows the dialog for adding or editing a freezer item.
  void _showItemDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => Form(
            key: _formKey,
            child: ItemDialog(
              title: _isEditing ? 'Edit Freezer Item' : 'Add to Freezer',
              isEditing: _isEditing,
              nameController: _nameController,
              quantityController: _quantityController,
              selectedDate: _selectedDate,
              onPickDate: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                  });
                  setStateDialog(() {});
                }
              },
              onSubmit: _isEditing ? _editItem : _addItem,
              onCancel: () {
                Navigator.of(context).pop();
                _resetForm();
                },
              ),
            ),
          );
         },
        );
       }   
/// Initiates the food scanning process via camera or gallery selection.
  void _scanAndAddFood() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _processImage(fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _processImage(fromCamera: false);
              },
            ),
          ],
        );
      },
    );
  }
  /// Processes the selected image, performs food recognition, and pre-fills form fields.
  Future<void> _processImage({required bool fromCamera}) async {
    await FoodController.loadModel();
    final File? image = await ImageService.pickImage(fromCamera: fromCamera);
    if (image == null) return;

    final result = await FoodController.predictFood(image);
    if (result == null || result["confidence"] < 0.5) {
      _showResultDialog("No food confidently detected.");
      return;
    }

    _resetForm();
    _nameController.text = result["label"];
    _quantityController.text = '1';
    _selectedDate = DateTime.now().add(const Duration(days: 5));
    _selectedStorageType = 'Freezer';

    _showItemDialog();
  }
/// Shows a dialog with a food recognition result or error message.
  void _showResultDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Food Recognition'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final expired = <FridgeItem>[];
    final soon = <FridgeItem>[];
    final later = <FridgeItem>[];

    for (var item in _filteredItems) {
      final diff = item.expirationDate.difference(today).inDays;
      if (diff < 0) {
        expired.add(item);
      } else if (diff <= 7) {
        soon.add(item);
      } else {
        later.add(item);
      }
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<SortOption>(
                  value: _sortOption,
                  onChanged: _setSortOption,
                  items: const [
                    DropdownMenuItem(
                      value: SortOption.name,
                      child: Text('Sort by Name'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.quantity,
                      child: Text('Sort by Quantity'),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: Colors.teal,
                  ),
                  onPressed: _toggleSortDirection,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                if (expired.isNotEmpty) ..._buildGroup('Expired', expired, Colors.red),
                if (soon.isNotEmpty) ..._buildGroup('Expiring Soon (≤ 7 days)', soon, Colors.orange),
                if (later.isNotEmpty) ..._buildGroup('Expiring Later', later, Colors.green),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'scan',
            backgroundColor: Colors.deepPurple,
            onPressed: _scanAndAddFood,
            child: const Icon(Icons.camera_alt),
            tooltip: 'Scan Food',
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'add',
            backgroundColor: const Color(0xFFFF7043),
            onPressed: () {
              _isEditing = false;
              _resetForm();
              _showItemDialog();
            },
            child: const Icon(Icons.add),
            tooltip: 'Add Item',
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroup(String label, List<FridgeItem> items, Color color) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ),
      ...items.map((item) {
        final index = _items.indexOf(item);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(item.name),
            subtitle: Text('Qty: ${item.quantity} | Expires: ${DateFormat.yMd().format(item.expirationDate)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.teal),
                  onPressed: () {
                    _isEditing = true;
                    _editingIndex = index;
                    _nameController.text = item.name;
                    _quantityController.text = item.quantity.toString();
                    _selectedDate = item.expirationDate;
                    _selectedStorageType = item.storageType;
                    _showItemDialog();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteItem(index),
                ),
              ],
            ),
          ),
        );
      }),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
