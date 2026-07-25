import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'employees_screen.dart';
import 'contracts_screen.dart';
import 'users_screen.dart';
import 'analytics_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

        if (role == 'admin') {
          return _buildAdminDashboard(context, name, user.email ?? "");
        } else if (role == 'employee') {
          return _buildEmployeeDashboard(context, name, user.email ?? "");
        } else {
          return _buildClientDashboard(context, name, user.email ?? "");
        }
      },
    );
  }

  // 1. لوحة تحكم (مدير النظام) - صلاحيات كاملة
  Widget _buildAdminDashboard(BuildContext context, String name, String email) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم مدير النظام'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.admin_panel_settings, size: 80, color: Colors.green),
            const SizedBox(height: 12),
            Text('المدير المسؤول: $name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('الحساب الحالي: $email', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const Divider(height: 30, thickness: 1),

            _buildDashboardCard(
              icon: Icons.person_add,
              title: 'إدارة حسابات وصلاحيات النظام',
              subtitle: 'إضافة مستخدمين جدد وتحديد أدوارهم السحابية وقدرة الحذف والتعديل',
              color: Colors.teal,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const UsersScreen()));
              },
            ),
            const SizedBox(height: 12),
            _buildDashboardCard(
              icon: Icons.people,
              title: 'إدارة موظفي الأمن',
              subtitle: 'إضافة الحراس الميدانيين وتحديث ومسح مواقع نوباتهم سحابياً',
              color: Colors.blueGrey,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EmployeesScreen()));
              },
            ),
            const SizedBox(height: 12),
            _buildDashboardCard(
              icon: Icons.assignment,
              title: 'إدارة العقود والمدفوعات (PDF)',
              subtitle: 'تسجيل العقود والمنشآت وتوليد ملفات الـ PDF مع شريط البحث المتقدم',
              color: Colors.amber,
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ContractsScreen(userRole: 'admin', currentUserName: name))
                );
              },
            ),
            const SizedBox(height: 12),
            _buildDashboardCard(
              icon: Icons.analytics,
              title: 'لوحة الإحصائيات والتقارير التفاعلية',
              subtitle: 'حساب قيم العقود السنوية وأعداد الحراس الميدانيين تلقائياً وبسرعة',
              color: Colors.purple,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  // 2. لوحة تحكم (الموظف التشغيلي) - يرى فقط شاشة الموظفين
  Widget _buildEmployeeDashboard(BuildContext context, String name, String email) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الموظف التشغيلية'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.badge, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 12),
            Text('مرحباً بك الموظف: $name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('الحساب الحالي: $email', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const Divider(height: 30, thickness: 1),
            _buildDashboardCard(
              icon: Icons.shield_outlined,
              title: 'استعراض الحراس وتوزيع نوبات الأمن الميدانية',
              subtitle: 'متابعة شؤون الموظفين وتنظيم العمل وتوزيع المهام المخصصة لك',
              color: Colors.blueGrey,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EmployeesScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  // 3. بوابة العميل الرقمية - يرى فواتيره وعقوده المفلترة باسمه فقط
  Widget _buildClientDashboard(BuildContext context, String name, String email) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بوابة العميل الرقمية'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.person, size: 80, color: Colors.indigo),
            const SizedBox(height: 12),
            Text('أهلاً بك العميل: $name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('الحساب الحالي: $email', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const Divider(height: 30, thickness: 1),
            _buildDashboardCard(
              icon: Icons.account_balance_wallet,
              title: 'استعراض فواتيري وعقودي الأمنية (PDF)',
              subtitle: 'الاطلاع الآمن على الفواتير، وحالة الدفع الحالية، والطباعة الفورية للفواتير',
              color: Colors.indigo,
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ContractsScreen(userRole: 'client', currentUserName: name))
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
