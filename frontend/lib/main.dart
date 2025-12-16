import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (_) => AuthProvider(),
    child: const MyApp(),
  ));
}

/// Ayarlar: backend adresi
const String apiBase = "http://192.168.1.202:5000"; // gerektiğinde kendi backend adresine çevir

class AuthProvider extends ChangeNotifier {
  String? get refreshToken => _refreshToken;
  String? _accessToken;
  String? _refreshToken;

  String? get token => _accessToken;

  // ✅ EKLİYORUZ
  bool get isAuthenticated => _accessToken != null;

  AuthProvider() {
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString("access_token");
    _refreshToken = prefs.getString("refresh_token");
    notifyListeners();
  }

  Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("access_token", access);
    await prefs.setString("refresh_token", refresh);
    _accessToken = access;
    _refreshToken = refresh;
    notifyListeners();
  }

  Future<String?> refreshAccessToken(String refreshToken) async {
  final url = Uri.parse("$apiBase/users/refresh");

  var response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "refresh_token": refreshToken,
    }),
  );

  print("Refresh Token Status: ${response.statusCode}");
  print("Refresh Token Body: ${response.body}");

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final newAccessToken = data["access_token"];
      
    if (newAccessToken != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("access_token", newAccessToken);
      _accessToken = newAccessToken;
      notifyListeners();
    }

    return newAccessToken;
  }

  return null;
}
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("access_token");
    await prefs.remove("refresh_token");
    _accessToken = null;
    _refreshToken = null;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Urun Takip',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
      routes: {
        '/register': (_) => const RegisterPage(),
        '/login': (_) => const LoginPage(),
        '/products': (_) => const ProductsPage(),
        '/products/create': (_) => const CreateProductPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ürün Takip')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text('Kayıt Ol')),
          const SizedBox(height: 10,),
          ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Giriş Yap')),
          const SizedBox(height: 10,),
          ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/products'),
              child: const Text('Ürünlere Git')),
          const SizedBox(height: 16),
          if (auth.isAuthenticated)
            ElevatedButton(
              onPressed: () => auth.logout(),
              child: const Text('Çıkış Yap'),
            ),
            const SizedBox(height: 10,),
        ]),
      ),
    );
  }
}

/// ---------------------- REGISTER ----------------------
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final Map<String, String> data = {};

  bool loading = false;
  String message = "";

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();
    setState(() {
      loading = true;
      message = "";
    });

    final url = Uri.parse('$apiBase/users/register');
    print("➡ Register endpoint: $apiBase/users/register");
    try {
      final res = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "name": data['name'],
            "surname": data['surname'],
            "email": data['email'],
            "password": data['password']
          }));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          message = "Kayıt başarılı";
        });
      } else {
        setState(() {
          message = body['detail'] ?? body['message'] ?? 'Hata oldu';
        });
      }
    } catch (e) {
      setState(() {
        message = "Sunucuya bağlanırken hata: $e";
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Form(
            key: _form,
            child: Column(children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'İsim'),
                onSaved: (v) => data['name'] = v ?? '',
                validator: (v) => (v ?? '').isEmpty ? 'Gerekli' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Soyisim'),
                onSaved: (v) => data['surname'] = v ?? '',
                validator: (v) => (v ?? '').isEmpty ? 'Gerekli' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                onSaved: (v) => data['email'] = v ?? '',
                validator: (v) => (v ?? '').isEmpty ? 'Gerekli' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Parola'),
                obscureText: true,
                onSaved: (v) => data['password'] = v ?? '',
                validator: (v) => (v ?? '').isEmpty ? 'Gerekli' : null,
              ),
              const SizedBox(height: 12),
              loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit, child: const Text('Kayıt Ol')),
              const SizedBox(height: 12),
              Text(message, style: const TextStyle(color: Colors.red)),
            ]),
          )
        ]),
      ),
    );
  }
}

/// ---------------------- LOGIN ----------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final Map<String, String> data = {};
  bool loading = false;
  String message = "";

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();

    setState(() {
      loading = true;
      message = "";
    });

    // OAuth2PasswordRequestForm expects form urlencoded with username & password
    final url = Uri.parse('$apiBase/users/login');
    final body = 'username=${Uri.encodeComponent(data['email']!)}&password=${Uri.encodeComponent(data['password']!)}';

    try {
      final res = await http.post(url,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: body);

      final b = jsonDecode(res.body);
      if (res.statusCode == 200) {
        final token = b['access_token'];
        final refresh = b['refresh_token'];

        await Provider.of<AuthProvider>(context, listen: false)
        .saveTokens(token, refresh);

  Navigator.pushReplacementNamed(context, '/products');
      } else {
        setState(() {
          message = b['detail'] ?? b['message'] ?? 'Giriş başarısız';
        });
      }
    } catch (e) {
      setState(() {
        message = "Bağlanamadı: $e";
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giriş')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Form(
            key: _form,
            child: Column(children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                onSaved: (v) => data['email'] = v ?? '',
                validator: (v) => (v ?? '').isEmpty ? 'Gerekli' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Parola'),
                obscureText: true,
                onSaved: (v) => data['password'] = v ?? '',
                validator: (v) => (v ?? '').isEmpty ? 'Gerekli' : null,
              ),
              const SizedBox(height: 12),
              loading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _login, child: const Text('Giriş')),
              const SizedBox(height: 12),
              Text(message, style: const TextStyle(color: Colors.red)),
            ]),
          )
        ]),
      ),
    );
  }
}

