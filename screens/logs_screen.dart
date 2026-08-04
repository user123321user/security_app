import 'package:flutter/material.dart' as material; // استخدام رمز مستعار صريح ومباشر
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LogsScreen extends material.StatelessWidget {
  final bool isArabic;

  const LogsScreen({super.key, required this.isArabic});

  @override
  material.Widget build(material.BuildContext context) {
    // حل هندسي قاطع: استدعاء التوجيه اللغوي عبر الرموز المستعارة الصريحة لمنع التضارب
    return material.Directionality(
      textDirection: isArabic ? material.TextDirection.rtl : material.TextDirection.ltr,
      child: material.Scaffold(
        appBar: material.AppBar(
          title: material.Text(isArabic ? 'سجل العمليات والنشاطات السحابي' : 'System Activity Logs'),
          backgroundColor: material.Colors.brown,
          foregroundColor: material.Colors.white,
        ),
        body: material.StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('activity_logs').orderBy('timestamp', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const material.Center(child: material.CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return material.Center(child: material.Text(isArabic ? 'لا توجد سجلات نشاط مسجلة بعد.' : 'No activity logs found.'));
            }

            return material.ListView.builder(
              padding: const material.EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                String action = data['action'] ?? 'Action';
                String details = data['details'] ?? 'Details';
                String email = data['userEmail'] ?? 'System';

                String dateStr = '';
                if (data['timestamp'] != null) {
                  DateTime dt = (data['timestamp'] as Timestamp).toDate();
                  dateStr = DateFormat('yyyy-MM-dd hh:mm a').format(dt);
                }

                return material.Card(
                  margin: const material.EdgeInsets.symmetric(vertical: 6),
                  child: material.ListTile(
                    leading: const material.CircleAvatar(
                      backgroundColor: material.Colors.brown,
                      child: material.Icon(material.Icons.history_toggle_off, color: material.Colors.white),
                    ),
                    title: material.Text(action, style: const material.TextStyle(fontWeight: material.FontWeight.bold, color: material.Colors.brown)),
                    subtitle: material.Column(
                      crossAxisAlignment: material.CrossAxisAlignment.start,
                      children: [
                        const material.SizedBox(height: 4),
                        material.Text(details, style: const material.TextStyle(fontSize: 14, color: material.Colors.black87)),
                        const material.SizedBox(height: 4),
                        material.Text('${isArabic ? "المسؤول: " : "By: "}$email | $dateStr', style: const material.TextStyle(fontSize: 11, color: material.Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
