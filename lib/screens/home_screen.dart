import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  final Function onThemeToggle;
  final FocusNode focusNode;
  
  const HomeScreen({
    super.key, 
    required this.onThemeToggle,
    required this.focusNode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime selectedDate = DateTime.now();
  Map<DateTime, Map<String, List<String>>> dailyRoutines = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    if (_userId == null) {
      setState(() {
        _error = 'Please sign in to save your routines';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('Loading routines for user: $_userId');

      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      print('Loading routines from $startOfWeek to $endOfWeek');

      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('routines')
          .get();

      print('Found ${snapshot.docs.length} documents');

      final Map<DateTime, Map<String, List<String>>> loadedRoutines = {};

      for (var doc in snapshot.docs) {
        print('Processing document: ${doc.id}');
        print('Document data: ${doc.data()}');
        
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final dateKey = DateTime(date.year, date.month, date.day);
        
        loadedRoutines[dateKey] = {
          'morning': List<String>.from(data['morning'] ?? []),
          'evening': List<String>.from(data['evening'] ?? []),
        };
      }

      print('Loaded routines: $loadedRoutines');

      if (mounted) {
        setState(() {
          dailyRoutines = loadedRoutines;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading routines: $e');
      if (mounted) {
        setState(() {
          _error = 'Error loading routines: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveRoutine(DateTime date, String routine, List<String> products) async {
    if (_userId == null) {
      print('Error: No user ID available');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save routines')),
      );
      return;
    }

    try {
      final dateKey = DateTime(date.year, date.month, date.day);
      final docId = dateKey.toIso8601String().split('T')[0]; // Use just the date part as ID

      print('=== Starting Save Operation ===');
      print('Document ID: $docId');
      print('User ID: $_userId');
      print('Routine type: $routine');
      print('Products to save: $products');

      // Get the current routines for this date
      final currentRoutines = dailyRoutines[dateKey] ?? {
        'morning': <String>[],
        'evening': <String>[],
      };

      // Update the specific routine (morning or evening)
      currentRoutines[routine] = products;

      // Create the complete document data
      final Map<String, dynamic> routineData = {
        'date': Timestamp.fromDate(dateKey),
        'lastUpdated': FieldValue.serverTimestamp(),
        'userId': _userId,
        'morning': currentRoutines['morning'],
        'evening': currentRoutines['evening'],
      };

      print('Full data to save: $routineData');

      // Reference to the user's routines collection
      final userRoutinesRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('routines')
          .doc(docId);

      print('Attempting to save to path: users/$_userId/routines/$docId');

      // Save the data
      await userRoutinesRef.set(routineData);

      // Verify the save by reading it back
      final savedDoc = await userRoutinesRef.get();
      if (savedDoc.exists) {
        print('Document saved successfully!');
        print('Saved data: ${savedDoc.data()}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Routine saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('Error: Document was not saved properly');
        throw Exception('Document was not saved properly');
      }

    } catch (e, stackTrace) {
      print('Error saving routine: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving routine: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addProduct(String routine, String product) {
    setState(() {
      final dateKey = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      if (!dailyRoutines.containsKey(dateKey)) {
        dailyRoutines[dateKey] = {
          'morning': [],
          'evening': [],
        };
      }
      dailyRoutines[dateKey]![routine]!.add(product);
      
      // Save to Firebase with more descriptive product name
      final productName = 'Product ${dailyRoutines[dateKey]![routine]!.length}';
      _saveRoutine(dateKey, routine, dailyRoutines[dateKey]![routine]!);
    });
  }

  void _removeProduct(String routine, int index) {
    setState(() {
      final dateKey = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      if (dailyRoutines.containsKey(dateKey)) {
        dailyRoutines[dateKey]![routine]!.removeAt(index);
        
        // Save to Firebase after removal
        _saveRoutine(dateKey, routine, dailyRoutines[dateKey]![routine]!);
      }
    });
  }

  List<String> _getProductsForDate(String routine) {
    final dateKey = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return dailyRoutines[dateKey]?[routine] ?? [];
  }

  String _getDayAbbreviation(int day) {
    return ['S', 'M', 'T', 'W', 'T', 'F', 'S'][day % 7];
  }

  String _getDayNumber(DateTime date) {
    return date.day.toString();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _showUserId() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your User ID (for finding data in Firebase Console):'),
              const SizedBox(height: 4),
              SelectableText(userId),
            ],
          ),
          duration: const Duration(seconds: 20),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dayWidth = (screenWidth - 32) / 7;

    // Generate dates for the current week
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday));
    final weekDates = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRoutines,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFF8DA1),
                    Color(0xFFFFB6C1),
                    Color(0xFFFFCCD5),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
            floating: true,
            pinned: true,
            expandedHeight: 160,
            centerTitle: true,
            toolbarHeight: 80,
            actions: [
              IconButton(
                icon: Icon(
                  Theme.of(context).brightness == Brightness.dark 
                      ? Icons.light_mode 
                      : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: () => widget.onThemeToggle(),
              ),
              const SizedBox(width: 8),
            ],
            title: const Text(
              'SkinScan',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(2, 2),
                    blurRadius: 4,
                    color: Colors.black26,
                  ),
                ],
                letterSpacing: 1.2,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: weekDates.map((date) {
                    final isSelected = date.year == selectedDate.year &&
                        date.month == selectedDate.month &&
                        date.day == selectedDate.day;
                    final hasRoutine = dailyRoutines.containsKey(
                      DateTime(date.year, date.month, date.day),
                    ) &&
                        (dailyRoutines[DateTime(date.year, date.month, date.day)]!['morning']!.isNotEmpty ||
                            dailyRoutines[DateTime(date.year, date.month, date.day)]!['evening']!.isNotEmpty);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDate = date;
                        });
                      },
                      child: Container(
                        width: dayWidth - 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isSelected
                                ? [
                                    Colors.white.withOpacity(0.95),
                                    Colors.white.withOpacity(0.7),
                                  ]
                                : hasRoutine
                                    ? [
                                        Colors.white.withOpacity(0.6),
                                        Colors.white.withOpacity(0.3),
                                      ]
                                    : [
                                        Colors.white.withOpacity(0.4),
                                        Colors.white.withOpacity(0.1),
                                      ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.2),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getDayAbbreviation(date.weekday),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.pink[800]
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              date.day.toString(),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.pink[800]
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                widget.focusNode.unfocus();
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      focusNode: widget.focusNode,
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildRoutineBar(),
                    const SizedBox(height: 20),
                    _buildCategories(),
                    _buildRecentScans(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _CategoryCard(
                title: 'Skincare',
                icon: Icons.face_retouching_natural,
                color: Colors.blue,
              ),
              _CategoryCard(
                title: 'Makeup',
                icon: Icons.brush,
                color: Colors.pink,
              ),
              _CategoryCard(
                title: 'Hair Care',
                icon: Icons.cut,
                color: Colors.purple,
              ),
              _CategoryCard(
                title: 'Body Care',
                icon: Icons.spa,
                color: Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentScans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Scans',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        _RecentScanCard(
          productName: 'Face Moisturizer',
          score: '85',
          description: 'Safe for sensitive skin',
        ),
      ],
    );
  }

  Widget _buildRoutineBar() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      color: Colors.white.withOpacity(0.8),
      child: ExpansionTile(
        title: const Text(
          'My Routine',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.pink[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.face_retouching_natural, color: Colors.pink),
        ),
        children: [
          _buildRoutineSection(
            'Morning Routine',
            Icons.wb_sunny,
            'Start your day with these products',
            Colors.orange[50],
            'morning',
          ),
          const Divider(height: 1),
          _buildRoutineSection(
            'Evening Routine',
            Icons.nightlight_round,
            'End your day with these products',
            Colors.blue[50],
            'evening',
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineSection(String title, IconData icon, String subtitle, Color? backgroundColor, String routineType) {
    final products = _getProductsForDate(routineType);
    
    return Container(
      color: backgroundColor?.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.black87),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (products.isEmpty)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 32,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your products',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: products.asMap().entries.map((entry) {
                  final index = entry.key;
                  final product = entry.value;
                  return Chip(
                    label: Text(product),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeProduct(routineType, index),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                // TODO: Show product selection dialog
                _addProduct(routineType, 'Sample Product ${DateTime.now().millisecondsSinceEpoch}');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black87,
                backgroundColor: backgroundColor?.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RecentScanCard extends StatelessWidget {
  final String productName;
  final String score;
  final String description;

  const _RecentScanCard({
    required this.productName,
    required this.score,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                productName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$score%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description),
        ],
      ),
    );
  }
} 