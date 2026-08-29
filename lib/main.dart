import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FarmSphereApp());
}

// COLORS
const green = Color(0xFF166534);
const lightGreen = Color(0xFF22C55E);
const gold = Color(0xFFD4A017);
const bg = Color(0xFFF7F8F3);
const darkBg = Color(0xFF101A13);
const darkCard = Color(0xFF19261C);
const gray = Color(0xFF64748B);
const red = Color(0xFFDC2626);

// STORAGE
class Store {
  static Future<List<Map<String, dynamic>>> get(String key) async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(key);
    if (v == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(v));
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(
      String key,
      List<Map<String, dynamic>> data,
      ) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key, jsonEncode(data));
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    for (final k in [
      'fields',
      'crops',
      'irrigation',
      'fertilizer',
      'workers',
      'harvest',
      'expenses',
      'sales',
    ]) {
      await p.remove(k);
    }
  }
}

// APP
class FarmSphereApp extends StatefulWidget {
  const FarmSphereApp({super.key});

  @override
  State<FarmSphereApp> createState() => _FarmSphereAppState();
}

class _FarmSphereAppState extends State<FarmSphereApp> {
  bool dark = false;

  @override
  void initState() {
    super.initState();
    loadTheme();
  }

  Future<void> loadTheme() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => dark = p.getBool('dark') ?? false);
  }

  Future<void> changeTheme(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark', value);
    if (mounted) setState(() => dark = value);
  }

  ThemeData theme(bool dark) {
    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: dark ? darkBg : bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? darkBg : bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: dark ? darkCard : Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF202D23) : const Color(0xFFF0F2EC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FarmSphere',
      theme: theme(false),
      darkTheme: theme(true),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: FarmHome(
        dark: dark,
        onTheme: changeTheme,
      ),
    );
  }
}

// HOME
class FarmHome extends StatefulWidget {
  final bool dark;
  final Future<void> Function(bool) onTheme;

  const FarmHome({
    super.key,
    required this.dark,
    required this.onTheme,
  });

  @override
  State<FarmHome> createState() => _FarmHomeState();
}

class _FarmHomeState extends State<FarmHome> {
  int selected = 0;

  final fields = <Map<String, dynamic>>[];
  final crops = <Map<String, dynamic>>[];
  final irrigation = <Map<String, dynamic>>[];
  final fertilizer = <Map<String, dynamic>>[];
  final workers = <Map<String, dynamic>>[];
  final harvest = <Map<String, dynamic>>[];
  final expenses = <Map<String, dynamic>>[];
  final sales = <Map<String, dynamic>>[];

  final names = const [
    'Dashboard',
    'Fields',
    'Crops',
    'Irrigation',
    'Fertilizer',
    'Workers',
    'Harvest',
    'Expenses',
    'Sales',
    'Reports',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    fields.addAll(await Store.get('fields'));
    crops.addAll(await Store.get('crops'));
    irrigation.addAll(await Store.get('irrigation'));
    fertilizer.addAll(await Store.get('fertilizer'));
    workers.addAll(await Store.get('workers'));
    harvest.addAll(await Store.get('harvest'));
    expenses.addAll(await Store.get('expenses'));
    sales.addAll(await Store.get('sales'));
    if (mounted) setState(() {});
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  Future<void> clearAll() async {
    await Store.clear();

    fields.clear();
    crops.clear();
    irrigation.clear();
    fertilizer.clear();
    workers.clear();
    harvest.clear();
    expenses.clear();
    sales.clear();

    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: FarmDrawer(
        selected: selected,
        onSelect: (i) {
          Navigator.pop(context);
          setState(() => selected = i);
        },
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          names[selected],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: selected,
          children: [
            Dashboard(
              fields: fields,
              crops: crops,
              workers: workers,
              harvest: harvest,
              expenses: expenses,
              sales: sales,
            ),
            FieldsPage(data: fields, refresh: refresh),
            CropsPage(data: crops, refresh: refresh),
            SimplePage(
              title: 'Irrigation',
              icon: Icons.water_drop_outlined,
              data: irrigation,
              fields: fields,
              storage: 'irrigation',
              refresh: refresh,
              field1: 'Water Amount',
              field2: 'Date',
            ),
            SimplePage(
              title: 'Fertilizer',
              icon: Icons.grass_outlined,
              data: fertilizer,
              fields: fields,
              storage: 'fertilizer',
              refresh: refresh,
              field1: 'Fertilizer Name',
              field2: 'Quantity',
            ),
            WorkersPage(data: workers, refresh: refresh),
            SimplePage(
              title: 'Harvest',
              icon: Icons.agriculture_outlined,
              data: harvest,
              fields: fields,
              storage: 'harvest',
              refresh: refresh,
              field1: 'Crop',
              field2: 'Quantity',
            ),
            MoneyPage(
              title: 'Expenses',
              icon: Icons.payments_outlined,
              data: expenses,
              storage: 'expenses',
              refresh: refresh,
              amountLabel: 'Amount',
            ),
            MoneyPage(
              title: 'Sales',
              icon: Icons.point_of_sale_outlined,
              data: sales,
              storage: 'sales',
              refresh: refresh,
              amountLabel: 'Sale Amount',
            ),
            Reports(
              fields: fields,
              crops: crops,
              workers: workers,
              harvest: harvest,
              expenses: expenses,
              sales: sales,
            ),
            SettingsPage(
              dark: widget.dark,
              onTheme: widget.onTheme,
              onClear: clearAll,
            ),
          ],
        ),
      ),
    );
  }
}

