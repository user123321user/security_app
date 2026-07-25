import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart'; // ربط كلاس السجلات المركزي

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  String? _selectedEmployeeName;
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _searchController = TextEditingController(); // متحكم شريط البحث
  String _searchQuery = ''; // متغير البحث لحراس الأمن
  bool _isSaving = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _locationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 1. عملية الإضافة: حفظ نوبة حارس جديد سحابياً وتدوين النشاط
  Future<void> _saveEmployee() async {
    if (_selectedEmployeeName == null || _phoneController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار اسم الموظف وتعبئة جميع الحقول'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() { _isSaving = true; });
    final String currentLoggedEmail = FirebaseAuth.instance.currentUser?.email ?? 'مسؤول Nyوبات';

    try {
      await FirebaseFirestore.instance.collection('employees').add({
        'name': _selectedEmployeeName,
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      await AppLogger.logActivity(
        action: 'تعيين نوبة عمل',
        details: 'تم تعيين نوبة للحارس: $_selectedEmployeeName في موقع: ${_locationController.text.trim()}',
        userEmail: currentLoggedEmail,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ بيانات الموظف بنجاح!'), backgroundColor: Colors.green),
        );
        setState(() { _selectedEmployeeName = null; });
        _phoneController.clear();
        _locationController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) { setState(() { _isSaving = false; }); }
    }
  }

  // 2. عملية التعديل: دالة تحديث بيانات ونوبة الحارس السحابية
  Future<void> _updateEmployeeShift(String docId, String phone, String location, String name) async {
    final String currentLoggedEmail = FirebaseAuth.instance.currentUser?.email ?? 'مسؤول النوبات';
    try {
      await FirebaseFirestore.instance.collection('employees').doc(docId).update({
        'phone': phone.trim(),
        'location': location.trim(),
      });
      await AppLogger.logActivity(
        action: 'تعديل نوبة عمل',
        details: 'تم تحديث هاتف وموقع الحارس ($name) إلى موقع [$location]',
        userEmail: currentLoggedEmail,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث بيانات النوبة بنجاح!'), backgroundColor: Colors.blue),
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
  // 3. عملية الحذف: دالة مسح النوبة بعد انتهائها وتدوين الحركة
  Future<void> _deleteEmployeeShift(String docId, String name) async {
    final String currentLoggedEmail = FirebaseAuth.instance.currentUser?.email ?? 'مسؤول النوبات';
    try {
      await FirebaseFirestore.instance.collection('employees').doc(docId).delete();
      await AppLogger.logActivity(
        action: 'حذف نوبة عمل',
        details: 'تم إنهاء ومسح نوبة العمل الخاصة بالحارس ($name) بنجاح',
        userEmail: currentLoggedEmail,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف نوبة العمل المنتهية بنجاح!'), backgroundColor: Colors.redAccent),
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

  void _showEditShiftDialog(String docId, String name, String currentPhone, String currentLocation) {
    final editPhoneController = TextEditingController(text: currentPhone);
    final editLocationController = TextEditingController(text: currentLocation);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل نوبة الحارس: $name', textAlign: TextAlign.right, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: editPhoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'تحديث رقم الهاتف', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: editLocationController, decoration: const InputDecoration(labelText: 'تحديث موقع النوبة المخصص', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (editPhoneController.text.isNotEmpty && editLocationController.text.isNotEmpty) {
                _updateEmployeeShift(docId, editPhoneController.text, editLocationController.text, name);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('تحديث البيانات', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة موظفي الأمن ونوباتهم'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'employee').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return  DropdownButtonFormField(items: [], onChanged: null, decoration: InputDecoration(labelText: 'جاري تحميل قائمة الحراس...', border: OutlineInputBorder()));
                }
                final employeeDocs = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _selectedEmployeeName,
                  decoration: const InputDecoration(labelText: 'اختر اسم حارس الأمن المسجل', border: OutlineInputBorder()),
                  items: employeeDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    String name = data['name'] ?? '';
                    return DropdownMenuItem<String>(value: name, child: Text(name));
                  }).toList(),
                  onChanged: (value) { setState(() { _selectedEmployeeName = value; }); },
                );
              },
            ),
            const SizedBox(height: 10),
            TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف الميداني', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'موقع النوبة المخصص حركياً', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveEmployee,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('إدراج وتوزيع النوبة الأمنية سحابياً', style: TextStyle(fontSize: 16)),
            ),
            const Divider(height: 20, thickness: 2),

            // شريط البحث والفلترة اللحظية لحراس الأمن والمواقع الميدانية
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                  labelText: 'ابحث باسم الحارس أو موقع نوبته الميدانية...',
                  prefixIcon: const Icon(Icons.person_search, color: Colors.blueGrey),
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () { setState(() { _searchController.clear(); _searchQuery = ''; }); })
                      : null
              ),
              onChanged: (value) {
                setState(() { _searchQuery = value.trim().toLowerCase(); });
              },
            ),
            const SizedBox(height: 15),

            const Text('سجل نوبات الحراس الميدانية الحالية:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('employees').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  // تصفية وقص الكروت تلقائياً بناءً على نص حقل البحث المكتوب
                  final filteredDocs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    String empName = (data['name'] ?? '').toString().toLowerCase();
                    String empLocation = (data['location'] ?? '').toString().toLowerCase();
                    return empName.contains(_searchQuery) || empLocation.contains(_searchQuery);
                  }).toList();

                  if (filteredDocs.isEmpty) return const Center(child: Text('لا توجد نوبات عمل مطابقة لبحثك حالياً.'));

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final data = filteredDocs[index].data() as Map<String, dynamic>;
                      String docId = filteredDocs[index].id;
                      String empName = data['name'] ?? 'بدون اسم';
                      String empPhone = data['phone'] ?? '';
                      String empLocation = data['location'] ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          leading: const Icon(Icons.shield, color: Colors.blueGrey, size: 30),
                          title: Text(empName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('الهاتف: $empPhone \nالموقع: $empLocation'),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEditShiftDialog(docId, empName, empPhone, empLocation),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                                onPressed: () => _deleteEmployeeShift(docId, empName),
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
