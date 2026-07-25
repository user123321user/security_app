import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  // دالة لحساب المجموع المالي لكافة العقود المبرمة لحظياً
  double _calculateTotalContractsValue(List<QueryDocumentSnapshot> docs) {
    double total = 0.0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      // تحويل القيمة النصية أو الرقمية المتوفرة في قاعدة البيانات إلى رقم عشري بأمان
      final valueStr = data['value']?.toString() ?? '0';
      total += double.tryParse(valueStr) ?? 0.0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التقارير والإحصائيات التفاعلية'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'مؤشرات الأداء التشغيلي والمالي الحية:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
            ),
            const SizedBox(height: 16),

            // 1. كارت إحصاء عدد حراس الأمن الميدانيين
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('employees').snapshots(),
              builder: (context, snapshot) {
                int totalEmployees = 0;
                if (snapshot.hasData) {
                  totalEmployees = snapshot.data!.docs.length;
                }
                return _buildStatCard(
                  title: 'إجمالي قوة حراس الأمن',
                  value: '$totalEmployees حارس',
                  icon: Icons.shield,
                  color: Colors.blueGrey,
                  isLoading: snapshot.connectionState == ConnectionState.waiting,
                );
              },
            ),
            const SizedBox(height: 12),

            // 2. كارت إحصاء عدد العقود وقيمتها المالية الإجمالية بالتزامن
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('contracts').snapshots(),
              builder: (context, snapshot) {
                int totalContracts = 0;
                double totalValue = 0.0;

                if (snapshot.hasData) {
                  totalContracts = snapshot.data!.docs.length;
                  totalValue = _calculateTotalContractsValue(snapshot.data!.docs);
                }

                return Column(
                  children: [
                    _buildStatCard(
                      title: 'إجمالي العقود الأمنية النشطة',
                      value: '$totalContracts عقد رقمي',
                      icon: Icons.assignment_turned_in,
                      color: Colors.amber[800]!,
                      isLoading: snapshot.connectionState == ConnectionState.waiting,
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      title: 'الحجم المالي الإجمالي للاستثمارات',
                      value: '${totalValue.toStringAsFixed(2)} ريال سعودي',
                      icon: Icons.monetization_on,
                      color: Colors.green[700]!,
                      isLoading: snapshot.connectionState == ConnectionState.waiting,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),

            // عنصر توضيحي للمسؤول يعكس الشفافية والأتمتة السحابية المتكاملة
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.purple),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'يتم تحديث هذه الإحصائيات الرياضية والمالية تلقائياً ولحظياً بمجرد إضافة أو تعديل أي عقد أو موظف ميداني في قاعدة البيانات.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // وجت مخصصة لبناء كروت المؤشرات الرقمية بدقة عالية UI/UX
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isLoading,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 28,
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(
                    value,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
