import 'package:flutter/material.dart';
import 'package:monitoring_jamur/core/theme/app_theme.dart';
import 'package:monitoring_jamur/core/session/user_session.dart';
import 'package:monitoring_jamur/features/auth/presentation/pages/login_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manajemen Akun',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 32),
              // Main Consolidated Frame
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Cool User Icon
                    _buildCoolUserIcon(),
                    const SizedBox(height: 24),
                    // Username Info
                    Text(
                      UserSession.username ?? 'Guest',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const Text(
                      'Account Owner',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 32, thickness: 1.0, color: AppTheme.backgroundBeige),
                    const SizedBox(height: 8),
                    // Menu Items
                    _buildMenuTile(
                      icon: Icons.settings_rounded,
                      title: 'Kelola Akun',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fitur Kelola Akun segera hadir')),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuTile(
                      icon: Icons.logout_rounded,
                      title: 'Log out',
                      isDestructive: true,
                      onTap: () async {
                        await UserSession.logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoolUserIcon() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, Color(0xFF81C784)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withAlpha(40),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.manage_accounts_rounded,
            size: 56,
            color: AppTheme.primaryGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red.shade700 : AppTheme.primaryGreen;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withAlpha(10) : AppTheme.backgroundBeige.withAlpha(50),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive ? Colors.red.withAlpha(20) : AppTheme.primaryGreen.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? color : AppTheme.textDark,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textLight.withAlpha(100)),
          ],
        ),
      ),
    );
  }
}
