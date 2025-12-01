import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to Elo!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Logged in as: ${user?.email}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.home),
              label: const Text('Explore'),
              onPressed: () {
                // Add navigation to explore functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}
