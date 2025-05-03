import 'package:flutter/material.dart';
import 'package:keepfresh/screens/calendar_page.dart';
import 'package:keepfresh/screens/recipe_screen.dart';
import 'fridge_page.dart';
import 'freezer_page.dart';
import 'pantry_page.dart';
import 'shopping_list_page.dart';
import 'login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keepfresh/services/reminder_services.dart';


class HomePage extends StatefulWidget {
  final String username;

  const HomePage({super.key, required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  late List<Widget> _pages;
  
/// Initializes reminder services and page navigation widgets.
  @override
  void initState() {
    super.initState();
    ReminderService.showExpiryReminders(widget.username);       
    ReminderService.scheduleDailyReminder(widget.username);     
    _pages = [
      FridgePage(username: widget.username),
      FreezerPage(username: widget.username),
      PantryPage(username: widget.username),
      ShoppingListPage(username: widget.username),
      CalendarScreen(username: widget.username),
      RecipeScreen(username: widget.username),
    ];
  }
/// Updates the currently selected page based on the bottom navigation index.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
 /// Logs the user out and redirects to the login
  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainMenuPage()),
    );
  }
/// Builds the HomePage UI including the app bar, dynamic page content, and bottom navigation bar.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'KeepFresh',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF26A69A), Color(0xFF80CBC4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen),
            label: 'Fridge',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.ac_unit),
            label: 'Freezer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Pantry',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Shopping List',
          ),
            BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), 
            label: 'Calendar',
          ),
            BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu), 
            label: 'Recipe',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF26A69A),
        unselectedItemColor: Colors.grey.shade500,
        backgroundColor: Colors.white,
        elevation: 12,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
