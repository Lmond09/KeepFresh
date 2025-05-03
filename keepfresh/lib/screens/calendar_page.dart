// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/fridge_item.dart';
import '../services/storage_service.dart';

/// A calendar screen that displays fridge items based on their expiration dates.
class CalendarScreen extends StatefulWidget {
  final String username;
  const CalendarScreen({super.key, required this.username});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  Map<DateTime, List<FridgeItem>> _groupedItems = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  /// Loads items from storage and groups them by expiration date.
  Future<void> _loadItems() async {
    final allItems = await StorageService.loadFridgeItems(widget.username);
    Map<DateTime, List<FridgeItem>> grouped = {};

    for (var item in allItems) {
      final day = DateTime(item.expirationDate.year, item.expirationDate.month, item.expirationDate.day);
      grouped.putIfAbsent(day, () => []).add(item);
    }

    setState(() {
      _groupedItems = grouped;
    });
  }
/// Retrieves the list of fridge items for a specific day.
  List<FridgeItem> _getItemsForDay(DateTime day) {
    return _groupedItems[DateTime(day.year, day.month, day.day)] ?? [];
  }

 /// Builds a colored marker bubble to indicate expiring items on the calendar.
  Widget _buildMarker(DateTime date) {
    final items = _getItemsForDay(date);
    if (items.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final soon = items.any((item) => item.expirationDate.difference(now).inDays <= 5);
    final mid = items.any((item) => item.expirationDate.difference(now).inDays > 5 && item.expirationDate.difference(now).inDays <= 7);
    final long = items.any((item) => item.expirationDate.difference(now).inDays > 7);

    Color bubbleColor = Colors.grey;
    if (soon) {
      bubbleColor = Colors.red;
    } else if (mid) {
      bubbleColor = Colors.yellow;
    } else if (long) {
      bubbleColor = Colors.green;
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '${items.length}',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
  /// Handles date selection on the calendar and displays a dialog
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    final items = _getItemsForDay(selectedDay);
    if (items.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Expiring on ${DateFormat('yyyy-MM-dd').format(selectedDay)}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('Qty: ${item.quantity} • ${item.storageType}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final allItems = await StorageService.loadFridgeItems(widget.username);
                          allItems.removeWhere((i) =>
                            i.name == item.name &&
                            i.quantity == item.quantity &&
                            i.expirationDate == item.expirationDate &&
                            i.storageType == item.storageType
                          );
                          await StorageService.saveFridgeItems(widget.username, allItems);
                          Navigator.pop(context);
                          _loadItems();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _goToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expiry Calendar'),
        backgroundColor: const Color(0xFF26A69A),
        actions: [
          TextButton(
            onPressed: _goToToday,
            child: const Text('Today', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: _onDaySelected,
        calendarFormat: CalendarFormat.month,
        eventLoader: _getItemsForDay,
        availableCalendarFormats: const {CalendarFormat.month: 'Month'}, // Disable format toggle
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) => _buildMarker(date),
        ),
      ),
    );
  }
}
