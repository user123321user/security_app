import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // حزمة الحفظ الثابت للغة
import 'employees_screen.dart';
import 'contracts_screen.dart';
import 'users_screen.dart';
import 'analytics_screen.dart';
import '../utils/app_strings.dart'; // كلاس الترجمة المركزي

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isArabic = true; // الحالة الافتراضية للغة النظام

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage(); // قراءة اللغة المحفوظة فور فتح الشاشة
  }

  // دالة قراءة اللغة المخزنة في القرص الصلب للهاتف لمنع تصفير القيمة عند إعادة التشغيل
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isArabic = prefs.getBool('is_arabic') ?? true;
    });
  }

  // دالة تبديل اللغة وحفظ الاختيار الجديد بشكل دائم في الذاكرة المحلية
  Future<void> _toggleLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isArabic = !_isArabic;
      prefs.setBool('is_arabic', _isArabic); // تثبيت الاختيار في القرص
    });
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return _buildClientDashboard(context, "مستخدم جديد", user.email ?? "");
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String role = userData['role'] ?? 'client';
        final String name = userData['name'] ?? 'مستخدم';

        // تغليف لوحة التحكم بموجه الاتجاه العالمي لتنقلب الواجهة بالكامل هندسياً حسب اللغة
        return Directionality(
          textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: role == 'admin'
              ? _buildAdminDashboard(context, name, user.email ?? "")
              : (role == 'employee'
              ? _buildEmployeeDashboard(context, name, user.email ?? "")
              : _buildClientDashboard(context, name, user.email ?? "")),
        );
      },
    );
  }
  // 1. لوحة تحكم (مدير النظام) المترجمة بالكامل بالاتخاذ الديناميكي
  Widget _buildAdminDashboard(BuildContext context, String name, String email) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('admin_dashboard', _isArabic)),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          // زر التبديل اللغوي اللحظي التفاعلي والمستدام
          TextButton.icon(
            icon: const Icon(Icons.language, color: Colors.white),
            label: Text(_isArabic ? "English" : "العربية", style: const TextStyle(color: Colors.white)),
            onPressed: _toggleLanguage,
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.admin_panel_settings, size: 80, color: Colors.green),
            const SizedBox(height: 12),
            Text('${_isArabic ? "المدير المسؤول" : "Manager"}: $name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('${AppStrings.get('current_user', _isArabic)}$email', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const Divider(height: 30, thickness: 1),

            _buildDashboardCard(
              icon: Icons.person_add,
              title: AppStrings.get('manage_users', _isArabic),
              subtitle: AppStrings.get('manage_users_sub', _isArabic),
              color: Colors.teal,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const UsersScreen()));
              },
            ),
            const SizedBox(height: 12),
            _buildDashboardCard(
              icon: Icons.people,
              title: AppStrings.get('manage_employees', _isArabic),
              subtitle: AppStrings.get('manage_employees_sub', _isArabic),
              color: Colors.blueGrey,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => EmployeesScreen(isArabic: _isArabic)));
              },
            ),
            const SizedBox(height: 12),
            _buildDashboardCard(
              icon: Icons.assignment,
              title: AppStrings.get('manage_contracts', _isArabic),
              subtitle: AppStrings.get('manage_contracts_sub', _isArabic),
              color: Colors.amber,
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ContractsScreen(userRole: 'admin', currentUserName: name, isArabic: _isArabic))
                );
              },
            ),
            const SizedBox(height: 12),
            _buildDashboardCard(
              icon: Icons.analytics,
              title: AppStrings.get('analytics', _isArabic),
              subtitle: AppStrings.get('analytics_sub', _isArabic),
              color: Colors.purple,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen())),
            ),
          ],
        ),
      ),
    );
  }

  // 2. لوحة تحكم (الموظف التشغيلي) المترجمة والمسجلة
  Widget _buildEmployeeDashboard(BuildContext context, String name, String email) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('employee_dashboard', _isArabic)),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.language), onPressed: _toggleLanguage),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.badge, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 12),
            Text('${_isArabic ? "الموظف" : "Employee"}: $name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('${AppStrings.get('current_user', _isArabic)}$email', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const Divider(height: 30, thickness: 1),
            _buildDashboardCard(
              icon: Icons.shield_outlined,
              title: AppStrings.get('manage_employees', _isArabic),
              subtitle: AppStrings.get('manage_employees_sub', _isArabic),
              color: Colors.blueGrey,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => EmployeesScreen(isArabic: _isArabic)));
              },
            ),
          ],
        ),
      ),
    );
  }

  // 3. بوابة (العميل) المترجمة وثنائية الواجهة والثابتة
  Widget _buildClientDashboard(BuildContext context, String name, String email) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('client_dashboard', _isArabic)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.language), onPressed: _toggleLanguage),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.person, size: 80, color: Colors.indigo),
            const SizedBox(height: 12),
            Text('${_isArabic ? "العميل" : "Client"}: $name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('${AppStrings.get('current_user', _isArabic)}$email', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const Divider(height: 30, thickness: 1),
            _buildDashboardCard(
              icon: Icons.account_balance_wallet,
              title: AppStrings.get('manage_contracts', _isArabic),
              subtitle: AppStrings.get('manage_contracts_sub', _isArabic),
              color: Colors.indigo,
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ContractsScreen(userRole: 'client', currentUserName: name, isArabic: _isArabic))
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          radius: 24,
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
