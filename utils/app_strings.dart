class AppStrings {
  static String get(String key, bool isArabic) {
    final Map<String, Map<String, String>> localizedValues = {
      'admin_dashboard': {
        'ar': 'لوحة تحكم مدير النظام',
        'en': 'Admin Dashboard'
      },
      'employee_dashboard': {
        'ar': 'لوحة الموظف التشغيلية',
        'en': 'Employee Operational Dashboard'
      },
      'client_dashboard': {
        'ar': 'بوابة العميل الرقمية',
        'en': 'Client Digital Portal'
      },
      'current_user': {
        'ar': 'الحساب الحالي: ',
        'en': 'Current Account: '
      },
      'manage_users': {
        'ar': 'إدارة حسابات وصلاحيات النظام',
        'en': 'Manage Accounts & Permissions'
      },
      'manage_users_sub': {
        'ar': 'إضافة مستخدمين جدد (موظفين، عملاء) وتحديد أدوارهم السحابية',
        'en': 'Add new users (employees, clients) and define cloud roles'
      },
      'manage_employees': {
        'ar': 'إدارة موظفي الأمن ونوباتهم',
        'en': 'Manage Security Guards & Shifts'
      },
      'manage_employees_sub': {
        'ar': 'إضافة الحراس الميدانيين وتوزيع النوبات السحابية حركياً',
        'en': 'Add field guards and assign mobile shifts dynamically'
      },
      'manage_contracts': {
        'ar': 'إدارة العقود الرقمية (PDF)',
        'en': 'Manage Digital Contracts (PDF)'
      },
      'manage_contracts_sub': {
        'ar': 'تسجيل العقود، أرشفة البنود، وتوليد ملفات الـ PDF للطباعة',
        'en': 'Register contracts, archive clauses, and generate PDFs for printing'
      },
      'analytics': {
        'ar': 'لوحة الإحصائيات والتقارير التفاعلية',
        'en': 'Interactive Analytics & Reports'
      },
      'analytics_sub': {
        'ar': 'حساب قيم العقود السنوية وأعداد الحراس الميدانيين تلقائياً',
        'en': 'Calculate annual contracts value & total guard strength automatically'
      },
      'select_guard': {
        'ar': 'اختر اسم حارس الأمن المسجل',
        'en': 'Select Registered Security Guard'
      },
      'phone_label': {
        'ar': 'رقم الهاتف الميداني',
        'en': 'Field Phone Number'
      },
      'location_label': {
        'ar': 'موقع النوبة المخصص حركياً',
        'en': 'Assigned Shift Location'
      },
      'btn_save_shift': {
        'ar': 'إدراج وتوزيع النوبة الأمنية سحابياً',
        'en': 'Insert & Assign Shift on Cloud'
      },
      'shift_archive': {
        'ar': 'سجل نوبات الحراس الميدانية الحالية:',
        'en': 'Current Field Guards Shifts Log:'
      },
      'no_shifts': {
        'ar': 'لا توجد نوبات عمل مسجلة حالياً.',
        'en': 'No registered shifts found at the moment.'
      },
      'phone_short': {
        'ar': 'الهاتف: ',
        'en': 'Phone: '
      },
      'location_short': {
        'ar': 'الموقع: ',
        'en': 'Location: '
      }
    };

    return localizedValues[key]?[isArabic ? 'ar' : 'en'] ?? key;
  }
}
