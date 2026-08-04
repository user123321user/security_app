import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../utils/app_strings.dart'; // استيراد كلاس الترجمة المركزي

class EmployeesScreen extends StatefulWidget {
  final bool isArabic; // استقبال حالة اللغة النشطة من الشاشة الرئيسية

  const EmployeesScreen({super.key, required this.isArabic});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  String? _selectedEmployeeName;
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSaving = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _locationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 1. عملية الإضافة المترجمة وتدوين النشاط سحابياً
  Future<void> _saveEmployee() async {
    if (_selectedEmployeeName == null || _phoneController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppStrings.get('alert_fill_fields', widget.isArabic)),
            backgroundColor: Colors.orange
        ),
      );
      return;
    }

    setState(() { _isSaving = true; });
    final String currentLoggedEmail = FirebaseAuth.instance.currentUser?.email ?? 'Guard Manager';

    try {
      await FirebaseFirestore.instance.collection('employees').add({
        'name': _selectedEmployeeName,
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      await AppLogger.logActivity(
        action: widget.isArabic ? 'تعيين نوبة عمل' : 'Assign Guard Shift',
        details: widget.isArabic
            ? 'تم تعيين نوبة للحارس: $_selectedEmployeeName في موقع: ${_locationController.text.trim()}'
            : 'Assigned shift for guard: $_selectedEmployeeName at location: ${_locationController.text.trim()}',
        userEmail: currentLoggedEmail,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isArabic ? 'تم حفظ بيانات الموظف بنجاح!' : 'Guard shift assigned successfully!'),
              backgroundColor: Colors.green
          ),
        );
        setState(() { _selectedEmployeeName = null; });
        _phoneController.clear();
        _locationController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) { setState(() { _isSaving = false; }); }
    }
  }

  // 2. عملية التعديل المترجمة والمغلقة تماماً بدون اختصارات
  Future<void> _updateEmployeeShift(String docId, String phone, String location, String name) async {
    final String currentLoggedEmail = FirebaseAuth.instance.currentUser?.email ?? 'Guard Manager';
    try {
      await FirebaseFirestore.instance.collection('employees').doc(docId).update({
        'phone': phone.trim(),
        'location': location.trim(),
      });
      await AppLogger.logActivity(
        action: widget.isArabic ? 'تعديل نوبة عمل' : 'Modify Guard Shift',
        details: widget.isArabic
            ? 'تم تحديث هاتف وموقع الحارس ($name) إلى موقع [$location]'
            : 'Updated phone and location for guard ($name) to [$location]',
        userEmail: currentLoggedEmail,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isArabic ? 'تم تحديث بيانات النوبة بنجاح!' : 'Shift updated successfully!'),
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
  // 3. عملية الحذف المترجمة والمغلقة بالكامل لتوثيق السجل
  Future<void> _deleteEmployeeShift(String docId, String name) async {
    final String currentLoggedEmail = FirebaseAuth.instance.currentUser?.email ?? 'Guard Manager';
    try {
      await FirebaseFirestore.instance.collection('employees').doc(docId).delete();
      await AppLogger.logActivity(
        action: widget.isArabic ? 'حذف نوبة عمل' : 'Delete Guard Shift',
        details: widget.isArabic
            ? 'تم إنهاء ومسح نوبة العمل الخاصة بالحارس ($name) بنجاح'
            : 'Ended and deleted the security shift for guard ($name) successfully',
        userEmail: currentLoggedEmail,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isArabic ? 'تم حذف نوبة العمل المنتهية بنجاح!' : 'Completed guard shift removed successfully!'),
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

  // نافذة تعديل البيانات المنبثقة ثنائية اللغة
  void _showEditShiftDialog(String docId, String name, String currentPhone, String currentLocation) {
    final editPhoneController = TextEditingController(text: currentPhone);
    final editLocationController = TextEditingController(text: currentLocation);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            '${AppStrings.get('edit_shift_title', widget.isArabic)}$name',
            textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: editPhoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: AppStrings.get('phone_label', widget.isArabic))),
            const SizedBox(height: 10),
            TextField(controller: editLocationController, decoration: InputDecoration(labelText: AppStrings.get('location_label', widget.isArabic))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.get('cancel', widget.isArabic))),
          ElevatedButton(
            onPressed: () {
              if (editPhoneController.text.isNotEmpty && editLocationController.text.isNotEmpty) {
                _updateEmployeeShift(docId, editPhoneController.text, editLocationController.text, name);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text(AppStrings.get('update', widget.isArabic), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // تغليف الشاشة بالكامل بموجه اتجاه النصوص لتنقلب الواجهة هندسياً تلقائياً
    return Directionality(
        textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
        appBar: AppBar(
        title: Text(AppStrings.get('manage_employees', widget.isArabic)),
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
    return DropdownButtonFormField(items: [], onChanged: null, decoration: InputDecoration(labelText: AppStrings.get('loading_guards', widget.isArabic), border: const OutlineInputBorder()));
    }
    final employeeDocs = snapshot.data!.docs;
    return DropdownButtonFormField<String>(
    value: _selectedEmployeeName,
    decoration: InputDecoration(labelText: AppStrings.get('select_guard', widget.isArabic), border: const OutlineInputBorder()),
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
    TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: AppStrings.get('phone_label', widget.isArabic), border: const OutlineInputBorder())),
    const SizedBox(height: 10),
    TextField(controller: _locationController, decoration: InputDecoration(labelText: AppStrings.get('location_label', widget.isArabic), border: const OutlineInputBorder())),
    const SizedBox(height: 15),
    ElevatedButton(
    onPressed: _isSaving ? null : _saveEmployee,
    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.green, foregroundColor: Colors.white),
    child: _isSaving
    ? const CircularProgressIndicator(color: Colors.white)
        : Text(AppStrings.get('btn_save_shift', widget.isArabic), style: const TextStyle(fontSize: 16)),
    ),
    const Divider(height: 20, thickness: 2),

    // شريط البحث والفلترة اللحظية المترجم بالكامل لغوياً
    TextField(
    controller: _searchController,
    decoration: InputDecoration(
    labelText: AppStrings.get('search_guard_placeholder', widget.isArabic),
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

    Text(AppStrings.get('shift_archive', widget.isArabic), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    const SizedBox(height: 10),
    Expanded(
    child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('employees').orderBy('timestamp', descending: true).snapshots(),
    builder: (context, snapshot) {
    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

    final filteredDocs = snapshot.data!.docs.where((doc) {
    final data = doc.data() as Map<String, dynamic>;
    String empName = (data['name'] ?? '').toString().toLowerCase();
    String empLocation = (data['location'] ?? '').toString().toLowerCase();
    return empName.contains(_searchQuery) || empLocation.contains(_searchQuery);
    }).toList();

    if (filteredDocs.isEmpty) return Center(child: Text(AppStrings.get('no_shifts', widget.isArabic)));

    return ListView.builder(
    itemCount: filteredDocs.length,
    itemBuilder: (context, index) {
    final data = filteredDocs[index].data() as Map<String, dynamic>;
    String docId = filteredDocs[index].id;
    String empName = data['name'] ?? 'Guard';
    String empPhone = data['phone'] ?? '';
    String empLocation = data['location'] ?? '';

    return Card(
    margin: const EdgeInsets.symmetric(vertical: 5),
    child: ListTile(
    leading: const Icon(Icons.shield, color: Colors.blueGrey, size: 30),
    title: Text(empName, style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text('${AppStrings.get('phone_short', widget.isArabic)}$empPhone \n${AppStrings.get('location_short', widget.isArabic)}$empLocation'),
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
        ),);}}