// DRAWER
class FarmDrawer extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const FarmDrawer({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Dashboard', Icons.dashboard_outlined),
      ('Fields', Icons.landscape_outlined),
      ('Crops', Icons.grass_outlined),
      ('Irrigation', Icons.water_drop_outlined),
      ('Fertilizer', Icons.eco_outlined),
      ('Workers', Icons.groups_outlined),
      ('Harvest', Icons.agriculture_outlined),
      ('Expenses', Icons.payments_outlined),
      ('Sales', Icons.point_of_sale_outlined),
      ('Reports', Icons.bar_chart_outlined),
      ('Settings', Icons.settings_outlined),
    ];

    return Drawer(
      width: MediaQuery.sizeOf(context).width * .82,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              color: green,
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 27,
                    backgroundColor: gold,
                    child: Icon(
                      Icons.agriculture_rounded,
                      color: Colors.white,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FarmSphere',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Smart Farm Management',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final active = selected == i;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: ListTile(
                      selected: active,
                      selectedTileColor: gold.withOpacity(.13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: Icon(
                        items[i].$2,
                        color: active ? gold : gray,
                      ),
                      title: Text(
                        items[i].$1,
                        style: TextStyle(
                          color: active ? gold : null,
                          fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      onTap: () => onSelect(i),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: green,
                    child: Icon(
                      Icons.person_outline,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Farm Manager',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
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

// DASHBOARD
class Dashboard extends StatelessWidget {
  final List<Map<String, dynamic>> fields;
  final List<Map<String, dynamic>> crops;
  final List<Map<String, dynamic>> workers;
  final List<Map<String, dynamic>> harvest;
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> sales;

  const Dashboard({
    super.key,
    required this.fields,
    required this.crops,
    required this.workers,
    required this.harvest,
    required this.expenses,
    required this.sales,
  });

  double sum(List<Map<String, dynamic>> list) {
    return list.fold(
      0,
          (a, e) => a + ((e['amount'] ?? 0) as num).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expense = sum(expenses);
    final sale = sum(sales);
    final profit = sale - expense;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      children: [
        Text(
          'Welcome back 👋',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Farm Overview',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (_, c) {
            final two = c.maxWidth >= 390;

            final cards = [
              DashCard(
                icon: Icons.landscape_outlined,
                title: 'Fields',
                value: '${fields.length}',
                color: green,
              ),
              DashCard(
                icon: Icons.grass_outlined,
                title: 'Crops',
                value: '${crops.length}',
                color: lightGreen,
              ),
              DashCard(
                icon: Icons.groups_outlined,
                title: 'Workers',
                value: '${workers.length}',
                color: gold,
              ),
              DashCard(
                icon: Icons.agriculture_outlined,
                title: 'Harvest',
                value: '${harvest.length}',
                color: green,
              ),
            ];

            if (!two) {
              return Column(
                children: [
                  for (final card in cards) ...[
                    card,
                    const SizedBox(height: 10),
                  ],
                ],
              );
            }

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: cards,
            );
          },
        ),
        const SizedBox(height: 22),
        const Text(
          'Financial Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                FinanceRow(
                  title: 'Total Sales',
                  value: 'Rs ${sale.toStringAsFixed(0)}',
                  icon: Icons.trending_up,
                  color: lightGreen,
                ),
                const Divider(height: 22),
                FinanceRow(
                  title: 'Total Expenses',
                  value: 'Rs ${expense.toStringAsFixed(0)}',
                  icon: Icons.trending_down,
                  color: red,
                ),
                const Divider(height: 22),
                FinanceRow(
                  title: 'Net Balance',
                  value: 'Rs ${profit.toStringAsFixed(0)}',
                  icon: Icons.account_balance_wallet_outlined,
                  color: gold,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Quick Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.eco_outlined, color: lightGreen, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fields.isEmpty
                        ? 'Start by adding your first field.'
                        : '${fields.length} field(s) are currently registered.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// FIELDS
class FieldsPage extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final VoidCallback refresh;

  const FieldsPage({
    super.key,
    required this.data,
    required this.refresh,
  });

  @override
  State<FieldsPage> createState() => _FieldsPageState();
}

class _FieldsPageState extends State<FieldsPage> {
  void add() {
    final name = TextEditingController();
    final area = TextEditingController();
    final location = TextEditingController();

    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Add Field'),
        content: FormBox(
          children: [
            Field(controller: name, label: 'Field Name'),
            Field(controller: area, label: 'Area'),
            Field(controller: location, label: 'Location'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: green),
            onPressed: () async {
              if (name.text.trim().isEmpty) return;

              widget.data.add({
                'name': name.text.trim(),
                'area': area.text.trim(),
                'location': location.text.trim(),
              });

              await Store.save('fields', widget.data);
              if (d.mounted) Navigator.pop(d);
              widget.refresh();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: gold,
        foregroundColor: Colors.white,
        onPressed: add,
        icon: const Icon(Icons.add),
        label: const Text('Add Field'),
      ),
      body: widget.data.isEmpty
          ? const Empty(icon: Icons.landscape_outlined, text: 'No fields added')
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: widget.data.length,
        itemBuilder: (_, i) {
          final x = widget.data[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEAF6EA),
                child: Icon(
                  Icons.landscape_outlined,
                  color: green,
                ),
              ),
              title: Text(
                x['name'].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${x['area']} • ${x['location']}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  widget.data.removeAt(i);
                  await Store.save('fields', widget.data);
                  widget.refresh();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// CROPS
class CropsPage extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final VoidCallback refresh;

  const CropsPage({
    super.key,
    required this.data,
    required this.refresh,
  });

  @override
  State<CropsPage> createState() => _CropsPageState();
}

class _CropsPageState extends State<CropsPage> {
  void add() {
    final crop = TextEditingController();
    final season = TextEditingController();
    final area = TextEditingController();

    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Add Crop'),
        content: FormBox(
          children: [
            Field(controller: crop, label: 'Crop Name'),
            Field(controller: season, label: 'Season'),
            Field(controller: area, label: 'Area'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: green),
            onPressed: () async {
              if (crop.text.trim().isEmpty) return;

              widget.data.add({
                'name': crop.text.trim(),
                'season': season.text.trim(),
                'area': area.text.trim(),
              });

              await Store.save('crops', widget.data);
              if (d.mounted) Navigator.pop(d);
              widget.refresh();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: green,
        foregroundColor: Colors.white,
        onPressed: add,
        icon: const Icon(Icons.add),
        label: const Text('Add Crop'),
      ),
      body: widget.data.isEmpty
          ? const Empty(icon: Icons.grass_outlined, text: 'No crops added')
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: widget.data.length,
        itemBuilder: (_, i) {
          final x = widget.data[i];

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEAF6EA),
                child: Icon(Icons.grass_outlined, color: green),
              ),
              title: Text(
                x['name'].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${x['season']} • ${x['area']}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  widget.data.removeAt(i);
                  await Store.save('crops', widget.data);
                  widget.refresh();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// SIMPLE RECORD PAGE
class SimplePage extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> data;
  final List<Map<String, dynamic>> fields;
  final String storage;
  final VoidCallback refresh;
  final String field1;
  final String field2;

  const SimplePage({
    super.key,
    required this.title,
    required this.icon,
    required this.data,
    required this.fields,
    required this.storage,
    required this.refresh,
    required this.field1,
    required this.field2,
  });

  @override
  State<SimplePage> createState() => _SimplePageState();
}

class _SimplePageState extends State<SimplePage> {
  void add() {
    final one = TextEditingController();
    final two = TextEditingController();

    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Add ${widget.title}'),
        content: FormBox(
          children: [
            Field(controller: one, label: widget.field1),
            Field(controller: two, label: widget.field2),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: green),
            onPressed: () async {
              if (one.text.trim().isEmpty) return;

              widget.data.add({
                'one': one.text.trim(),
                'two': two.text.trim(),
              });

              await Store.save(widget.storage, widget.data);
              if (d.mounted) Navigator.pop(d);
              widget.refresh();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: green,
        foregroundColor: Colors.white,
        onPressed: add,
        icon: const Icon(Icons.add),
        label: Text('Add ${widget.title}'),
      ),
      body: widget.data.isEmpty
          ? Empty(icon: widget.icon, text: 'No ${widget.title.toLowerCase()} records')
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: widget.data.length,
        itemBuilder: (_, i) {
          final x = widget.data[i];

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: gold.withOpacity(.12),
                child: Icon(widget.icon, color: gold),
              ),
              title: Text(
                x['one'].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                x['two'].toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  widget.data.removeAt(i);
                  await Store.save(widget.storage, widget.data);
                  widget.refresh();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// WORKERS
class WorkersPage extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final VoidCallback refresh;

  const WorkersPage({
    super.key,
    required this.data,
    required this.refresh,
  });

  @override
  State<WorkersPage> createState() => _WorkersPageState();
}

class _WorkersPageState extends State<WorkersPage> {
  void add() {
    final name = TextEditingController();
    final role = TextEditingController();
    final phone = TextEditingController();

    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Add Worker'),
        content: FormBox(
          children: [
            Field(controller: name, label: 'Full Name'),
            Field(controller: role, label: 'Role'),
            Field(controller: phone, label: 'Phone'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: gold),
            onPressed: () async {
              if (name.text.trim().isEmpty) return;

              widget.data.add({
                'name': name.text.trim(),
                'role': role.text.trim(),
                'phone': phone.text.trim(),
              });

              await Store.save('workers', widget.data);
              if (d.mounted) Navigator.pop(d);
              widget.refresh();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: gold,
        foregroundColor: Colors.white,
        onPressed: add,
        icon: const Icon(Icons.add),
        label: const Text('Add Worker'),
      ),
      body: widget.data.isEmpty
          ? const Empty(icon: Icons.groups_outlined, text: 'No workers added')
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: widget.data.length,
        itemBuilder: (_, i) {
          final x = widget.data[i];

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.all(11),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFF7DD),
                child: Icon(Icons.person_outline, color: gold),
              ),
              title: Text(
                x['name'].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${x['role']} • ${x['phone']}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  widget.data.removeAt(i);
                  await Store.save('workers', widget.data);
                  widget.refresh();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// MONEY PAGE
class MoneyPage extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> data;
  final String storage;
  final VoidCallback refresh;
  final String amountLabel;

  const MoneyPage({
    super.key,
    required this.title,
    required this.icon,
    required this.data,
    required this.storage,
    required this.refresh,
    required this.amountLabel,
  });

  @override
  State<MoneyPage> createState() => _MoneyPageState();
}

class _MoneyPageState extends State<MoneyPage> {
  double total() => widget.data.fold(
    0,
        (a, e) => a + ((e['amount'] ?? 0) as num).toDouble(),
  );

  void add() {
    final title = TextEditingController();
    final amount = TextEditingController();

    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Add ${widget.title}'),
        content: FormBox(
          children: [
            Field(controller: title, label: 'Title'),
            Field(
              controller: amount,
              label: widget.amountLabel,
              number: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: green),
            onPressed: () async {
              if (title.text.trim().isEmpty) return;

              widget.data.add({
                'title': title.text.trim(),
                'amount': double.tryParse(amount.text) ?? 0,
              });

              await Store.save(widget.storage, widget.data);
              if (d.mounted) Navigator.pop(d);
              widget.refresh();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: green,
        foregroundColor: Colors.white,
        onPressed: add,
        icon: const Icon(Icons.add),
        label: Text('Add ${widget.title}'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: green,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total ${widget.title}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Rs ${total().toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.data.isEmpty
                ? Empty(icon: widget.icon, text: 'No records added')
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: widget.data.length,
              itemBuilder: (_, i) {
                final x = widget.data[i];

                return Card(
                  margin: const EdgeInsets.only(bottom: 9),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: gold.withOpacity(.12),
                      child: Icon(widget.icon, color: gold),
                    ),
                    title: Text(
                      x['title'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Rs ${x['amount']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            widget.data.removeAt(i);
                            await Store.save(
                              widget.storage,
                              widget.data,
                            );
                            widget.refresh();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// REPORTS
class Reports extends StatelessWidget {
  final List<Map<String, dynamic>> fields;
  final List<Map<String, dynamic>> crops;
  final List<Map<String, dynamic>> workers;
  final List<Map<String, dynamic>> harvest;
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> sales;

  const Reports({
    super.key,
    required this.fields,
    required this.crops,
    required this.workers,
    required this.harvest,
    required this.expenses,
    required this.sales,
  });

  double sum(List<Map<String, dynamic>> data) {
    return data.fold(
      0,
          (a, e) => a + ((e['amount'] ?? 0) as num).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sale = sum(sales);
    final expense = sum(expenses);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
      children: [
        const Text(
          'Farm Reports',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Live statistics from your saved records.',
          style: TextStyle(color: gray),
        ),
        const SizedBox(height: 18),
        ReportRow('Fields', '${fields.length}', Icons.landscape, green),
        ReportRow('Crops', '${crops.length}', Icons.grass, lightGreen),
        ReportRow('Workers', '${workers.length}', Icons.groups, gold),
        ReportRow('Harvest Records', '${harvest.length}', Icons.agriculture, green),
        ReportRow(
          'Total Sales',
          'Rs ${sale.toStringAsFixed(0)}',
          Icons.trending_up,
          lightGreen,
        ),
        ReportRow(
          'Total Expenses',
          'Rs ${expense.toStringAsFixed(0)}',
          Icons.trending_down,
          red,
        ),
        ReportRow(
          'Net Profit',
          'Rs ${(sale - expense).toStringAsFixed(0)}',
          Icons.account_balance_wallet,
          gold,
        ),
      ],
    );
  }
}

// SETTINGS
class SettingsPage extends StatelessWidget {
  final bool dark;
  final Future<void> Function(bool) onTheme;
  final Future<void> Function() onClear;

  const SettingsPage({
    super.key,
    required this.dark,
    required this.onTheme,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: gold.withOpacity(.12),
              child: Icon(
                dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                color: gold,
              ),
            ),
            title: const Text(
              'Dark Mode',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              dark ? 'Dark theme enabled' : 'Light theme enabled',
            ),
            trailing: Switch(
              value: dark,
              activeColor: gold,
              onChanged: onTheme,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEAF6EA),
              child: Icon(Icons.storage_outlined, color: green),
            ),
            title: const Text(
              'Local Storage',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Your farm records are saved on this device.',
              maxLines: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFEEEE),
              child: Icon(Icons.delete_sweep_outlined, color: red),
            ),
            title: const Text(
              'Clear All Data',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Remove all saved farm records.',
              maxLines: 2,
            ),
            onTap: () async {
              final ok = await confirm(context);

              if (ok) {
                await onClear();
              }
            },
          ),
        ),
        const SizedBox(height: 28),
        const Center(
          child: Column(
            children: [
              Icon(
                Icons.agriculture_rounded,
                color: green,
                size: 38,
              ),
              SizedBox(height: 6),
              Text(
                'FarmSphere',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Smart Farm Management',
                style: TextStyle(
                  color: gray,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// COMPONENTS
class DashCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const DashCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: gray,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

class FinanceRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const FinanceRow({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class ReportRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const ReportRow(
      this.title,
      this.value,
      this.icon,
      this.color, {
        super.key,
      });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FormBox extends StatelessWidget {
  final List<Widget> children;

  const FormBox({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: dialogWidth(context),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

class Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool number;

  const Field({
    super.key,
    required this.controller,
    required this.label,
    this.number = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class Empty extends StatelessWidget {
  final IconData icon;
  final String text;

  const Empty({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: gray),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: gray),
            ),
          ],
        ),
      ),
    );
  }
}

// HELPERS
double dialogWidth(BuildContext context) {
  return (MediaQuery.sizeOf(context).width - 48).clamp(250.0, 420.0);
}

Future<bool> confirm(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      title: const Text('Clear All Data'),
      content: const Text(
        'Are you sure you want to remove all saved records?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(d, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: red),
          onPressed: () => Navigator.pop(d, true),
          child: const Text('Clear'),
        ),
      ],
    ),
  );

  return result ?? false;
}