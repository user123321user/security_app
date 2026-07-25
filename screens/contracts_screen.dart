import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../main.dart';
import '../utils/app_strings.dart';

class ContractsScreen extends StatefulWidget {
  final String userRole;
  final String currentUserName;
  final bool isArabic; // استقبال حالة اللغة النشطة من الشاشة الرئيسية

  const ContractsScreen({
    super.key,
    required this.userRole,
    required this.currentUserName,
    required this.isArabic,
  });

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

  // محرك بناء الـ PDF ثنائي اللغة بالكامل ومغلق برمجياً بنسبة 100%
  Future<Uint8List> _buildPdfBytes(String clientName, String facility, String value, String details, String paymentStatus) async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    String translatedStatus = paymentStatus;
    if (!widget.isArabic) {
      translatedStatus = paymentStatus == 'مدفوع' ? 'Paid' : 'Pending';
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: widget.isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(30),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blueGrey, width: 2)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(child: pw.Text(AppStrings.get('pdf_title', widget.isArabic), style: pw.TextStyle(font: arabicFontBold, fontSize: 22))),
                  pw.SizedBox(height: 10),
                  pw.Divider(thickness: 2),
                  pw.SizedBox(height: 30),
                  pw.Text(AppStrings.get('pdf_party_one', widget.isArabic), style: pw.TextStyle(font: arabicFont, fontSize: 14)),
                  pw.SizedBox(height: 10),
                  pw.Text('${AppStrings.get('pdf_party_two', widget.isArabic)}$clientName', style: pw.TextStyle(font: arabicFont, fontSize: 14)),
                  pw.SizedBox(height: 10),
                  pw.Text('${AppStrings.get('pdf_facility', widget.isArabic)}$facility', style: pw.TextStyle(font: arabicFont, fontSize: 14)),
                  pw.SizedBox(height: 20),
                  pw.Text('${AppStrings.get('pdf_value', widget.isArabic)}$value${AppStrings.get('pdf_currency', widget.isArabic)}', style: pw.TextStyle(font: arabicFont, fontSize: 14)),
                  pw.Text('${AppStrings.get('pdf_status', widget.isArabic)}$translatedStatus', style: pw.TextStyle(font: arabicFontBold, fontSize: 14, color: paymentStatus == 'مدفوع' ? PdfColors.green : PdfColors.red)),
                  pw.SizedBox(height: 20),
                  pw.Text(AppStrings.get('pdf_details_title', widget.isArabic), style: pw.TextStyle(font: arabicFontBold, fontSize: 14)),
                  pw.SizedBox(height: 5),
                  pw.Text(details, style: pw.TextStyle(font: arabicFont, fontSize: 12)),
                  pw.SizedBox(height: 50),
                  pw.Divider(),
                  pw.Center(child: pw.Text(AppStrings.get('pdf_footer', widget.isArabic), style: pw.TextStyle(font: arabicFont, fontSize: 10))),
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
        SnackBar(content: Text(AppStrings.get('alert_fill_fields', widget.isArabic)), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() { _isSaving = true; });
    final String currentAdminEmail = FirebaseAuth.instance.currentUser?.email ?? 'Finance Manager';

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
        action: widget.isArabic ? 'تسجيل عقد مالي' : 'Register Contract',
        details: widget.isArabic
            ? 'تم إبرام عقد للعميل: $clientName منشأة: $facilityName بقيمة: $contractValue ريال وحالتها [$_selectedPaymentStatus]'
            : 'Created contract for client: $clientName facility: $facilityName with value: $contractValue SAR status: [$_selectedPaymentStatus]',
        userEmail: currentAdminEmail,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isArabic ? 'تم حفظ بيانات العقد بنجاح!' : 'Contract data saved successfully!'), backgroundColor: Colors.green),
        );
        setState(() { _selectedClientName = null; _selectedPaymentStatus = 'قيد الانتظار'; });
        _facilityNameController.clear();
        _contractValueController.clear();
        _detailsController.clear();
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

  Future<void> _togglePaymentStatus(String docId, String currentStatus) async {
    String newStatus = currentStatus == 'مدفوع' ? 'قيد الانتظار' : 'مدفوع';
    final String currentAdminEmail = FirebaseAuth.instance.currentUser?.email ?? 'Finance Administration';
    try {
      await FirebaseFirestore.instance.collection('contracts').doc(docId).update({
        'paymentStatus': newStatus,
      });
      await AppLogger.logActivity(
        action: widget.isArabic ? 'تحديث حالة دفع' : 'Update Payment Status',
        details: widget.isArabic
            ? 'تم تغيير حالة دفع المستند رقم ($docId) إلى [$newStatus]'
            : 'Changed contract payment status for doc ($docId) to [$newStatus]',
        userEmail: currentAdminEmail,
      );
    } catch (e) {
      debugPrint('🚨 Error updating payment: $e');
    }
  }
  Future<void> _generateLocalPdfPreview(String clientName, String facility, String value, String details, String paymentStatus) async {
    if (clientName.isEmpty) return;
    setState(() { _isSaving = true; });
    try {
      Uint8List pdfBytes = await _buildPdfBytes(clientName, facility, value, details, paymentStatus);
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes, name: 'Contract_$clientName.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally { if (mounted) { setState(() { _isSaving = false; }); } }
  }

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
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('manage_contracts', widget.isArabic)),
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
                      return DropdownButtonFormField(items: [], onChanged: null, decoration: InputDecoration(labelText: AppStrings.get('loading_clients', widget.isArabic), border: const OutlineInputBorder()));
                    }
                    final clientDocs = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      value: _selectedClientName,
                      decoration: InputDecoration(labelText: AppStrings.get('select_client', widget.isArabic), border: const OutlineInputBorder()),
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
                TextField(controller: _facilityNameController, decoration: InputDecoration(labelText: AppStrings.get('facility_label', widget.isArabic), border: const OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _contractValueController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: AppStrings.get('value_label', widget.isArabic), border: const OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _detailsController, maxLines: 2, decoration: InputDecoration(labelText: AppStrings.get('details_label', widget.isArabic), border: const OutlineInputBorder())),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedPaymentStatus,
                  decoration: InputDecoration(labelText: AppStrings.get('payment_status_label', widget.isArabic), border: const OutlineInputBorder()),
                  items: [
                    DropdownMenuItem(value: 'قيد الانتظار', child: Text(AppStrings.get('status_pending_opt', widget.isArabic))),
                    DropdownMenuItem(value: 'مدفوع', child: Text(AppStrings.get('status_paid_opt', widget.isArabic))),
                  ],
                  onChanged: (value) { setState(() { _selectedPaymentStatus = value!; }); },
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.cloud_upload),
                        label: Text(AppStrings.get('btn_save_contract', widget.isArabic)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                        onPressed: _isSaving ? null : _saveContract,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, thickness: 2),
              ],

              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                    labelText: AppStrings.get('search_contract_placeholder', widget.isArabic),
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

              Text(AppStrings.get('contract_archive', widget.isArabic), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getContractsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    final filteredDocs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      String clientName = (data['clientName'] ?? '').toString().toLowerCase();
                      String facilityName = (data['facilityName'] ?? '').toString().toLowerCase();
                      return clientName.contains(_searchQuery) || facilityName.contains(_searchQuery);
                    }).toList();

                    if (filteredDocs.isEmpty) return Center(child: Text(AppStrings.get('no_contracts', widget.isArabic)));

                    return ListView.builder(
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final data = filteredDocs[index].data() as Map<String, dynamic>;
                        String docId = filteredDocs[index].id;
                        String cName = data['clientName'] ?? '';
                        String fName = data['facilityName'] ?? 'Facility';
                        String cValue = data['value'] ?? '0';
                        String cDetails = data['details'] ?? '';
                        String pStatus = data['paymentStatus'] ?? 'قيد الانتظار';

                        String displayStatus = pStatus == 'مدفوع' ? AppStrings.get('status_paid', widget.isArabic) : AppStrings.get('status_pending', widget.isArabic);
                        Color statusColor = pStatus == 'مدفوع' ? Colors.green : Colors.red;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: statusColor.withOpacity(0.1),
                              child: Icon(pStatus == 'مدفوع' ? Icons.check_circle : Icons.pending, color: statusColor),
                            ),
                            title: Text('$cName - ($fName)'),
                            subtitle: Text('${AppStrings.get('value_label', widget.isArabic)}: $cValue ${AppStrings.get('pdf_currency', widget.isArabic)} \nStatus: $displayStatus'),
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
      ),
    );
  }
}
