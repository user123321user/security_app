import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // لتنسيق وعرض التواريخ

class LogsScreen extends StatelessWidget {
  final bool isArabic; // استقبال حالة اللغة النشطة

  const LogsScreen({super.key, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isArabic ? 'سجل العمليات والنشاطات السحابي' : 'System Activity Logs'),
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('activity_logs').orderBy('timestamp', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return Center(child: Text(isArabic ? 'لا توجد سجلات نشاط مسجلة بعد.' : 'No activity logs found.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
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

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.brown,
                      child: Icon(Icons.history_toggle_off, color: Colors.white),
                    ),
                    title: Text(action, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(details, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text('${isArabic ? "المسؤول: " : "By: "}$email | $dateStr', style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
