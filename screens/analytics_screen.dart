import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsScreen extends StatefulWidget {
  final bool isArabic; // استقبال حالة اللغة النشطة

  const AnalyticsScreen({super.key, required this.isArabic});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isArabic ? 'لوحة الإحصائيات والتقارير' : 'Live Analytics & Reports'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isArabic ? 'ملخص العمليات والوضع المالي الحالي:' : 'Operational & Financial Summary:',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 1. بطاقة حساب أعداد حراس الأمن الميدانيين تلقائياً
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('employees').snapshots(),
                builder: (context, snapshot) {
                  int totalGuards = 0;
                  if (snapshot.hasData) {
                    totalGuards = snapshot.data!.docs.length;
                  }
                  return _buildStatCard(
                    title: widget.isArabic ? 'إجمالي نوبات الحراس النشطة' : 'Total Active Guard Shifts',
                    value: '$totalGuards',
                    icon: Icons.shield,
                    color: Colors.blueGrey,
                  );
                },
              ),
              const SizedBox(height: 15),

              // 2. بطاقة حساب القيم الإجمالية والمالية للعقود السحابية
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('contracts').snapshots(),
                builder: (context, snapshot) {
                  double totalRevenue = 0;
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      double value = double.tryParse(data['value'] ?? '0') ?? 0;
                      totalRevenue += value;
                    }
                  }
                  return _buildStatCard(
                    title: widget.isArabic ? 'إجمالي الاستثمارات وقيم العقود السنوية' : 'Total Annual Contracts Value',
                    value: widget.isArabic ? '$totalRevenue ريال سعودي' : '$totalRevenue SAR',
                    icon: Icons.monetization_on,
                    color: Colors.green,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 30,
              child: Icon(icon, color: color, size: 35),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
