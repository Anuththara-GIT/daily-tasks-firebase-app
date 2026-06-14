import 'package:flutter/material.dart';

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key, this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF7E8DA),
              Color(0xFFE8F1E4),
              Color(0xFFD8E2D1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        size: 36,
                        color: Color(0xFF2F6B45),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Connect Firebase to continue',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The task app is ready, but it still needs your Firebase '
                      'Android configuration before it can save daily tasks.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF33433A),
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 24),
                    const _SetupStepCard(
                      step: '1',
                      title: 'Create a Firebase project',
                      description:
                          'Open the Firebase console and create a new project '
                          'for this mobile app.',
                    ),
                    const SizedBox(height: 12),
                    const _SetupStepCard(
                      step: '2',
                      title: 'Register the Android app',
                      description:
                          'Use package name com.example.daily_tasks_app when '
                          'adding the Android app inside Firebase.',
                    ),
                    const SizedBox(height: 12),
                    const _SetupStepCard(
                      step: '3',
                      title: 'Add google-services.json',
                      description:
                          'Download google-services.json and place it in '
                          'android/app/google-services.json.',
                    ),
                    const SizedBox(height: 12),
                    const _SetupStepCard(
                      step: '4',
                      title: 'Run the app again',
                      description:
                          'After the file is added, run flutter clean and '
                          'flutter run to start syncing tasks with Firestore.',
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Current initialization error',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFD2C2B5),
                          ),
                        ),
                        child: SelectableText(
                          errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.4,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupStepCard extends StatelessWidget {
  const _SetupStepCard({
    required this.step,
    required this.title,
    required this.description,
  });

  final String step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF2F6B45),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: const Color(0xFF3C4C42),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
