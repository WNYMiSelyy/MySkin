import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize auth state
  await FirebaseAuth.instance.authStateChanges().first;
  
  runApp(const SkinScanApp());
}

class SkinScanApp extends StatefulWidget {
  const SkinScanApp({super.key});

  @override
  State<SkinScanApp> createState() => _SkinScanAppState();
}

class _SkinScanAppState extends State<SkinScanApp> {
  bool _isDarkMode = false;

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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasData) {
            return MainScreen(
              toggleTheme: toggleTheme,
              isDarkMode: _isDarkMode,
            );
          }
          
          return const LoginScreen();
        },
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
  bool _isKeyboardVisible = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isKeyboardVisible = _focusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _startQRScanner() async {
    // Hide keyboard and remove focus before opening scanner
    FocusScope.of(context).unfocus();
    _focusNode.unfocus();
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
    
    // Ensure keyboard stays hidden and focus is removed after returning from scanner
    FocusScope.of(context).unfocus();
    _focusNode.unfocus();
    
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scanned: $result'),
          backgroundColor: const Color(0xFFFFC7C7),
        ),
      );
    }
  }

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
            HomeScreen(
              onThemeToggle: widget.toggleTheme,
              focusNode: _focusNode,
            ),
            const SizedBox(),
            const ProfileScreen(),
          ],
        ),
        floatingActionButton: _isKeyboardVisible ? null : FloatingActionButton(
          onPressed: _startQRScanner,
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
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 0),
                  child: Column(
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
                ),
                const SizedBox(width: 40),
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 2),
                  child: Column(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
