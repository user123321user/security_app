import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart'; // This exact line links the screen to the AppLogger in main.dart

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'employee';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 1. عملية الإضافة: دالة إنشاء مستخدم جديد المعزولة والمحكمة سحابياً
  Future<void> _createUserAccount() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تعبئة جميع معلومات الحساب الجديد'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final String temporaryDocId = FirebaseFirestore.instance.collection('users').doc().id;
    String temporaryAppName = 'IsolatedAuth_${DateTime.now().millisecondsSinceEpoch}';
    FirebaseApp? isolatedApp;

    try {
      await FirebaseFirestore.instance.collection('users').doc(temporaryDocId).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      isolatedApp = await Firebase.initializeApp(
          name: temporaryAppName, options: Firebase.app().options);

      UserCredential credential = await FirebaseAuth.instanceFor(app: isolatedApp)
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (credential.user != null) {
        String realUid = credential.user!.uid;

        await FirebaseFirestore.instance.collection('users').doc(realUid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance.collection('users').doc(temporaryDocId).delete();
      }

      // [المكان الدقيق]: ضع هذا السطر فوق سطر _showSuccessAndClear(); مباشرة داخل بلوك try
      await AppLogger.logActivity(
        action: 'إنشاء حساب جديد',
        details: 'تم إنشاء حساب للمسجل: ${_nameController.text.trim()} بصلاحية: $_selectedRole',
        userEmail: FirebaseAuth.instance.currentUser?.email ?? 'مدير النظام',
      );

      _showSuccessAndClear(); // هذا السجل القديم الموجود في ملفك

    } catch (e) {
      if (e.toString().contains('PigeonUserDetails')) {
        try {
          final authForApp = FirebaseAuth.instanceFor(app: isolatedApp!);
          if (authForApp.currentUser != null) {
            String realUid = authForApp.currentUser!.uid;
            await FirebaseFirestore.instance.collection('users').doc(realUid).set({
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'role': _selectedRole,
              'createdAt': FieldValue.serverTimestamp(),
            });
            await FirebaseFirestore.instance.collection('users').doc(temporaryDocId).delete();
          }
        } catch (_) {}
        _showSuccessAndClear();
      } else {
        debugPrint('🚨 خطأ في النظام: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل إنشاء الحساب: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      if (isolatedApp != null) {
        await isolatedApp.delete();
      }
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }
  // 2. عملية التعديل: دالة تحديث دور وصلاحية مستخدم حالي في السحاب
  Future<void> _updateUserRole(String docId, String newRole) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'role': newRole,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث صلاحية الحساب بنجاح!'), backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء التحديث: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 3. عملية الحذف: دالة مسح مستند المستخدم من أرشيف الـ Firestore
  Future<void> _deleteUser(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الحساب من النظام بنجاح!'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء الحذف: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // نافذة منبثقة لتغيير رتبة المستخدم ديناميكياً
  void _showEditRoleDialog(String docId, String currentRole) {
    String roleToUpdate = currentRole;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل صلاحية المستخدم', textAlign: TextAlign.right),
          content: DropdownButtonFormField<String>(
            value: roleToUpdate,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'admin', child: Text('مدير نظام')),
              DropdownMenuItem(value: 'employee', child: Text('موظف / مراقب')),
              DropdownMenuItem(value: 'client', child: Text('عميل / منشأة')),
            ],
            onChanged: (value) {
              setDialogState(() { roleToUpdate = value!; });
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                _updateUserRole(docId, roleToUpdate);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('تحديث الصلاحية', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessAndClear() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الحساب الجديد وتفعيل صلاحياته بنجاح!'), backgroundColor: Colors.green),
      );
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة حسابات وصلاحيات النظام'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل للمستخدم الجديد', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني المعتمد للعمل', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الافتراضية', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'تحديد صلاحية وفئة الحساب', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('مدير نظام (صلاحيات إشرافية كاملة)')),
                DropdownMenuItem(value: 'employee', child: Text('موظف / مراقب أمني ميداني')),
                DropdownMenuItem(value: 'client', child: Text('عميل / صاحب منشأة مستهدفة')),
              ],
              onChanged: (value) {
                setState(() { _selectedRole = value!; });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _createUserAccount,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.teal, foregroundColor: Colors.white),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('إنشاء وتفعيل الحساب سحابياً', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 40, thickness: 2),
            const Text('أرشيف وقائمة مستخدمي النظام الحاليين:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return const Center(child: Text('لا يوجد مستخدمون مسجلون بالنظام حالياً.'));

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      String docId = docs[index].id;
                      String userRole = data['role'] ?? 'client';

                      IconData roleIcon = userRole == 'admin' ? Icons.admin_panel_settings : (userRole == 'employee' ? Icons.badge : Icons.person);
                      Color roleColor = userRole == 'admin' ? Colors.green : (userRole == 'employee' ? Colors.blueGrey : Colors.indigo);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          leading: Icon(roleIcon, color: roleColor, size: 30),
                          title: Text(data['name'] ?? 'بدون اسم', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('البريد: ${data['email']} \nالصلاحية: ${userRole.toUpperCase()}'),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEditRoleDialog(docId, userRole),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _deleteUser(docId),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
