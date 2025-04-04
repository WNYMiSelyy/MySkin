import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const SkinScanApp());
}

class SkinScanApp extends StatefulWidget {
  const SkinScanApp({super.key});

  @override
  State<SkinScanApp> createState() => _SkinScanAppState();
}

class _SkinScanAppState extends State<SkinScanApp> {
  bool _isDarkMode = true;

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkinScan',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? _darkTheme : _lightTheme,
      home: MainScreen(
        toggleTheme: toggleTheme,
        isDarkMode: _isDarkMode,
      ),
    );
  }

  final _darkTheme = ThemeData.dark().copyWith(
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFFFF69B4),
      surface: Colors.grey[900]!,
      background: Colors.black,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    useMaterial3: true,
  );

  final _lightTheme = ThemeData.light().copyWith(
    colorScheme: ColorScheme.light(
      primary: const Color(0xFFFF69B4),
      surface: Colors.grey[100]!,
      background: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    useMaterial3: true,
  );
}

class MainScreen extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;

  const MainScreen({
    super.key, 
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.isDarkMode 
            ? const [
                Color(0xFF1A1A1A),
                Color(0xFF0D0D0D),
              ]
            : const [
                Color(0xFFFFF0F5),
                Color(0xFFFFE4E1),
              ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            HomeScreen(onThemeToggle: widget.toggleTheme),
            const SizedBox(), // Empty widget for scan button
            const ProfileScreen(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // TODO: Implement scanning
          },
          backgroundColor: Colors.white,
          child: const Icon(
            Icons.qr_code_scanner,
            size: 28,
            color: Color(0xFFFFC7C7),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          color: const Color(0xFFFFC7C7),
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home,
                      color: _selectedIndex == 0 ? Colors.white : Colors.white70,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Home',
                      style: TextStyle(
                        color: _selectedIndex == 0 ? Colors.white : Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 40),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      color: _selectedIndex == 2 ? Colors.white : Colors.white70,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Profile',
                      style: TextStyle(
                        color: _selectedIndex == 2 ? Colors.white : Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
