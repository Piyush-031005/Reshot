import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_shell.dart';
import 'theme/cyber_theme.dart';
import 'repositories/gallery_repository.dart';
import 'repositories/hidden_gem_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/cloud_gallery_repository.dart';
import 'repositories/cloud_hidden_gem_repository.dart';
import 'repositories/cloud_profile_repository.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'providers/repository_provider.dart';
import 'providers/findra_engine_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Error retrieving camera devices: $e');
  }

  final localGalleryRepo = HiveGalleryRepository();
  final localHiddenGemRepo = HiveHiddenGemRepository();
  final localProfileRepo = HiveProfileRepository();

  final authService = AuthService();
  final syncService = SyncService(
    localGalleryRepo: localGalleryRepo,
    localGemRepo: localHiddenGemRepo,
    localProfileRepo: localProfileRepo,
    cloudGalleryRepo: CloudGalleryRepository(),
    cloudGemRepo: CloudHiddenGemRepository(),
    cloudProfileRepo: CloudProfileRepository(),
    authService: authService,
  );

  // Trigger initial anonymous auth and sync
  authService.ensureAnonymousLogin().then((uid) async {
    if (uid != null) {
      debugPrint('VERIFICATION_EVIDENCE: Anonymous Login Successful. UID: $uid');
      
      // Cleanup stale verification data
      try {
        final box = await Hive.openBox<String>('hidden_gems_box');
        if (box.containsKey('verify-gem-123')) {
          await box.delete('verify-gem-123');
          debugPrint('CLEANUP_LOG: Successfully removed stale test record "verify-gem-123" from Hive box.');
        }
        final docsDir = await getApplicationDocumentsDirectory();
        final testFile = File('${docsDir.path}/verify-test-image.png');
        if (await testFile.exists()) {
          await testFile.delete();
          debugPrint('CLEANUP_LOG: Successfully deleted verification image file "verify-test-image.png".');
        }
      } catch (e) {
        debugPrint('CLEANUP_LOG: Error in startup cleanup: $e');
      }

      await syncService.syncAll();
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppRepositoryProvider(
            galleryRepository: localGalleryRepo,
            hiddenGemRepository: localHiddenGemRepo,
            profileRepository: localProfileRepo,
            syncService: syncService,
            cameras: cameras,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => FindraEngineProvider(),
        ),
      ],
      child: const FindraApp(),
    ),
  );
}

class FindraApp extends StatelessWidget {
  const FindraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Findra',
      debugShowCheckedModeBanner: false,
      theme: CyberTheme.themeData,
      // Splash is the entry point — transitions to HomeShell (bottom nav) after animations
      home: const SplashScreen(),
      routes: {
        '/home': (_) => const HomeShell(),
        '/splash': (_) => const SplashScreen(),
      },
    );
  }
}
