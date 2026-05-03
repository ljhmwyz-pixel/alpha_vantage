import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_config.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        children: const <Widget>[
          ListTile(
            leading: Icon(Icons.dns_outlined),
            title: Text('API base URL'),
            subtitle: Text(AppConfig.apiBaseUrl),
          ),
          ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('User'),
            subtitle: Text(AppConfig.demoUserId),
          ),
        ],
      ),
    );
  }
}
