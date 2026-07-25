import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyCDNwci6C3rK3_F6T3YxSLf-hP4C4KcphM',
      appId: '1:331251595053:android:7d003e4c9a4aadc36985a4',
      messagingSenderId: '331251595053',
      projectId: 'securitycompanyapp-ad3c1',
      storageBucket: 'securitycompanyapp-ad3c1.firebasestorage.app',
    ),
  );

  runApp(const SecurityCompanyApp());
}

class SecurityCompanyApp extends StatelessWidget {
  const SecurityCompanyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام شركة الحماية والأمن',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class AppLogger {
  static Future<void> logActivity({
    required String action,
    required String details,
    required String userEmail,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('activity_logs').add({
        'action': action,
        'details': details,
        'userEmail': userEmail,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Activity log saved successfully');
    } catch (e) {
      debugPrint('🚨 Activity log failed: $e');
    }
  }
}
