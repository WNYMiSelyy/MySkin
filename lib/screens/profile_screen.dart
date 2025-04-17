import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error signing out')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      user?.email?.substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    user?.email ?? 'No email',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                _buildProfileSection(
                  title: 'Account Settings',
                  children: [
                    _buildProfileItem(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      subtitle: user?.email ?? 'Not set',
                    ),
                    _buildProfileItem(
                      icon: Icons.security_outlined,
                      title: 'Password',
                      subtitle: '••••••••',
                      onTap: () {
                        // TODO: Implement password change
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildProfileSection(
                  title: 'App Settings',
                  children: [
                    _buildProfileItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Manage your notifications',
                      onTap: () {
                        // TODO: Implement notifications settings
                      },
                    ),
                    _buildProfileItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'Get help with the app',
                      onTap: () {
                        // TODO: Implement help & support
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _logout,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout),
                              SizedBox(width: 8),
                              Text(
                                'Logout',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
        trailing: onTap != null
            ? const Icon(Icons.chevron_right)
            : null,
      ),
    );
  }
} 