/// ---------------------- PRODUCTS LIST ----------------------
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});
  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List products = [];
  bool loading = false;
  String message = "";

  Future<void> fetchProducts() async {
  setState(() {
    loading = true;
    message = "";
  });

  final auth = Provider.of<AuthProvider>(context, listen: false);

  final token = auth.token;
  if (token == null) {
    setState(() {
      message = "Giriş yapın";
      loading = false;
    });
    return;
  }

  final url = Uri.parse('$apiBase/products/');

  try {
    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    // --- 200 OK ---
    if (res.statusCode == 200) {
      products = res.body.isNotEmpty
          ? (jsonDecode(res.body) as List)
          : [];
      return;

    // --- 401 Unauthorized: token expired ---
    } else if (res.statusCode == 401) {
      // refresh token yoksa direkt çık
      if (auth.refreshToken == null) {
        setState(() {
          message = "Token bulunamadı. Tekrar giriş yapın.";
        });
        return;
      }

      final newToken = await auth.refreshAccessToken(auth.refreshToken!);

      if (newToken != null) {
        // Yeni access token ile tekrar dene
        return await fetchProducts();
      } else {
        setState(() {
          message = "Token süresi doldu. Tekrar giriş yapın.";
        });
        return;
      }

    // --- Diğer hatalar ---
    } else {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      message = body['detail'] ?? body['message'] ?? 'Hata oluştu';
      return;
    }

  } catch (e) {
    message = 'Sunucuya bağlanamadı: $e';
  } finally {
    setState(() {
      loading = false;
    });
  }
}

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürünler'),
        actions: [
          IconButton(
              onPressed: () => Navigator.pushNamed(context, '/products/create'),
              icon: const Icon(Icons.add))
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : message.isNotEmpty
              ? Center(child: Text(message))
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (_, i) {
                    final p = products[i];
                    return ListTile(
                      title: Text("${p['name'] ?? p['name']} (${p['type'] ?? ''})"),
                      subtitle: Text("Adet: ${p['count'] ?? p['count']}"),
                    );
                  },
                ),
    );
  }
}

/// ---------------------- CREATE PRODUCT ----------------------
class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});
  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final _form = GlobalKey<FormState>();
  final Map<String, String> data = {};
  bool loading = false;
  String message = "";

  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) {
      setState(() {
        message = "Giriş yapmalısınız";
      });
      return;
    }

    setState(() {
      loading = true;
      message = "";
    });

    final url = Uri.parse('$apiBase/products/');
    try {
      var res = await http.post(url,
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode({"type": data['type'], "name": data['name'], "count": int.parse(data['count']!)}));

      // 401 hatası alırsak token'ı yenile ve tekrar dene
      if (res.statusCode == 401 && auth.refreshToken != null) {
        final newToken = await auth.refreshAccessToken(auth.refreshToken!);
        if (newToken != null) {
          // Yeni token ile tekrar dene
          res = await http.post(url,
              headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $newToken'},
              body: jsonEncode({"type": data['type'], "name": data['name'], "count": int.parse(data['count']!)}));
        } else {
          setState(() {
            message = "Token süresi doldu. Tekrar giriş yapın.";
          });
          return;
        }
      }

      final b = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          message = b['detail'] ?? b['message'] ?? 'Başarısız';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Hata: $e';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ürün Oluştur')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Form(
            key: _form,
            child: Column(children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Tip'),
                onSaved: (v) => data['type'] = v ?? '',
                validator: (v) => (v ?? '').isEmpty ? 'Gerekli' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'İsim'),
                onSaved: (v) => data['name'] = v ?? '',
                validator: (v) => (v ?? '').isEmpty ? 'Gerekli' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Adet'),
                keyboardType: TextInputType.number,
                onSaved: (v) => data['count'] = v ?? '0',
                validator: (v) => (v ?? '').isEmpty ? 'Gerekli' : null,
              ),
              const SizedBox(height: 12),
              loading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _create, child: const Text('Oluştur')),
              const SizedBox(height: 12),
              Text(message, style: const TextStyle(color: Colors.red)),
            ]),
          )
        ]),
      ),
    );
  }
}
