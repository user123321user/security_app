import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../main.dart';

class ContractsScreen extends StatefulWidget {
  final String userRole;
  final String currentUserName;

  const ContractsScreen({super.key, required this.userRole, required this.currentUserName});

  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> {
  String? _selectedClientName;
  final _facilityNameController = TextEditingController();
  final _contractValueController = TextEditingController();
  final _detailsController = TextEditingController();
  final _searchController = TextEditingController();
  String _selectedPaymentStatus = 'قيد الانتظار';
  String _searchQuery = '';
  bool _isSaving = false;

  @override
  void dispose() {
    _facilityNameController.dispose();
    _contractValueController.dispose();
    _detailsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // محرك توليد بايتات الـ PDF محلياً في الذاكرة دون استهلاك مساحات سحابية
  Future<Uint8List> _buildPdfBytes(String clientName, String facility, String value, String details, String paymentStatus) async {
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
                  pw.Text('حالة الفاتورة والمدفوعات الحالية: $paymentStatus', style: pw.TextStyle(font: arabicFontBold, fontSize: 14, color: paymentStatus == 'مدفوع' ? PdfColors.green : PdfColors.red)),
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

  // دالة حفظ العقد والوضعية المالية وتدوين الحركة في السجل
  Future<void> _saveContract() async {
    if (_selectedClientName == null || _facilityNameController.text.isEmpty || _contractValueController.text.isEmpty || _detailsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار العميل وإدخال المنشأة وتعبئة المتطلبات'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() { _isSaving = true; });
    final String currentAdminEmail = FirebaseAuth.instance.currentUser?.email ?? 'admin@security.com';

    try {
      String clientName = _selectedClientName!;
      String facilityName = _facilityNameController.text.trim();
      String contractValue = _contractValueController.text.trim();
      String contractDetails = _detailsController.text.trim();

      await FirebaseFirestore.instance.collection('contracts').add({
        'clientName': clientName,
        'facilityName': facilityName,
        'value': contractValue,
        'details': contractDetails,
        'paymentStatus': _selectedPaymentStatus,
        'startDate': FieldValue.serverTimestamp(),
      });

      await AppLogger.logActivity(
        action: 'تسجيل عقد مالي',
        details: 'تم إبرام عقد للعميل: $clientName منشأة: $facilityName بقيمة: $contractValue ريال وحالتها [$_selectedPaymentStatus]',
        userEmail: currentAdminEmail,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل وحفظ العقد والوضعية المالية بنجاح!'), backgroundColor: Colors.green),
        );
        setState(() { _selectedClientName = null; _selectedPaymentStatus = 'قيد الانتظار'; });
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

  // دالة تحديث حالة السداد الفاتورية فوريّاً وتدوينها أمنياً
  Future<void> _togglePaymentStatus(String docId, String currentStatus) async {
    String newStatus = currentStatus == 'مدفوع' ? 'قيد الانتظار' : 'مدفوع';
    final String currentAdminEmail = FirebaseAuth.instance.currentUser?.email ?? 'admin@security.com';
    try {
      await FirebaseFirestore.instance.collection('contracts').doc(docId).update({
        'paymentStatus': newStatus,
      });
      await AppLogger.logActivity(
        action: 'تحديث حالة دفع',
        details: 'تم تغيير حالة دفع المستند رقم ($docId) إلى [$newStatus]',
        userEmail: currentAdminEmail,
      );
    } catch (e) {
      debugPrint('🚨 خطأ في تحديث الفاتورة: $e');
    }
  }
  Future<void> _generateLocalPdfPreview(String clientName, String facility, String value, String details, String paymentStatus) async {
    if (clientName.isEmpty) return;
    setState(() { _isSaving = true; });
    try {
      Uint8List pdfBytes = await _buildPdfBytes(clientName, facility, value, details, paymentStatus);
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes, name: 'عقد_حماية_$clientName.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء المعاينة: $e'), backgroundColor: Colors.red),
        );
      }
    } finally { if (mounted) { setState(() { _isSaving = false; }); } }
  }

  // آلية الفلترة السحابية: المدير يرى الكل، والعميل يرى فواتيره الخاصة فقط
  Stream<QuerySnapshot> _getContractsStream() {
    if (widget.userRole == 'admin') {
      return FirebaseFirestore.instance.collection('contracts').orderBy('startDate', descending: true).snapshots();
    } else {
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
        title: const Text('إدارة واستعراض العقود والمدفوعات'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
              TextField(controller: _detailsController, maxLines: 2, decoration: const InputDecoration(labelText: 'شروط وبنود التغطية الأمنية', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedPaymentStatus,
                decoration: const InputDecoration(labelText: 'تحديد وضعية حالة الدفع الأولية', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'قيد الانتظار', child: Text('قيد الانتظار (لم يتم السداد)')),
                  DropdownMenuItem(value: 'مدفوع', child: Text('مدفوع (تم السداد بالكامل)')),
                ],
                onChanged: (value) { setState(() { _selectedPaymentStatus = value!; }); },
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('حفظ العقد والمالية سحابياً'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: _isSaving ? null : _saveContract,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 2),
            ],

            // شريط البحث المتقدم والفلترة الفورية للعقود والفواتير الحية
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                  labelText: 'ابحث باسم العميل أو اسم المنشأة المستهدفة...',
                  prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
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

            const Text('أرشيف الفواتير والتعاقدات المالية الحية:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getContractsStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  // تصفية الكروت فورياً بالخلفية بناءً على نص حقل البحث المكتوب
                  final filteredDocs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    String clientName = (data['clientName'] ?? '').toString().toLowerCase();
                    String facilityName = (data['facilityName'] ?? '').toString().toLowerCase();
                    return clientName.contains(_searchQuery) || facilityName.contains(_searchQuery);
                  }).toList();

                  if (filteredDocs.isEmpty) return const Center(child: Text('لا توجد نتائج مطابقة لبحثك أو صلاحيتك الحالية.'));

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final data = filteredDocs[index].data() as Map<String, dynamic>;
                      String docId = filteredDocs[index].id;
                      String cName = data['clientName'] ?? '';
                      String fName = data['facilityName'] ?? 'منشأة عامة';
                      String cValue = data['value'] ?? '0';
                      String cDetails = data['details'] ?? '';
                      String pStatus = data['paymentStatus'] ?? 'قيد الانتظار';

                      Color statusColor = pStatus == 'مدفوع' ? Colors.green : Colors.red;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withOpacity(0.1),
                            child: Icon(pStatus == 'مدفوع' ? Icons.check_circle : Icons.pending, color: statusColor),
                          ),
                          title: Text('$cName - ($fName)'),
                          subtitle: Text('القيمة: $cValue ريال \nحالة الفاتورة: $pStatus'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.userRole == 'admin')
                                IconButton(
                                  icon: const Icon(Icons.published_with_changes, color: Colors.blueGrey),
                                  onPressed: () => _togglePaymentStatus(docId, pStatus),
                                ),
                              IconButton(
                                icon: const Icon(Icons.print, color: Colors.blueGrey),
                                onPressed: () => _generateLocalPdfPreview(cName, fName, cValue, cDetails, pStatus),
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
