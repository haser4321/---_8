
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HesabApp());
}

const Color appColor = Color(0xFF087F8C);

class HesabApp extends StatefulWidget {
  const HesabApp({super.key});

  @override
  State<HesabApp> createState() => _HesabAppState();
}

class _HesabAppState extends State<HesabApp> {
  bool darkMode = false;
  bool loading = true;
  String currency = 'د.ع';

  List<Map<String, dynamic>> projects = [];
  List<Map<String, dynamic>> history = [];
  Map<String, double> prices = {
    'سعر البلاط للمتر': 15000,
    'سعر الصبغ للتر': 5000,
    'سعر كيس الإسمنت': 8000,
    'أجرة العامل للمتر': 5000,
  };

  
  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedProjects = prefs.getString('projects');
      final savedHistory = prefs.getString('history');
      final savedPrices = prefs.getString('prices');

      final loadedProjects = <Map<String, dynamic>>[];
      final loadedHistory = <Map<String, dynamic>>[];

      if (savedProjects != null) {
        loadedProjects.addAll(
          (jsonDecode(savedProjects) as List).map(
            (e) => Map<String, dynamic>.from(e as Map),
          ),
        );
      }

      if (savedHistory != null) {
        loadedHistory.addAll(
          (jsonDecode(savedHistory) as List).map(
            (e) => Map<String, dynamic>.from(e as Map),
          ),
        );
      }

      final loadedPrices = <String, double>{
        'سعر البلاط للمتر': 15000,
        'سعر الصبغ للتر': 5000,
        'سعر كيس الإسمنت': 8000,
        'أجرة العامل للمتر': 5000,
      };

      if (savedPrices != null) {
        final decodedPrices = jsonDecode(savedPrices) as Map;

        decodedPrices.forEach((key, value) {
          if (value is num) {
            loadedPrices[key.toString()] = value.toDouble();
          }
        });
      }

      if (!mounted) return;

      setState(() {
        projects = loadedProjects;
        history = loadedHistory;
        prices = loadedPrices;
        darkMode = prefs.getBool('darkMode') ?? false;
        currency = prefs.getString('currency') ?? 'د.ع';
        loading = false;
      });
    } catch (error) {
      debugPrint('خطأ تحميل بيانات التطبيق: $error');

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }


      if (savedPrices != null) {
        prices = Map<String, double>.from(
          (jsonDecode(savedPrices) as Map).map(
            (key, value) => MapEntry(
              key.toString(),
              (value as num).toDouble(),
            ),
          ),
        );
      }

      darkMode = prefs.getBool('darkMode') ?? false;
      currency = prefs.getString('currency') ?? 'د.ع';
    } catch (_) {
      projects = [];
      history = [];
    }

    if (mounted) {
      setState(() => loading = false);
    }


  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('projects', jsonEncode(projects));
    await prefs.setString('history', jsonEncode(history));
    await prefs.setString('prices', jsonEncode(prices));
    await prefs.setBool('darkMode', darkMode);
    await prefs.setString('currency', currency);
  }

  Future<void> addProject(Map<String, dynamic> project) async {
    setState(() => projects.insert(0, project));
    await persist();
  }

  Future<void> addHistory(Map<String, dynamic> item) async {
    setState(() {
      history.insert(0, item);

      if (history.length > 500) {
        history = history.take(500).toList();
      }
    });

    await persist();
  }

  Future<void> updatePrice(String name, double value) async {
    setState(() => prices[name] = value);
    await persist();
  }

  Future<void> setTheme(bool value) async {
    setState(() => darkMode = value);
    await persist();
  }

  Future<void> setCurrency(String value) async {
    setState(() => currency = value);
    await persist();
  }

  Future<void> deleteProject(int index) async {
    setState(() => projects.removeAt(index));
    await persist();
  }

  Future<void> deleteHistory(int index) async {
    setState(() => history.removeAt(index));
    await persist();
  }

  Future<void> restoreBackup(String raw) async {
    final data = jsonDecode(raw) as Map<String, dynamic>;

    final restoredProjects =
        (data['projects'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

    final restoredHistory =
        (data['history'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

    final restoredPrices = <String, double>{};

    (data['prices'] as Map? ?? {}).forEach((key, value) {
      restoredPrices[key.toString()] = (value as num).toDouble();
    });

    setState(() {
      projects = restoredProjects;
      history = restoredHistory;
      prices = restoredPrices;
    });

    await persist();
  }

  Future<void> exportBackup() async {
    final backup = jsonEncode({
      'version': 1,
      'projects': projects,
      'history': history,
      'prices': prices,
    });

    await Clipboard.setData(ClipboardData(text: backup));
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      projects = [];
      history = [];
      prices = {
        'سعر البلاط للمتر': 15000,
        'سعر الصبغ للتر': 5000,
        'سعر كيس الإسمنت': 8000,
        'أجرة العامل للمتر': 5000,
      };
    });

    await prefs.remove('projects');
    await prefs.remove('history');
    await prefs.remove('prices');
    await persist();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حِسبة المعلّم',
      debugShowCheckedModeBanner: false,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: appColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7F8),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: appColor,
          brightness: Brightness.dark,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      home: loading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : HomeScreen(
              projects: projects,
              history: history,
              prices: prices,
              currency: currency,
              darkMode: darkMode,
              onAddProject: addProject,
              onAddHistory: addHistory,
              onDeleteProject: deleteProject,
              onDeleteHistory: deleteHistory,
              onUpdatePrice: updatePrice,
              onThemeChanged: setTheme,
              onCurrencyChanged: setCurrency,
              onExport: exportBackup,
              onRestore: restoreBackup,
              onClear: clearAll,
            ),
    );
  }


class HomeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> projects;
  final List<Map<String, dynamic>> history;
  final Map<String, double> prices;
  final String currency;
  final bool darkMode;

  final Future<void> Function(Map<String, dynamic>) onAddProject;
  final Future<void> Function(Map<String, dynamic>) onAddHistory;
  final Future<void> Function(int) onDeleteProject;
  final Future<void> Function(int) onDeleteHistory;
  final Future<void> Function(String, double) onUpdatePrice;
  final Future<void> Function(bool) onThemeChanged;
  final Future<void> Function(String) onCurrencyChanged;
  final Future<void> Function() onExport;
  final Future<void> Function(String) onRestore;
  final Future<void> Function() onClear;

  const HomeScreen({
    super.key,
    required this.projects,
    required this.history,
    required this.prices,
    required this.currency,
    required this.darkMode,
    required this.onAddProject,
    required this.onAddHistory,
    required this.onDeleteProject,
    required this.onDeleteHistory,
    required this.onUpdatePrice,
    required this.onThemeChanged,
    required this.onCurrencyChanged,
    required this.onExport,
    required this.onRestore,
    required this.onClear,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0;

  String money(num value) {
    return '${formatNumber(value)} ${widget.currency}';
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      dashboard(),
      calculators(),
      projectPage(),
      historyPage(),
      settingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.construction, color: appColor),
            SizedBox(width: 9),
            Text(
              'حِسبة المعلّم',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: selectedTab,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (value) {
          setState(() => selectedTab = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'الحاسبات',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'المشاريع',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'السجل',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }

  Widget dashboard() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF087F8C), Color(0xFF075E69)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'كل حسابات شغلك في مكان واحد',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'احسب الكميات والتكاليف واحفظ مشاريعك دون إنترنت.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 18),
              FilledButton.tonalIcon(
                onPressed: () => setState(() => selectedTab = 1),
                icon: const Icon(Icons.calculate),
                label: const Text('ابدأ الحساب'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            statCard(
              'المشاريع',
              '${widget.projects.length}',
              Icons.folder,
            ),
            statCard(
              'الحسابات',
              '${widget.history.length}',
              Icons.calculate,
            ),
            statCard(
              'أسعار المواد',
              '${widget.prices.length}',
              Icons.inventory_2,
            ),
            statCard(
              'العمل',
              'دون إنترنت',
              Icons.wifi_off,
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Text(
          'الحاسبات السريعة',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        quickCalculator('البلاط', 'tile', Icons.grid_view),
        quickCalculator('الصبغ', 'paint', Icons.format_paint),
        quickCalculator('الخرسانة', 'concrete', Icons.foundation),
        quickCalculator('التكلفة', 'cost', Icons.payments),
        const SizedBox(height: 22),
        const Text(
          'آخر الحسابات',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (widget.history.isEmpty)
          const EmptyMessage('ستظهر حساباتك المحفوظة هنا.')
        else
          ...widget.history.take(4).map((item) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long, color: appColor),
                title: Text('${item['title'] ?? 'حساب'}'),
                subtitle: Text('${item['date'] ?? ''}'),
                trailing: Text(
                  '${formatNumber(numberOf(item['total']))} ${widget.currency}',
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget statCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: appColor, size: 25),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget quickCalculator(String title, String type, IconData icon) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: appColor.withValues(alpha: 0.12),
          child: Icon(icon, color: appColor),
        ),
        title: Text('حاسبة $title'),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => openCalculator(type),
      ),
    );
  }

  Widget calculators() {
    final items = [
      ['مساحة الغرفة', 'area', Icons.square_foot],
      ['البلاط والهدر', 'tile', Icons.grid_view],
      ['الصبغ', 'paint', Icons.format_paint],
      ['الخرسانة', 'concrete', Icons.foundation],
      ['تكلفة المشروع', 'cost', Icons.payments],
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'اختر الحاسبة',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('أدخل القياسات لتحصل على نتيجة قابلة للمراجعة.'),
        const SizedBox(height: 12),
        ...items.map((item) {
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: CircleAvatar(
                backgroundColor: appColor.withValues(alpha: 0.12),
                child: Icon(item[2] as IconData, color: appColor),
              ),
              title: Text(item[0] as String),
              subtitle: Text(calculatorDescription(item[1] as String)),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => openCalculator(item[1] as String),
            ),
          );
        }),
      ],
    );
  }

  String calculatorDescription(String type) {
    switch (type) {
      case 'area':
        return 'مساحة الأرضيات والجدران';
      case 'tile':
        return 'عدد البلاطات مع نسبة الهدر';
      case 'paint':
        return 'تقدير كمية الصبغ';
      case 'concrete':
        return 'حجم الخرسانة بالمتر المكعب';
      default:
        return 'حساب المواد والأجور';
    }
  }

  void openCalculator(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CalculatorScreen(
          type: type,
          prices: widget.prices,
          currency: widget.currency,
          onSave: widget.onAddHistory,
          onAddProject: widget.onAddProject,
        ),
      ),
    );
  }

  Widget projectPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'مشاريعي',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            FilledButton.icon(
              onPressed: addProjectDialog,
              icon: const Icon(Icons.add),
              label: const Text('مشروع جديد'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.projects.isEmpty)
          const EmptyMessage('لم تحفظ أي مشروع بعد.')
        else
          ...widget.projects.asMap().entries.map((entry) {
            final project = entry.value;
            final total = numberOf(project['total']);

            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.home_work),
                ),
                title: Text('${project['name'] ?? 'مشروع'}'),
                subtitle: Text(
                  '${project['date'] ?? ''}\n'
                  'التكلفة التقديرية: ${formatNumber(total)} ${widget.currency}',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'share') {
                      await copyText(
                        'المشروع: ${project['name']}\n'
                        'التفاصيل: ${project['details'] ?? ''}\n'
                        'التكلفة التقديرية: ${formatNumber(total)} ${widget.currency}',
                      );
                    }

                    if (value == 'delete') {
                      await widget.onDeleteProject(entry.key);
                      refresh();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'share',
                      child: Text('نسخ تفاصيل المشروع'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('حذف المشروع'),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Future<void> addProjectDialog() async {
    final nameController = TextEditingController();
    final detailsController = TextEditingController();
    final totalController = TextEditingController(text: '0');

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('إنشاء مشروع'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم المشروع'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'التفاصيل'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: totalController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'التكلفة التقديرية (${widget.currency})',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(dialogContext, true);
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      await widget.onAddProject({
        'name': nameController.text.trim(),
        'details': detailsController.text.trim(),
        'total': numberOf(totalController.text),
        'date': currentDate(),
      });

      refresh();
    }

    nameController.dispose();
    detailsController.dispose();
    totalController.dispose();
  }

  Widget historyPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'سجل الحسابات',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('تُحفظ آخر 500 عملية على الجهاز.'),
        const SizedBox(height: 12),
        if (widget.history.isEmpty)
          const EmptyMessage('لا توجد عمليات محفوظة.')
        else
          ...widget.history.asMap().entries.map((entry) {
            final item = entry.value;

            return Card(
              child: ListTile(
                leading: const Icon(Icons.history, color: appColor),
                title: Text('${item['title'] ?? 'حساب'}'),
                subtitle: Text(
                  '${item['date'] ?? ''}\n'
                  '${formatNumber(numberOf(item['quantity']))} وحدة',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'copy') {
                      await copyText(
                        'حِسبة المعلّم\n'
                        'الحساب: ${item['title']}\n'
                        'التفاصيل: ${item['details']}\n'
                        'الكمية: ${item['quantity']}\n'
                        'الإجمالي: ${item['total']} ${widget.currency}',
                      );
                    } else if (value == 'delete') {
                      await widget.onDeleteHistory(entry.key);
                      refresh();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'copy',
                      child: Text('نسخ الحساب'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('حذف الحساب'),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget settingsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'الإعدادات',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            value: widget.darkMode,
            onChanged: widget.onThemeChanged,
            secondary: const Icon(Icons.dark_mode),
            title: const Text('الوضع الليلي'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.payments),
            title: const Text('العملة'),
            subtitle: Text(widget.currency),
            trailing: const Icon(Icons.chevron_left),
            onTap: chooseCurrency,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.price_change),
            title: const Text('أسعار المواد'),
            subtitle: const Text('تعديل الأسعار الافتراضية للحسابات'),
            trailing: const Icon(Icons.chevron_left),
            onTap: managePrices,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('نسخ احتياطي'),
            subtitle: const Text('نسخ المشاريع والسجل والأسعار كنص JSON'),
            onTap: backupDialog,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('استعادة نسخة احتياطية'),
            subtitle: const Text('استبدال البيانات بالنسخة المستعادة'),
            onTap: restoreDialog,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('مسح جميع البيانات'),
            onTap: confirmClear,
          ),
        ),
        const SizedBox(height: 18),
        const Center(
          child: Text(
            'حِسبة المعلّم • الإصدار 1.0.0\n'
            'يعمل دون إنترنت',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Future<void> chooseCurrency() async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('اختر العملة'),
        children: [
          for (final value in ['د.ع', 'دولار', 'ريال', 'درهم'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, value),
              child: Text(value),
            ),
        ],
      ),
    );

    if (result != null) {
      await widget.onCurrencyChanged(result);
      refresh();
    }
  }

  Future<void> managePrices() async {
    final names = widget.prices.keys.toList();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PricesScreen(
          prices: widget.prices,
          currency: widget.currency,
          onSave: widget.onUpdatePrice,
        ),
      ),
    );

    if (mounted) refresh();
  }

  Future<void> backupDialog() async {
    final controller = TextEditingController();

    await widget.onExport();

    final backup = jsonEncode({
      'version': 1,
      'projects': widget.projects,
      'history': widget.history,
      'prices': widget.prices,
    });

    controller.text = backup;

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('النسخة الاحتياطية'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'انسخ النص كاملًا واحتفظ به خارج التطبيق. '
                'استعادته ستستبدل البيانات الحالية.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 8,
                readOnly: true,
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () async {
                  await copyText(controller.text);
                },
                icon: const Icon(Icons.copy),
                label: const Text('نسخ النص'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );

    controller.dispose();
  }

  Future<void> restoreDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('استعادة النسخة'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'الصق نص النسخة الاحتياطية هنا',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await widget.onRestore(controller.text);
        refresh();
        message('تمت استعادة البيانات.');
      } catch (_) {
        message('تعذرت الاستعادة. تحقق من صحة النص.');
      }
    }

    controller.dispose();
  }

  Future<void> confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مسح البيانات؟'),
        content: const Text(
          'سيتم حذف جميع المشاريع والحسابات والأسعار المخصصة. '
          'لا يمكن التراجع عن هذه العملية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('مسح'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.onClear();
      refresh();
      message('تم مسح البيانات.');
    }
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  final String type;
  final Map<String, double> prices;
  final String currency;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final Future<void> Function(Map<String, dynamic>) onAddProject;

  const CalculatorScreen({
    super.key,
    required this.type,
    required this.prices,
    required this.currency,
    required this.onSave,
    required this.onAddProject,
  });

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final Map<String, TextEditingController> controllers = {};

  double resultQuantity = 0;
  double resultCost = 0;
  String resultDetails = '';
  bool calculated = false;

  late String title;

  @override
  void initState() {
    super.initState();

    title = calculatorTitle(widget.type);

    for (final field in fieldsFor(widget.type)) {
      controllers[field.key] = TextEditingController(
        text: field.initialValue,
      );
    }
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double value(String key) {
    return numberOf(controllers[key]?.text);
  }

  void calculate() {
    final length = value('length');
    final width = value('width');
    final height = value('height');
    final openings = value('openings');
    final waste = value('waste');
    final tileLength = value('tileLength');
    final tileWidth = value('tileWidth');
    final coverage = value('coverage');
    final coats = value('coats');
    final thickness = value('thickness');
    final materialPrice = value('materialPrice');
    final laborPrice = value('laborPrice');
    final quantityInput = value('quantity');
    final unitPrice = value('unitPrice');

    double quantity = 0;
    double materialCost = 0;
    double laborCost = 0;
    String details = '';

    switch (widget.type) {
      case 'area':
        quantity = length * width;
        details = 'مساحة الأرضية = الطول × العرض';
        break;

      case 'tile':
        if (tileLength <= 0 || tileWidth <= 0) {
          showError('أدخل طول البلاطة وعرضها بقيم أكبر من صفر.');
          return;
        }

        final area = length * width;
        final usableArea = area + (area * waste / 100);
        quantity = usableArea / (tileLength * tileWidth);

        materialCost =
            quantity * materialPrice;

        details =
            'المساحة: ${formatNumber(area)} م²\n'
            'المساحة بعد الهدر: ${formatNumber(usableArea)} م²\n'
            'عدد البلاطات قبل التقريب: ${formatNumber(quantity)}';
        break;

      case 'paint':
        final walls = 2 * (length + width) * height;
        final ceiling = length * width;
        final netArea = walls + ceiling - openings;

        if (netArea < 0 || coverage <= 0 || coats <= 0) {
          showError('تحقق من المساحات والتغطية وعدد الطبقات.');
          return;
        }

        quantity = netArea * coats / coverage;
        materialCost = quantity * materialPrice;

        details =
            'مساحة الجدران والسقف الصافية: '
            '${formatNumber(netArea)} م²\n'
            'التغطية المفترضة: $coverage م² لكل لتر\n'
            'عدد الطبقات: ${formatNumber(coats)}';
        break;

      case 'concrete':
        if (thickness <= 0) {
          showError('يجب أن يكون السمك أكبر من صفر.');
          return;
        }

        quantity = length * width * thickness;
        materialCost = quantity * materialPrice;

        details =
            'الحجم الهندسي: ${formatNumber(quantity)} م³\n'
            'هذا تقدير للحجم فقط، وليس تصميم خلطة خرسانية.';
        break;

      case 'cost':
        quantity = quantityInput;
        materialCost = quantity * unitPrice;

        details =
            'الكمية: ${formatNumber(quantity)}\n'
            'سعر الوحدة: ${formatNumber(unitPrice)} ${widget.currency}';
        break;
    }

    if (!quantity.isFinite ||
        !materialCost.isFinite ||
        quantity < 0 ||
        materialCost < 0) {
      showError('القيم المدخلة غير صالحة.');
      return;
    }

    laborCost = quantity * laborPrice;
    final total = materialCost + laborCost;

    setState(() {
      resultQuantity = quantity;
      resultCost = total;
      resultDetails = details;
      calculated = true;
    });
  }

  Future<void> saveCalculation() async {
    if (!calculated) return;

    await widget.onSave({
      'title': title,
      'date': currentDate(),
      'quantity': resultQuantity,
      'total': resultCost,
      'details': resultDetails,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الحساب في السجل.')),
      );
    }
  }

  Future<void> saveAsProject() async {
    if (!calculated) return;

    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حفظ كمشروع'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'اسم المشروع',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (name != null) {
      await widget.onAddProject({
        'name': name,
        'details': '$title\n$resultDetails',
        'total': resultCost,
        'date': currentDate(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ المشروع.')),
        );
      }
    }

    controller.dispose();
  }

  Future<void> shareResult() async {
    if (!calculated) return;

    final text =
        'حِسبة المعلّم\n'
        'الحساب: $title\n'
        '$resultDetails\n'
        'الكمية: ${formatNumber(resultQuantity)}\n'
        'التكلفة التقديرية: ${formatNumber(resultCost)} ${widget.currency}\n'
        'التاريخ: ${currentDate()}\n'
        'النتيجة تقديرية وتعتمد على القياسات والأسعار المدخلة.';

    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ تفاصيل الحساب.')),
      );
    }
  }

  void showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fields = fieldsFor(widget.type);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'أدخل القياسات الفعلية. تأكد من استخدام وحدة القياس '
                    'الموضحة بجوار كل حقل.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...fields.map((field) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: controllers[field.key],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                decoration: InputDecoration(
                  labelText: field.label,
                  helperText: field.helper,
                  suffixText: field.unit.isEmpty ? null : field.unit,
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: calculate,
            icon: const Icon(Icons.calculate),
            label: const Text('احسب النتيجة'),
          ),
          if (calculated) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'نتيجة الحساب',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    resultRow(
                      'الكمية التقديرية',
                      '${formatNumber(resultQuantity)} ${unitFor(widget.type)}',
                    ),
                    const Divider(height: 24),
                    resultRow(
                      'التكلفة التقديرية',
                      '${formatNumber(resultCost)} ${widget.currency}',
                    ),
                    const SizedBox(height: 12),
                    SelectableText(resultDetails),
                    const SizedBox(height: 16),
                    const Text(
                      'التكلفة تقديرية وليست عرض سعر ملزمًا. '
                      'تأكد من الأسعار الفعلية والهدر وظروف العمل.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: saveCalculation,
              icon: const Icon(Icons.save),
              label: const Text('حفظ في السجل'),
            ),
            OutlinedButton.icon(
              onPressed: saveAsProject,
              icon: const Icon(Icons.folder),
              label: const Text('حفظ كمشروع'),
            ),
            OutlinedButton.icon(
              onPressed: shareResult,
              icon: const Icon(Icons.copy),
              label: const Text('نسخ النتيجة'),
            ),
          ],
        ],
      ),
    );
  }

  Widget resultRow(String label, String result) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Flexible(
          child: Text(
            result,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class PricesScreen extends StatefulWidget {
  final Map<String, double> prices;
  final String currency;
  final Future<void> Function(String, double) onSave;

  const PricesScreen({
    super.key,
    required this.prices,
    required this.currency,
    required this.onSave,
  });

  @override
  State<PricesScreen> createState() => _PricesScreenState();
}

class _PricesScreenState extends State<PricesScreen> {
  late Map<String, TextEditingController> controllers;

  @override
  void initState() {
    super.initState();

    controllers = {
      for (final entry in widget.prices.entries)
        entry.key: TextEditingController(
          text: formatNumber(entry.value),
        ),
    };
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    for (final entry in controllers.entries) {
      final parsed = double.tryParse(entry.value.text.trim());

      if (parsed == null || !parsed.isFinite || parsed < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('السعر غير صالح: ${entry.key}')),
        );
        return;
      }
    }

    for (final entry in controllers.entries) {
      await widget.onSave(
        entry.key,
        double.parse(entry.value.text.trim()),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الأسعار.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أسعار المواد')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'هذه أسعار أولية قابلة للتعديل. أدخل الأسعار الحقيقية '
            'في منطقتك قبل إجراء الحسابات.',
          ),
          const SizedBox(height: 16),
          ...controllers.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: entry.value,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: entry.key,
                  suffixText: widget.currency,
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: save,
            icon: const Icon(Icons.save),
            label: const Text('حفظ الأسعار'),
          ),
        ],
      ),
    );
  }
}

