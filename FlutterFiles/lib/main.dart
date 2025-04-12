import 'dart:convert';
import 'package:RoboFood/splash_screen.dart';
import 'package:RoboFood/webview_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreenWithAnimation(),
    );
  }
}

class ContactListPage extends StatefulWidget {
  const ContactListPage({super.key});

  @override
  State<ContactListPage> createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  List<Map<String, String>> contacts = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadContacts();
  }


  Future<void> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactList = prefs.getStringList('contacts') ?? [];
    setState(() {
      contacts = contactList.map((contact) {
        final data = jsonDecode(contact) as Map<String, dynamic>;
        return {
          'name': data['name']?.toString() ?? 'Unknown',
          'username': data['username']?.toString() ?? 'Unknown',
          'password': data['password']?.toString() ?? 'Unknown',
        };
      }).toList();
    });
  }

  Future<void> saveContact(String name, String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final contact = jsonEncode({
      'name': name,
      'username': username,
      'password': password,
    });
    final contactList = prefs.getStringList('contacts') ?? [];
    contactList.add(contact);
    await prefs.setStringList('contacts', contactList);
    loadContacts();
  }

  void _showAddContactDialog() {
    _nameController.clear();
    _usernameController.clear();
    _passwordController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          // Force RTL layout
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)
            ),
            title: const FittedBox(
              fit: BoxFit.scaleDown, // Scales text down if needed
              child: Text(
                'اضافه کردن حساب کاربری',
                style: TextStyle(
                  fontFamily: 'Shabnam',
                  fontWeight: FontWeight.bold,
                  fontSize: 20, // Base size (will scale down if space is limited)
                ),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20,),
                  TextField(
                    controller: _nameController,
                    textAlign: TextAlign.right, // RTL alignment
                    decoration: InputDecoration(
                      labelText: 'حساب کاربری',
                      labelStyle: const TextStyle(fontFamily: 'Shabnam'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usernameController,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'یوزرنیم',
                      labelStyle: const TextStyle(fontFamily: 'Shabnam'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    textAlign: TextAlign.right,
                    obscureText: true, // Hide password
                    decoration: InputDecoration(
                      labelText: 'پسورد',
                      labelStyle: const TextStyle(fontFamily: 'Shabnam'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween, // Better button spacing
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'لغو',
                  style: TextStyle(
                    fontFamily: 'Shabnam',
                    color: Colors.red,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Modern button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  if (_nameController.text.isEmpty || _usernameController.text.isEmpty || _passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'لطفا تمام فیلدها را پر کنید!',
                          style: TextStyle(fontFamily: 'Shabnam'),
                        ),
                      ),
                    );
                    return;
                  }
                  saveContact(
                    _nameController.text,
                    _usernameController.text,
                    _passwordController.text,
                  );
                  _nameController.clear();
                  _usernameController.clear();
                  _passwordController.clear();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'ذخیره',
                  style: TextStyle(
                    fontFamily: 'Shabnam',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'shabnam', // Add your custom Persian font here
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'حساب های کاربری',
              textAlign: TextAlign.right,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.add,
              size: 26,
            ),
            onPressed: _showAddContactDialog,
          ),
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      contact['name']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(contact['username']!),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WebViewApp(
                            username: contact['username']!,
                            password: contact['password']!,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

