import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../utils/app_strings.dart';

class UsersScreen extends StatefulWidget {
  final bool isArabic; // استقبال حالة اللغة النشطة من الشاشة الرئيسية

  const UsersScreen({super.key, required this.isArabic});

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

  // 1. عملية الإضافة المعزولة والمترجمة بالكامل وتدوين النشاط سحابياً
  Future<void> _createUserAccount() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppStrings.get('alert_fill_fields', widget.isArabic)),
            backgroundColor: Colors.orange
        ),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final String currentAdminEmail = FirebaseAuth.instance.currentUser?.email ?? 'admin@security.com';
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

      await AppLogger.logActivity(
        action: widget.isArabic ? 'إنشاء حساب جديد' : 'Create New Account',
        details: widget.isArabic
            ? 'تم إنشاء حساب للمسجل: ${_nameController.text.trim()} بصلاحية: $_selectedRole'
            : 'Created account for user: ${_nameController.text.trim()} with role: $_selectedRole',
        userEmail: currentAdminEmail,
      );

      _showSuccessAndClear();

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

        await AppLogger.logActivity(
          action: widget.isArabic ? 'إنشاء حساب جديد' : 'Create New Account',
          details: widget.isArabic
              ? 'تم إنشاء حساب للمسجل: ${_nameController.text.trim()} بصلاحية: $_selectedRole'
              : 'Created account for user: ${_nameController.text.trim()} with role: $_selectedRole',
          userEmail: currentAdminEmail,
        );
        _showSuccessAndClear();
      } else {
        debugPrint('🚨 خطأ في النظام: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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

  // 2. عملية التعديل المترجمة وتحديث رتب وصلاحيات الحسابات
  Future<void> _updateUserRole(String docId, String newRole, String userName) async {
    final String currentAdminEmail = FirebaseAuth.instance.currentUser?.email ?? 'admin@security.com';
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'role': newRole,
      });
      await AppLogger.logActivity(
        action: widget.isArabic ? 'تعديل صلاحية مستخدم' : 'Modify User Role',
        details: widget.isArabic
            ? 'تم تعديل صلاحية الحساب ($userName) إلى [$newRole]'
            : 'Modified account permission for ($userName) to [$newRole]',
        userEmail: currentAdminEmail,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isArabic ? 'تم تحديث صلاحية الحساب بنجاح!' : 'Account role updated successfully!'),
              backgroundColor: Colors.blue
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 3. عملية الحذف المترجمة والموثقة بسجل العمليات الإدارية
  Future<void> _deleteUser(String docId, String userName) async {
    final String currentAdminEmail = FirebaseAuth.instance.currentUser?.email ?? 'admin@security.com';
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).delete();
      await AppLogger.logActivity(
        action: widget.isArabic ? 'حذف حساب مستخدم' : 'Delete User Account',
        details: widget.isArabic
            ? 'تم مسح وإيقاف حساب المستخدم ($userName) بالكامل من النظام'
            : 'Deleted and deactivated account for user ($userName) from the system',
        userEmail: currentAdminEmail,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isArabic ? 'تم حذف الحساب من النظام بنجاح!' : 'User account removed successfully!'),
              backgroundColor: Colors.redAccent
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  // نافذة تعديل الرتب المنبثقة المترجمة بالكامل
  void _showEditRoleDialog(String docId, String currentRole, String userName) {
    String roleToUpdate = currentRole;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
              widget.isArabic ? 'تعديل صلاحية المستخدم' : 'Edit User Permissions',
              textAlign: widget.isArabic ? TextAlign.right : TextAlign.left
          ),
          content: DropdownButtonFormField<String>(
            value: roleToUpdate,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [
              DropdownMenuItem(value: 'admin', child: Text(widget.isArabic ? 'مدير نظام' : 'System Admin')),
              DropdownMenuItem(value: 'employee', child: Text(widget.isArabic ? 'موظف / مراقب' : 'Operational Employee')),
              DropdownMenuItem(value: 'client', child: Text(widget.isArabic ? 'عميل / منشأة' : 'Corporate Client')),
            ],
            onChanged: (value) {
              setDialogState(() { roleToUpdate = value!; });
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.get('cancel', widget.isArabic))),
            ElevatedButton(
              onPressed: () {
                _updateUserRole(docId, roleToUpdate, userName);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text(AppStrings.get('update', widget.isArabic), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessAndClear() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.isArabic ? 'تم تسجيل الحساب الجديد وتفعيل صلاحياته بنجاح!' : 'New account created successfully!'),
            backgroundColor: Colors.green
        ),
      );
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    // تغليف واجهة الصلاحيات بالكامل بموجه اتجاه النصوص لتنقلب الواجهة تلقائياً
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('manage_users', widget.isArabic)),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                      labelText: widget.isArabic ? 'الاسم الكامل للمستخدم الجديد' : 'Full Name for New User',
                      border: const OutlineInputBorder()
                  )
              ),
              const SizedBox(height: 10),
              TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                      labelText: widget.isArabic ? 'البريد الإلكتروني المعتمد للعمل' : 'Authorized Corporate Email',
                      border: const OutlineInputBorder()
                  )
              ),
              const SizedBox(height: 10),
              TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: widget.isArabic ? 'كلمة المرور الافتراضية' : 'Default Security Password',
                      border: const OutlineInputBorder()
                  )
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(labelText: widget.isArabic ? 'تحديد صلاحية وفئة الحساب' : 'Select Cloud Account Role', border: const OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: 'admin', child: Text(widget.isArabic ? 'مدير نظام (صلاحيات كاملة)' : 'System Admin (Full Access)')),
                  DropdownMenuItem(value: 'employee', child: Text(widget.isArabic ? 'موظف / مراقب أمني ميداني' : 'Field Security Employee')),
                  DropdownMenuItem(value: 'client', child: Text(widget.isArabic ? 'عميل / صاحب منشأة مستهدفة' : 'Corporate Client Account')),
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
                    : Text(widget.isArabic ? 'إنشاء وتفعيل الحساب سحابياً' : 'Deploy & Activate Cloud Account', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 30, thickness: 2),
              Text(widget.isArabic ? 'أرشيف وقائمة مستخدمي النظام الحاليين:' : 'Current System Accounts Archive:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) return Center(child: Text(widget.isArabic ? 'لا يوجد مستخدمون مسجلون بالنظام حالياً.' : 'No users registered in the system yet.'));

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        String docId = docs[index].id;
                        String userRole = data['role'] ?? 'client';
                        String uName = data['name'] ?? 'User';

                        IconData roleIcon = userRole == 'admin' ? Icons.admin_panel_settings : (userRole == 'employee' ? Icons.badge : Icons.person);
                        Color roleColor = userRole == 'admin' ? Colors.green : (userRole == 'employee' ? Colors.blueGrey : Colors.indigo);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            leading: Icon(roleIcon, color: roleColor, size: 30),
                            title: Text(uName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${widget.isArabic ? "البريد: " : "Email: "}${data['email']} \n${widget.isArabic ? "الصلاحية: " : "Role: "}${userRole.toUpperCase()}'),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showEditRoleDialog(docId, userRole, uName),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _deleteUser(docId, uName),
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
      ),
    );
  }
}