class InputField {
  final String key;
  final String label;
  final String unit;
  final String initialValue;
  final String? helper;

  const InputField(
    this.key,
    this.label, {
    this.unit = '',
    this.initialValue = '0',
    this.helper,
  });
}

String calculatorTitle(String type) {
  switch (type) {
    case 'area':
      return 'حاسبة المساحة';
    case 'tile':
      return 'حاسبة البلاط';
    case 'paint':
      return 'حاسبة الصبغ';
    case 'concrete':
      return 'حاسبة الخرسانة';
    default:
      return 'حاسبة التكلفة';
  }
}

String unitFor(String type) {
  switch (type) {
    case 'area':
      return 'م²';
    case 'tile':
      return 'بلاطة';
    case 'paint':
      return 'لتر';
    case 'concrete':
      return 'م³';
    default:
      return 'وحدة';
  }
}

List<InputField> fieldsFor(String type) {
  switch (type) {
    case 'area':
      return const [
        InputField('length', 'الطول', unit: 'م'),
        InputField('width', 'العرض', unit: 'م'),
      ];

    case 'tile':
      return const [
        InputField('length', 'طول الغرفة', unit: 'م'),
        InputField('width', 'عرض الغرفة', unit: 'م'),
        InputField(
          'tileLength',
          'طول البلاطة',
          unit: 'م',
          initialValue: '0.6',
        ),
        InputField(
          'tileWidth',
          'عرض البلاطة',
          unit: 'م',
          initialValue: '0.6',
        ),
        InputField(
          'waste',
          'نسبة الهدر',
          unit: '%',
          initialValue: '10',
        ),
        InputField(
          'materialPrice',
          'سعر البلاطة الواحدة',
          unit: 'عملة',
          initialValue: '1000',
        ),
        InputField(
          'laborPrice',
          'أجرة تركيب المتر المربع',
          unit: 'عملة/م²',
        ),
      ];

    case 'paint':
      return const [
        InputField('length', 'طول الغرفة', unit: 'م'),
        InputField('width', 'عرض الغرفة', unit: 'م'),
        InputField('height', 'ارتفاع الجدران', unit: 'م'),
        InputField(
          'openings',
          'مساحة الأبواب والنوافذ',
          unit: 'م²',
        ),
        InputField(
          'coverage',
          'تغطية اللتر الواحد',
          unit: 'م²/لتر',
          initialValue: '10',
        ),
        InputField(
          'coats',
          'عدد الطبقات',
          initialValue: '2',
        ),
        InputField(
          'materialPrice',
          'سعر اللتر',
          unit: 'عملة',
          initialValue: '5000',
        ),
        InputField(
          'laborPrice',
          'أجرة العمل لكل لتر تقديري',
          unit: 'عملة',
        ),
      ];

    case 'concrete':
      return const [
        InputField('length', 'الطول', unit: 'م'),
        InputField('width', 'العرض', unit: 'م'),
        InputField(
          'thickness',
          'السمك',
          unit: 'م',
          initialValue: '0.1',
        ),
        InputField(
          'materialPrice',
          'سعر المتر المكعب',
          unit: 'عملة',
        ),
        InputField(
          'laborPrice',
          'أجرة العمل للمتر المكعب',
          unit: 'عملة',
        ),
      ];

    default:
      return const [
        InputField('quantity', 'الكمية'),
        InputField('unitPrice', 'سعر الوحدة', unit: 'عملة'),
      ];
  }
}

class EmptyMessage extends StatelessWidget {
  final String message;

  const EmptyMessage(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 42,
              color: appColor,
            ),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

double numberOf(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String formatNumber(num value) {
  if (!value.isFinite) return '0';

  final text = value.toStringAsFixed(2);

  if (text.endsWith('.00')) {
    return text.substring(0, text.length - 3);
  }

  if (text.endsWith('0')) {
    return text.substring(0, text.length - 1);
  }

  return text;
}

String currentDate() {
  final now = DateTime.now();

  String two(int number) => number.toString().padLeft(2, '0');

  return '${now.year}-${two(now.month)}-${two(now.day)} '
      '${two(now.hour)}:${two(now.minute)}';
}

Future<void> copyText(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}