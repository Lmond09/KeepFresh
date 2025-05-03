import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ItemDialog extends StatelessWidget {
  final String title;
  final bool isEditing;
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final DateTime? selectedDate;
  final VoidCallback onPickDate;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const ItemDialog({
    super.key,
    required this.title,
    required this.isEditing,
    required this.nameController,
    required this.quantityController,
    required this.selectedDate,
    required this.onPickDate,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.grey.shade100,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onPickDate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade100,
                foregroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.calendar_today),
              label: const Text(
                'Pick Expiry Date',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            if (selectedDate != null)
              Row(
                children: [
                  const Icon(Icons.event, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Text(
                    'Expiry Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onSubmit,
          child: Text(
            isEditing ? 'Save' : 'Add',
            style: const TextStyle(color: Colors.deepPurple),
          ),
        ),
        TextButton(
          onPressed: onCancel,
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
