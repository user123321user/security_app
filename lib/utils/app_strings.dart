import 'package:flutter/material.dart';

class AppStrings {
  static String get(String key, bool isArabic) {
    final Map<String, Map<String, String>> localizedValues = {
      // شاشة الدخول واللوحة الرئيسية
      'admin_dashboard': {'ar': 'لوحة تحكم مدير النظام', 'en': 'Admin Dashboard'},
      'employee_dashboard': {'ar': 'لوحة الموظف التشغيلية', 'en': 'Employee Operational Dashboard'},
      'client_dashboard': {'ar': 'بوابة العميل الرقمية', 'en': 'Client Digital Portal'},
      'current_user': {'ar': 'الحساب الحالي: ', 'en': 'Current Account: '},
      'logout': {'ar': 'تسجيل الخروج', 'en': 'Log Out'},

      // بطاقات اللوحة الرئيسية
      'manage_users': {'ar': 'إدارة حسابات وصلاحيات النظام', 'en': 'Manage Accounts & Permissions'},
      'manage_users_sub': {'ar': 'إضافة مستخدمين جدد وتحديد أدوارهم السحابية وقدرة الحذف والتعديل', 'en': 'Add new users, define cloud roles, edit and delete accounts'},
      'manage_employees': {'ar': 'إدارة موظفي الأمن ونوباتهم', 'en': 'Manage Security Guards & Shifts'},
      'manage_employees_sub': {'ar': 'إضافة الحراس الميدانيين وتوزيع النوبات السحابية حركياً بالبحث المتقدم', 'en': 'Add field guards and assign mobile shifts dynamically with advanced search'},
      'manage_contracts': {'ar': 'إدارة العقود والمدفوعات (PDF)', 'en': 'Manage Contracts & Payments (PDF)'},
      'manage_contracts_sub': {'ar': 'تسجيل العقود والمنشآت وتوليد ملفات الـ PDF مع شريط البحث المتقدم', 'en': 'Register contracts, facilities, and generate PDFs with advanced search bar'},
      'analytics': {'ar': 'لوحة الإحصائيات والتقارير التفاعلية', 'en': 'Interactive Analytics & Reports'},
      'analytics_sub': {'ar': 'حساب قيم العقود السنوية وأعداد الحراس الميدانيين تلقائياً وبسرعة', 'en': 'Calculate annual contracts value & total guard strength automatically'},

      // شاشة إدارة الموظفين والحراس
      'select_guard': {'ar': 'اختر اسم حارس الأمن المسجل', 'en': 'Select Registered Security Guard'},
      'loading_guards': {'ar': 'جاري تحميل قائمة الحراس...', 'en': 'Loading guards list...'},
      'phone_label': {'ar': 'رقم الهاتف الميداني', 'en': 'Field Phone Number'},
      'location_label': {'ar': 'موقع النوبة المخصص حركياً', 'en': 'Assigned Shift Location'},
      'btn_save_shift': {'ar': 'إدراج وتوزيع النوبة الأمنية سحابياً', 'en': 'Insert & Assign Shift on Cloud'},
      'search_guard_placeholder': {'ar': 'ابحث باسم الحارس أو موقع نوبته الميدانية...', 'en': 'Search by guard name or shift location...'},
      'shift_archive': {'ar': 'سجل نوبات الحراس الميدانية الحالية:', 'en': 'Current Field Guards Shifts Log:'},
      'no_shifts': {'ar': 'لا توجد نوبات عمل مطابقة لبحثك حالياً.', 'en': 'No matching shifts found at the moment.'},
      'edit_shift_title': {'ar': 'تعديل نوبة الحارس: ', 'en': 'Edit Shift for Guard: '},

      // شاشة إدارة العقود والمدفوعات
      'select_client': {'ar': 'اختر اسم العميل المسؤول', 'en': 'Select Responsible Client Name'},
      'loading_clients': {'ar': 'جاري تحميل قائمة العملاء...', 'en': 'Loading clients list...'},
      'facility_label': {'ar': 'اسم المنشأة المستهدفة بالتغطية الأمنية', 'en': 'Target Facility Name for Security Coverage'},
      'value_label': {'ar': 'قيمة العقد الإجمالية', 'en': 'Total Contract Value'},
      'details_label': {'ar': 'شروط وبنود التغطية الأمنية', 'en': 'Security Coverage Terms & Clauses'},
      'payment_status_label': {'ar': 'تحديد وضعية حالة الدفع الأولية', 'en': 'Select Initial Payment Status'},
      'status_pending_opt': {'ar': 'قيد الانتظار (لم يتم السداد)', 'en': 'Pending (Unpaid)'},
      'status_paid_opt': {'ar': 'مدفوع (تم السداد بالكامل)', 'en': 'Paid (Fully Paid)'},
      'btn_save_contract': {'ar': 'حفظ العقد والمالية سحابياً', 'en': 'Save Contract & Finances to Cloud'},
      'search_contract_placeholder': {'ar': 'ابحث باسم العميل أو اسم المنشأة المستهدفة...', 'en': 'Search by client name or target facility...'},
      'contract_archive': {'ar': 'أرشيف الفواتير والتعاقدات المالية الحية:', 'en': 'Live Invoices & Contracts Archive:'},
      'no_contracts': {'ar': 'لا توجد نتائج مطابقة لبحثك أو صلاحيتك الحالية.', 'en': 'No contracts found matching your search or role.'},

      // نصوص عامة ومستند الـ PDF
      'pdf_title': {'ar': 'وثيقة عقد حماية وأمن رقمي', 'en': 'Digital Security & Protection Contract Document'},
      'pdf_party_one': {'ar': 'الطرف الأول: شركة الحماية والأمن المتكاملة', 'en': 'First Party: Integrated Security & Protection Company'},
      'pdf_party_two': {'ar': 'الطرف الثاني (العميل): ', 'en': 'Second Party (Client): '},
      'pdf_facility': {'ar': 'المنشأة المستهدفة بالتغطية: ', 'en': 'Target Facility for Coverage: '},
      'pdf_value': {'ar': 'قيمة العقد السنوية المتفق عليها: ', 'en': 'Agreed Annual Contract Value: '},
      'pdf_currency': {'ar': ' ريال سعودي', 'en': ' SAR'},
      'pdf_status': {'ar': 'حالة الفاتورة والمدفوعات الحالية: ', 'en': 'Current Invoice & Payment Status: '},
      'pdf_details_title': {'ar': 'تفاصيل ونطاق الحماية الميدانية:', 'en': 'Field Security Details & Scope:'},
      'pdf_footer': {'ar': 'مستند رقمي معتمد سحابياً عبر نظام الحماية', 'en': 'Digital document officially certified via the Cloud Security System'},
      'status_paid': {'ar': 'مدفوع', 'en': 'Paid'},
      'status_pending': {'ar': 'قيد الانتظار', 'en': 'Pending'},
      'alert_fill_fields': {'ar': 'الرجاء تعبئة جميع المتطلبات', 'en': 'Please fill all required fields'},
      'cancel': {'ar': 'إلغاء', 'en': 'Cancel'},
      'update': {'ar': 'تحديث', 'en': 'Update'}
    };

    return localizedValues[key]?[isArabic ? 'ar' : 'en'] ?? key;
  }
}
