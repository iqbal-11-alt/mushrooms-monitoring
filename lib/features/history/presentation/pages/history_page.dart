import 'package:flutter/material.dart';
import 'package:monitoring_jamur/core/theme/app_theme.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'History Content Coming Soon',
          style: TextStyle(color: AppTheme.textLight),
        ),
      ),
    );
  }
}
