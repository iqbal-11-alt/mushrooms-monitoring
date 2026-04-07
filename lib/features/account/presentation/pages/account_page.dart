import 'package:flutter/material.dart';
import 'package:monitoring_jamur/core/theme/app_theme.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Account Content Coming Soon',
          style: TextStyle(color: AppTheme.textLight),
        ),
      ),
    );
  }
}
