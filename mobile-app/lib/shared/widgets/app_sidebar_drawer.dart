import 'package:flutter/material.dart';

import '../../features/about/about_us_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/contact/contact_us_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/data_backup_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';

class AppSidebarDrawer extends StatefulWidget {
  const AppSidebarDrawer({super.key});

  @override
  State<AppSidebarDrawer> createState() => _AppSidebarDrawerState();
}

class _AppSidebarDrawerState extends State<AppSidebarDrawer> {
  UserModel? user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final profile = await const ProfileService().getProfile();
      if (!mounted) return;
      setState(() => user = profile);
    } catch (_) {
      if (!mounted) return;
      setState(() => user = null);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openScreen(Widget screen) async {
    Navigator.pop(context);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    await loadProfile();
  }

  Future<void> logout() async {
    Navigator.pop(context);
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.photoUrl?.trim() ?? '';
    final initials = (user?.displayName ?? 'U').characters.first.toUpperCase();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E2A78), Color(0xFF5B6EF5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: loading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
                        child: photoUrl.isEmpty
                            ? Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'NBExpenseManager',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'Manage your account',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          if (user != null)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              subtitle: const Text('Personal details and profile photo'),
              onTap: () => openScreen(ProfileScreen(user: user!)),
            ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            subtitle: const Text('Password, logout, and security'),
            onTap: () => openScreen(const SettingsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Backup & Restore'),
            subtitle: const Text('Import and export CSV backups'),
            onTap: () => openScreen(const DataBackupScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_outlined),
            title: const Text('Contact Us'),
            subtitle: const Text('Support and business help'),
            onTap: () => openScreen(const ContactUsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Us'),
            subtitle: const Text('About NBExpenseManager'),
            onTap: () => openScreen(const AboutUsScreen()),
          ),
          const Divider(height: 20),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: logout,
          ),
        ],
      ),
    );
  }
}
