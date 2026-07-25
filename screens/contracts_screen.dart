import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../main.dart';

class ContractsScreen extends StatefulWidget {
  final String userRole;   // استقبال رتبة المستخدم الحالي
  final String currentUserName; // استقبال الاسم الصريح للمستخدم الحالي

  const ContractsScreen({super.key, required this.userRole, required this.currentUserName});

  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> {
  String? _selectedClientName;
  final _facilityNameController = TextEditingController(); // متحكم اسم المنشأة الجديد
  final _contractValueController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _facilityNameController.dispose();
    _contractValueController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<Uint8List> _buildPdfBytes(String clientName, String facility, String value, String details) async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(30),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blueGrey, width: 2)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(child: pw.Text('وثيقة عقد حماية وأمن رقمي', style: pw.TextStyle(font: arabicFontBold, fontSize: 24))),
                  pw.SizedBox(height: 10),
                  pw.Divider(thickness: 2),
                  pw.SizedBox(height: 30),
                  pw.Text('الطرف الأول: شركة الحماية والأمن المتكاملة', style: pw.TextStyle(font: arabicFont, fontSize: 14)),
                  pw.SizedBox(height: 10),
                  pw.Text('الطرف الثاني (العميل): $clientName', style: pw.TextStyle(font: arabicFont, fontSize: 14)),
                  pw.SizedBox(height: 10),
                  pw.Text('المنشأة المستهدفة بالتغطية: $facility', style: pw.TextStyle(font: arabicFont, fontSize: 14)),
                  pw.SizedBox(height: 20),
                  pw.Text('قيمة العقد السنوية المتفق عليها: $value ريال سعودي', style: pw.TextStyle(font: arabicFont, fontSize: 14)),
                  pw.SizedBox(height: 20),
                  pw.Text('تفاصيل ونطاق الحماية الميدانية:', style: pw.TextStyle(font: arabicFontBold, fontSize: 14)),
                  pw.SizedBox(height: 5),
                  pw.Text(details, style: pw.TextStyle(font: arabicFont, fontSize: 12)),
                  pw.SizedBox(height: 50),
                  pw.Divider(),
                  pw.Center(child: pw.Text('مستند رقمي معتمد سحابياً عبر نظام الحماية', style: pw.TextStyle(font: arabicFont, fontSize: 10))),
                ],
              ),
            ),
          );
        },
      ),
    );
    return pdf.save();
  }

  Future<void> _saveContract() async {
    if (_selectedClientName == null || _facilityNameController.text.isEmpty || _contractValueController.text.isEmpty || _detailsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار العميل وإدخال المنشأة وتعبئة المتطلبات'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() { _isSaving = true; });

    try {
      String clientName = _selectedClientName!;
      String facilityName = _facilityNameController.text.trim();
      String contractValue = _contractValueController.text.trim();
      String contractDetails = _detailsController.text.trim();

      await FirebaseFirestore.instance.collection('contracts').add({
        'clientName': clientName,
        'facilityName': facilityName, // حفظ اسم المنشأة المستهدفة سحابياً
        'value': contractValue,
        'details': contractDetails,
        'startDate': FieldValue.serverTimestamp(),
      });

      await AppLogger.logActivity(
        action: 'تسجيل عقد رقمي',
        details: 'تم إبرام عقد للعميل: $clientName منشأة: $facilityName بقيمة: $contractValue ريال',
        userEmail: FirebaseAuth.instance.currentUser?.email ?? 'المسؤول المالي',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل وحفظ العقد السحابي بنجاح!'), backgroundColor: Colors.green),
        );
        setState(() { _selectedClientName = null; });
        _facilityNameController.clear();
        _contractValueController.clear();
        _detailsController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء حفظ العقد: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) { setState(() { _isSaving = false; }); }
    }
  }
  Future<void> _generateLocalPdfPreview(String clientName, String facility, String value, String details) async {
    if (clientName.isEmpty) return;
    setState(() { _isSaving = true; });
    try {
      Uint8List pdfBytes = await _buildPdfBytes(clientName, facility, value, details);
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes, name: 'عقد_حماية_$clientName.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء توليد المعاينة: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) { setState(() { _isSaving = false; }); }
    }
  }


  // دالة تحديد تدفق البيانات (Stream Query) بناءً على صلاحية الحساب المفتوح
  Stream<QuerySnapshot> _getContractsStream() {
    if (widget.userRole == 'admin') {
      // المدير يرى كافة عقود المنشآت بدون قيود
      return FirebaseFirestore.instance.collection('contracts').orderBy('startDate', descending: true).snapshots();
    } else {
      // الحماية والسرية: العميل يرى فقط العقود التي تطابق اسمه الصريح المسجل بالـ Firestore
      return FirebaseFirestore.instance
          .collection('contracts')
          .where('clientName', isEqualTo: widget.currentUserName)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة واستعراض العقود الرقمية'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // حجب نموذج الإدخال والأزرار الإدارية بالكامل عن واجهة العميل وإظهارها فقط للمدير
            if (widget.userRole == 'admin') ...[
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'client').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return  DropdownButtonFormField(items: [], onChanged: null, decoration: InputDecoration(labelText: 'جاري تحميل قائمة العملاء...', border: OutlineInputBorder()));
                  }
                  final clientDocs = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: _selectedClientName,
                    decoration: const InputDecoration(labelText: 'اختر اسم العميل المسؤول', border: OutlineInputBorder()),
                    items: clientDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      String name = data['name'] ?? '';
                      return DropdownMenuItem<String>(value: name, child: Text(name));
                    }).toList(),
                    onChanged: (value) { setState(() { _selectedClientName = value; }); },
                  );
                },
              ),
              const SizedBox(height: 10),
              TextField(controller: _facilityNameController, decoration: const InputDecoration(labelText: 'اسم المنشأة المستهدفة بالتغطية الأمنية', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: _contractValueController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قيمة العقد الإجمالية', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: _detailsController, maxLines: 3, decoration: const InputDecoration(labelText: 'شروط وبنود التغطية الأمنية', border: OutlineInputBorder())),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('حفظ سحابياً'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: _isSaving ? null : _saveContract,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('توليد PDF مسبق'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: _isSaving ? null : () => _generateLocalPdfPreview(_selectedClientName ?? '', _facilityNameController.text, _contractValueController.text, _detailsController.text),
                    ),
                  ),
                ],
              ),
              const Divider(height: 30, thickness: 2),
            ],

            const Text('أرشيف المستندات والتعاقدات الحية:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getContractsStream(), // استدعاء البث المفلتر أمنياً
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return const Center(child: Text('لا توجد عقود مسجلة بالنظام حالياً تتبع صلاحيتك.'));

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      String cName = data['clientName'] ?? '';
                      String fName = data['facilityName'] ?? 'منشأة عامة';
                      String cValue = data['value'] ?? '0';
                      String cDetails = data['details'] ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          leading: const Icon(Icons.gavel, color: Colors.amber),
                          title: Text('$cName - ($fName)'), // دمج اسم العميل مع منشأته في بطاقة العرض
                          subtitle: Text('القيمة: $cValue ريال \nالبنود: $cDetails'),
                          trailing: IconButton(
                            icon: const Icon(Icons.print, color: Colors.blueGrey),
                            onPressed: () => _generateLocalPdfPreview(cName, fName, cValue, cDetails),
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
