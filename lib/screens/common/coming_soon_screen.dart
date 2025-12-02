import 'package:flutter/material.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.description,
    this.requirementId,
  });

  final String title;
  final String description;
  final String? requirementId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction,
                  color: theme.colorScheme.primary, size: 64),
              const SizedBox(height: 24),
              Text(
                description,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (requirementId != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Requisito: $requirementId',
                  style: theme.textTheme.labelMedium,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
