import 'package:flutter/material.dart';
import 'api.dart';

const Color cNavy = Color(0xFF1B3A5C);
const Color cOrange = Color(0xFFF39C2F);

void main() => runApp(const ParentApp());

class ParentApp extends StatelessWidget {
  const ParentApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منصتي — ولي الأمر',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      theme: ThemeData(useMaterial3: true, primaryColor: cNavy, colorScheme: ColorScheme.fromSeed(seedColor: cNavy)),
      builder: (ctx, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _u = TextEditingController(); final _p = TextEditingController();
  String? _err; bool _busy = false;

  Future<void> _submit() async {
    setState(() { _busy = true; _err = null; });
    try {
      final user = await ManasetyApi.login(_u.text.trim(), _p.text);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChildrenScreen(user: user)));
    } catch (e) {
      setState(() => _err = 'بيانات الدخول غير صحيحة');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: cNavy,
    body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Card(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('منصتي', style: TextStyle(fontSize: 30, color: cNavy, fontWeight: FontWeight.bold)),
        Container(height: 3, width: 60, color: cOrange, margin: const EdgeInsets.symmetric(vertical: 6)),
        const Text('تطبيق ولي الأمر'),
        const SizedBox(height: 16),
        TextField(controller: _u, decoration: const InputDecoration(labelText: 'اسم المستخدم', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: _p, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder())),
        if (_err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_err!, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: cOrange, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? '...' : 'دخول'),
        )),
      ]),
    )))),
  );
}

class ChildrenScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const ChildrenScreen({super.key, required this.user});
  @override
  State<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  List<dynamic> _kids = []; bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await ManasetyApi.get('/parent/children');
      setState(() { _kids = data['children']; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: cNavy, foregroundColor: Colors.white,
      title: Text('مرحبًا، ${widget.user['full_name']}'),
      actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () async {
        await ManasetyApi.logout();
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      })],
    ),
    body: _loading ? const Center(child: CircularProgressIndicator())
      : _kids.isEmpty
        ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('لا يوجد أبناء مرتبطون بهذا الحساب. اطلب من المدرسة ربط الحساب.')))
        : ListView(children: _kids.map<Widget>((k) => Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: cOrange, foregroundColor: Colors.white, child: Icon(Icons.person)),
              title: Text(k['full_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${k['permanent_code']} — ${k['current_section'] ?? 'غير مقيّد'}'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildDetailScreen(child: k))),
            ),
          )).toList()),
  );
}

class ChildDetailScreen extends StatelessWidget {
  final Map<String, dynamic> child;
  const ChildDetailScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: Scaffold(
      appBar: AppBar(
        backgroundColor: cNavy, foregroundColor: Colors.white,
        title: Text(child['full_name']),
        bottom: const TabBar(
          indicatorColor: cOrange, labelColor: Colors.white, unselectedLabelColor: Colors.white70,
          tabs: [Tab(text: 'الحضور'), Tab(text: 'النتائج'), Tab(text: 'الفواتير'), Tab(text: 'الإشعارات')],
        ),
      ),
      body: TabBarView(children: [
        _Loader('/parent/child/${child['id']}/attendance', (d) => _attendanceView(d)),
        _Loader('/parent/child/${child['id']}/results', (d) => _resultsView(d)),
        _Loader('/parent/child/${child['id']}/invoices', (d) => _invoicesView(d)),
        _Loader('/parent/notifications', (d) => _notifsView(d)),
      ]),
    ),
  );

  Widget _attendanceView(dynamic d) {
    final s = d['summary'] as Map;
    return ListView(padding: const EdgeInsets.all(12), children: [
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Column(children: [Text('${s['present']}', style: const TextStyle(fontSize: 28, color: Colors.green)), const Text('حاضر')]),
        Column(children: [Text('${s['absent']}', style: const TextStyle(fontSize: 28, color: Colors.red)), const Text('غائب')]),
        Column(children: [Text('${s['late']}', style: const TextStyle(fontSize: 28, color: cOrange)), const Text('متأخر')]),
        Column(children: [Text('${s['rate']}%', style: const TextStyle(fontSize: 28, color: cNavy, fontWeight: FontWeight.bold)), const Text('النسبة')]),
      ]))),
      const SizedBox(height: 8),
      ...((d['records'] as List).map((r) => ListTile(
        leading: Icon(r['status']=='present' ? Icons.check_circle : r['status']=='absent' ? Icons.cancel : Icons.access_time,
          color: r['status']=='present' ? Colors.green : r['status']=='absent' ? Colors.red : cOrange),
        title: Text(r['date']),
        subtitle: r['notes'] != null ? Text(r['notes']) : null,
      ))),
    ]);
  }

  Widget _resultsView(dynamic d) {
    final results = d['results'] as List;
    if (results.isEmpty) return const Center(child: Text('لا توجد نتائج معتمدة بعد.'));
    return ListView(children: results.map<Widget>((r) => Card(
      margin: const EdgeInsets.all(8),
      child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${r['year']} — ${r['grade']} / ${r['section']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(children: [
          Chip(label: Text(r['status']=='pass' ? 'ناجح' : 'راسب'),
            backgroundColor: r['status']=='pass' ? Colors.green : Colors.red,
            labelStyle: const TextStyle(color: Colors.white)),
          const SizedBox(width: 8),
          Text('المعدل: ${r['average']}'),
        ]),
      ])),
    )).toList());
  }

  Widget _invoicesView(dynamic d) {
    return ListView(children: (d['invoices'] as List).map<Widget>((i) => Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text('${i['number']} — ${i['total_amount']}'),
        subtitle: Text('متبقّي: ${i['remaining']} • ${i['status']}'),
        trailing: Icon(
          i['status']=='paid' ? Icons.check_circle :
          i['status']=='overdue' ? Icons.warning : Icons.pending,
          color: i['status']=='paid' ? Colors.green : i['status']=='overdue' ? Colors.red : cOrange,
        ),
      ),
    )).toList());
  }

  Widget _notifsView(dynamic d) {
    return ListView(children: (d['notifications'] as List).map<Widget>((n) => ListTile(
      leading: const Icon(Icons.message, color: cNavy),
      title: Text(n['kind']),
      subtitle: Text(n['created_at']),
    )).toList());
  }
}

class _Loader extends StatelessWidget {
  final String path;
  final Widget Function(dynamic) builder;
  const _Loader(this.path, this.builder);
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: ManasetyApi.get(path),
    builder: (ctx, snap) {
      if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snap.hasError) return Center(child: Text('خطأ: ${snap.error}'));
      return builder(snap.data);
    },
  );
}
