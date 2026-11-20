import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/firestore_spend_repository.dart';
import 'data/repositories/spend_repository.dart';
import 'features/shell/app_shell.dart';
import 'providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localRepo = LocalSpendRepository(seedDemoData: false);
  await localRepo.loadFromDisk();
  SpendRepository repository = localRepo;

  // Attempt Firebase initialization. Once you run `flutterfire configure`
  // and pass `DefaultFirebaseOptions.currentPlatform`, SpendWise automatically
  // enables Cloud Firestore offline persistence and syncs under the user's UID.
  try {
    await Firebase.initializeApp();
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
    final uid = auth.currentUser?.uid;
    if (uid != null) {
      repository = FirestoreSpendRepository(uid: uid);
    }
  } catch (_) {
    // Runs cleanly with fresh local on-device persistence until Firebase is configured.
  }

  runApp(
    ProviderScope(
      overrides: [
        spendRepositoryProvider.overrideWithValue(repository),
      ],
      child: const SpendWiseApp(),
    ),
  );
}

class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendWise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 540) {
              return ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              );
            }
            return child ?? const SizedBox.shrink();
          },
        );
      },
      home: const AppShell(),
    );
  }
}
