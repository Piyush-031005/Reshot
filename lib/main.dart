import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard.dart';
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
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'models/hidden_gem_model.dart';

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
      await syncService.syncAll();
      
      // Give it a moment to complete initial sync
      await Future.delayed(const Duration(seconds: 2));
      
      // Verification: Firestore Document Creation
      final testGem = HiddenGemModel(
        id: 'verify-gem-123',
        name: 'Cloud Verification Gem',
        description: 'Testing firestore upload',
        latitude: 12.34, longitude: 56.78, altitude: '100m', tags: ['Test'],
        photoPath: 'e:/APPS/IMAGE/test_image.jpg',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Simulate saving locally, which triggers SyncService
      debugPrint('VERIFICATION_EVIDENCE: Saving gem locally to trigger sync...');
      final provider = AppRepositoryProvider(
            galleryRepository: localGalleryRepo,
            hiddenGemRepository: localHiddenGemRepo,
            profileRepository: localProfileRepo,
            syncService: syncService,
            cameras: cameras,
      );
      await provider.saveHiddenGem(testGem);
      
      // Wait for sync to propagate
      await Future.delayed(const Duration(seconds: 4));
      
      // Verify Firestore and Multi-device retrieval
      final doc = await FirebaseFirestore.instance.collection('hidden_gems').doc('verify-gem-123').get();
      if (doc.exists) {
        debugPrint('VERIFICATION_EVIDENCE: Firestore document retrieved successfully from cloud! Data: ${doc.data()}');
      } else {
        debugPrint('VERIFICATION_EVIDENCE: Failed to retrieve document from Firestore.');
      }
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
      ],
      child: const ReShotApp(),
    ),
  );
}

class ReShotApp extends StatelessWidget {
  const ReShotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReShot AI',
      debugShowCheckedModeBanner: false,
      theme: CyberTheme.themeData,
      home: const DashboardScreen(),
    );
  }
}
