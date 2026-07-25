import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// استيراد الشاشات المنفصلة لتفعيل الربط الاحترافي
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
            return const HomeScreen(); // موجه للشاشة الرئيسية المنفصلة
          }
          return const LoginScreen(); // موجه لشاشة تسجيل الدخول المنفصلة
        },
      ),
    );
  }

}
class AppLogger {
  // دالة سحابية ثابتة لتسجيل نشاطات المسؤولين والموظفين تلقائياً
  static Future<void> logActivity({
    required String action,      // نوع الحركة (مثال: إضافة عقد)
    required String details,     // تفاصيل الحركة (اسم العميل أو الحارس)
    required String userEmail,   // بريد الشخص الذي قام بالحركة
  }) async {
    try {
      await FirebaseFirestore.instance.collection('activity_logs').add({
        'action': action,
        'details': details,
        'userEmail': userEmail,
        'timestamp': FieldValue.serverTimestamp(), // توقيت خوادم جوجل الدقيق
      });
    } catch (e) {
      debugPrint('🚨 فشل تسجيل النشاط في السحاب: $e');
    }
  }
}
