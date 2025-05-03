import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/storage_service.dart';
import '../models/fridge_item.dart';

/// Screen for displaying and searching recipes based on selected fridge ingredients.
class RecipeScreen extends StatefulWidget {
  final String username;
  const RecipeScreen({super.key, required this.username});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  List<dynamic> recipes = [];
  List<FridgeItem> userIngredients = [];
  List<FridgeItem> selectedIngredients = [];
  bool _loading = true;
  String _error = '';
  bool _searchPerformed = false;
  bool _isRandomSelection = false;
// Track if random selection is made

  @override
  void initState() {
    super.initState();
    _loadUserIngredients();
  }
   /// Loads fridge items for the current user from local storage
  Future<void> _loadUserIngredients() async {
    try {
      // Load all fridge items from storage
      final allItems = await StorageService.loadFridgeItems(widget.username);
      
      setState(() {
        userIngredients = allItems;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load ingredients: $e';
        _loading = false;
      });
    }
  }
  /// Fetches recipes based on selected ingredients from TheMealDB API
  Future<void> _fetchRecipesByIngredients() async {
    if (selectedIngredients.isEmpty) {
      setState(() {
        _error = 'Please select at least one ingredient.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one ingredient.')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
      _searchPerformed = false; // Reset before searching
      _isRandomSelection = false; // Reset random selection
      recipes.clear();
    });

    try {
      final ingredientsQuery = selectedIngredients.map((e) => e.name).join('&');
      final uri = Uri.parse('https://www.themealdb.com/api/json/v1/1/filter.php?i=$ingredientsQuery');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          recipes = List<Map<String, dynamic>>.from(data['meals'] ?? []);
          _loading = false;
          _searchPerformed = true; // ✅ This is critical
        });
      } else {
        setState(() {
          _error = 'Failed to fetch recipes. Status code: ${response.statusCode}';
          _loading = false;
          _searchPerformed = true; // Show empty state
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred while fetching recipes.';
        _loading = false;
        _searchPerformed = true; // Still show the error
      });
    }
  }


  // Add this method to the _RecipeScreenState class
  Future<void> _viewRecipeDetails(String recipeId) async {
    setState(() {
      _loading = true;
    });

    final url = Uri.parse('https://www.themealdb.com/api/json/v1/1/lookup.php?i=$recipeId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final recipeDetails = data['meals']?[0];
        
        setState(() {
          _loading = false;
        });
        
        if (recipeDetails != null) {
          _showRecipeDetailsDialog(recipeDetails);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recipe details not found')),
          );
        }
      } else {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch recipe details. Status code: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  // Add this method to display recipe details in a dialog
  void _showRecipeDetailsDialog(dynamic recipeDetails) {
    // Extract ingredients and measurements
    List<String> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      final ingredient = recipeDetails['strIngredient$i'];
      final measure = recipeDetails['strMeasure$i'];
      
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients.add('${measure ?? ""} ${ingredient}');
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  recipeDetails['strMeal'] ?? 'Recipe Details',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (recipeDetails['strMealThumb'] != null)
                Image.network(
                  recipeDetails['strMealThumb'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ingredients:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...ingredients.map((ingredient) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text('• $ingredient'),
                      )),
                      const SizedBox(height: 16),
                      const Text(
                        'Instructions:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(recipeDetails['strInstructions'] ?? 'No instructions available'),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildIngredientSelector() {
    if (userIngredients.isEmpty) {
      return const Text(
        'Your fridge is empty. Please add some ingredients first.',
        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select ingredients from your fridge:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: userIngredients.map((ingredient) {
            final isSelected = selectedIngredients.contains(ingredient);
            return FilterChip(
              label: Text(ingredient.name),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected && !selectedIngredients.contains(ingredient)) {
                    selectedIngredients.add(ingredient);
                  } else {
                    selectedIngredients.remove(ingredient);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _fetchRecipesByIngredients,
          child: const Text('Find Recipes'),
        ),
      ],
    );
  }


  Widget _buildRecipeCard(dynamic recipe) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: recipe['strMealThumb'] != null
                ? Image.network(
                    recipe['strMealThumb'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.image_outlined, size: 48, color: Colors.grey),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe['strMeal'] ?? 'No Name',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 8), // Add some spacing between the name and button
                SizedBox(
                  width: double.infinity, // Make the button take full width
                  child: ElevatedButton(
                    onPressed: () {
                      _viewRecipeDetails(recipe['idMeal']);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 14), // Slightly bigger
                    ),
                    child: const Text('View'),
                  ),
                ),
              ],
            ),
          )

        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    // Inside AppBar - Add actions with functionality
    appBar: AppBar(
      title: const Text('Recipe Finder'),
      actions: [
        IconButton(
          icon: const Icon(Icons.lightbulb_outline),
          onPressed: () async {
            setState(() {
              _loading = true;
              _error = '';
              _searchPerformed = true;
              recipes.clear();
              selectedIngredients.clear(); // Optional: clear filters
            });

            try {
              _isRandomSelection = true;
              final uri = Uri.parse('https://www.themealdb.com/api/json/v1/1/random.php');
              final response = await http.get(uri);

              if (response.statusCode == 200) {
                final data = json.decode(response.body);
                final mealsData = data['meals'];
                print(data['meals']);

                if (mealsData is List) {
                  setState(() {
                    recipes = List<Map<String, dynamic>>.from(mealsData);
                    _loading = false;
                  });
                } else {
                  setState(() {
                    _error = 'Unexpected response format from the API.';
                    _loading = false;
                  });
                }
              } else {
                setState(() {
                  _error = 'Failed to load suggestions. (${response.statusCode})';
                  _loading = false;
                });
              }
            } catch (e) {
              setState(() {
                _error = 'Error fetching suggestions: $e';
                _loading = false;
              });
            }
          },
        ),

      ],
    ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty && recipes.isEmpty
              ? Center(child: Text(_error))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIngredientSelector(),
                        const SizedBox(height: 24),
                        if (_searchPerformed) ...[
                          if (recipes.isNotEmpty) ...[
                          Text(  _isRandomSelection
                            ? 'Here are some random recipe suggestions'
                            : 'Recipes with ${selectedIngredients.map((i) => i.name).join(", ")}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: recipes.length,
                            itemBuilder: (context, index) {
                              return _buildRecipeCard(recipes[index]);
                            },
                          )
                        ] else if (selectedIngredients.isNotEmpty) ...[
                          const Text('No recipes found with the selected ingredients.'),
                        ],
                      ],
                    ],
                    ),
                  ),
                ),

    );
  }
}