import 'package:flutter/material.dart';
import 'api.dart';

const Color cNavy = Color(0xFF1B3A5C);
const Color cOrange = Color(0xFFF39C2F);

void main() => runApp(const TeacherApp());

class TeacherApp extends StatelessWidget {
  const TeacherApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منصتي — المعلم',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: cNavy),
        primaryColor: cNavy,
      ),
      builder: (ctx, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
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
  final _u = TextEditingController();
  final _p = TextEditingController();
  String? _err;
  bool _busy = false;

  Future<void> _submit() async {
    setState(() { _busy = true; _err = null; });
    try {
      final user = await ManasetyApi.login(_u.text.trim(), _p.text);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => HomeScreen(user: user),
      ));
    } catch (e) {
      setState(() => _err = 'بيانات الدخول غير صحيحة');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cNavy,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('منصتي', style: TextStyle(fontSize: 30, color: cNavy, fontWeight: FontWeight.bold)),
                Container(height: 3, width: 60, color: cOrange, margin: const EdgeInsets.symmetric(vertical: 6)),
                const Text('بوابة المعلم'),
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
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomeScreen({super.key, required this.user});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _sections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ManasetyApi.get('/teacher/sections');
      setState(() { _sections = data['sections']; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        : ListView(children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('فصولك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ..._sections.map((s) => ListTile(
              title: Text(s['name']),
              subtitle: Text((s['subjects'] as List).map((sub) => sub['name']).join(' • ')),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('فتح شاشة الحضور — ${s['name']}')),
              ),
            )),
          ]),
    );
  }
}
