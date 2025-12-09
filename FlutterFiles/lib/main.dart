import 'dart:convert';
import 'splash_screen.dart';
import 'webview_page.dart';
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
  final TextEditingController _defaultSelfCodeController =
      TextEditingController();

  String? _selectedSelfUrlName;

  final Map<String, String> selfUrlsMap = {
    'گیلان': 'http://food.guilan.ac.ir',
    'علم و صنعت': 'https://stu.iust.ac.ir',
    'شهید بهشتی': 'https://dining.sbu.ac.ir',
    'ارومیه': 'https://nds.urmia.ac.ir',
    'خواجه نصیر طوسی': 'https://refahi.kntu.ac.ir',
    'امیرکبیر': 'https://samad.aut.ac.ir',
    'شریف': 'https://setad.dining.sharif.edu',
    'الزهرا': 'https://samad1.alzahra.ac.ir',
    'بوعلی سینا': 'https://samad.basu.ac.ir',
    'صنعتی کرمانشاه': 'https://food.kut.ac.ir',
    'جیرفت': 'https://dining.ujiroft.ac.ir',
    'امام خمینی': 'https://studentlife.ikiu.ac.ir',
    'شهید رجایی': 'http://food.sru.ac.ir',
  };

  @override
  void initState() {
    super.initState();
    _checkAndShowDisclaimer();
    loadContacts();
  }

  Future<void> _checkAndShowDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAccepted = prefs.getBool('disclaimer_accepted') ?? false;

    if (!hasAccepted && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDisclaimerDialog();
      });
    }
  }

  void _showDisclaimerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'سلب مسئولیت',
              style: TextStyle(
                fontFamily: 'Shabnam',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const SingleChildScrollView(
              child: Text(
                'این ابزار صرفاً برای اهداف آموزشی و آزمایشی ارائه شده است. هیچ‌گونه تضمین یا مسئولیتی درخصوص نحوهٔ استفادهٔ کاربران از این ابزار برعهدهٔ سازنده نیست.\n\n'
                'هر نوع استفاده از این برنامه، از جمله اما نه محدود به:\n'
                '• خودکارسازی تعامل با وب‌سایت‌ها\n'
                '• ارسال درخواست‌های مکرر\n'
                '• انجام عملیات رزرو یا مانیتورینگ\n\n'
                'باید مطابق قوانین، مقررات، سیاست‌های وب‌سایت مقصد و آیین‌نامه‌های مجموعهٔ مربوطه باشد.\n\n'
                'کاربر موظف است قبل از استفاده از این ابزار، تمامی قوانین و شرایط استفاده (Terms of Service) سامانهٔ موردنظر را بررسی کند.\n\n'
                'مسئولیت هرگونه استفادهٔ نادرست، هرگونه نقض قوانین یا هر پیامد احتمالی کاملاً برعهدهٔ کاربر است و توسعه‌دهنده هیچ مسئولیت حقوقی، فنی یا اجرایی در این زمینه ندارد.\n\n'
                'استفاده از این ابزار به‌معنای پذیرش کامل این شرایط است.',
                style: TextStyle(fontFamily: 'Shabnam'),
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('disclaimer_accepted', true);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text(
                  'تایید و ادامه',
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

  Future<void> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactList = prefs.getStringList('contacts') ?? [];
    final defaultUrlName = selfUrlsMap.keys.first;
    setState(() {
      contacts = contactList.map((contact) {
        final data = jsonDecode(contact) as Map<String, dynamic>;
        final storedSelfUrlName = data['selfUrl']?.toString();
        return {
          'name': data['name']?.toString() ?? 'Unknown',
          'username': data['username']?.toString() ?? 'Unknown',
          'password': data['password']?.toString() ?? 'Unknown',
          'selfUrl': selfUrlsMap.containsKey(storedSelfUrlName)
              ? storedSelfUrlName!
              : defaultUrlName,
          'defaultSelfCode': data['defaultSelfCode']?.toString() ?? 'Unknown',
        };
      }).toList();
    });
  }

  Future<void> saveContact(
      String name, String username, String password, String selfUrlName,
      [int? defaultSelfCode]) async {
    final prefs = await SharedPreferences.getInstance();
    final contact = jsonEncode({
      'name': name,
      'username': username,
      'password': password,
      'selfUrl': selfUrlName,
      'defaultSelfCode': defaultSelfCode,
    });
    final contactList = prefs.getStringList('contacts') ?? [];
    contactList.add(contact);
    await prefs.setStringList('contacts', contactList);
    loadContacts();
  }

  Future<void> editContact(int index, String name, String username,
      String password, String selfUrlName,
      [int? defaultSelfCode]) async {
    final prefs = await SharedPreferences.getInstance();
    final contactList = prefs.getStringList('contacts') ?? [];

    // Remove the old contact
    contactList.removeAt(index);

    // Add the updated contact
    final updatedContact = jsonEncode({
      'name': name,
      'username': username,
      'password': password,
      'selfUrl': selfUrlName,
      'defaultSelfCode': defaultSelfCode,
    });
    contactList.insert(index, updatedContact);

    await prefs.setStringList('contacts', contactList);
    loadContacts();
  }

  void _showAddContactDialog() {
    _nameController.clear();
    _usernameController.clear();
    _passwordController.clear();
    _selectedSelfUrlName = null;
    _defaultSelfCodeController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                title: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'اضافه کردن حساب کاربری',
                    style: TextStyle(
                      fontFamily: 'Shabnam',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 20,
                      ),
                      TextField(
                        controller: _nameController,
                        textAlign: TextAlign.right,
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
                        decoration: InputDecoration(
                          labelText: 'پسورد',
                          labelStyle: const TextStyle(fontFamily: 'Shabnam'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedSelfUrlName,
                            hint: const Text(
                              'انتخاب آدرس وب سایت',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontFamily: 'Shabnam'),
                            ),
                            items: selfUrlsMap.keys.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    value,
                                    style:
                                        const TextStyle(fontFamily: 'Shabnam'),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setDialogState(() {
                                _selectedSelfUrlName = newValue;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actionsAlignment: MainAxisAlignment.spaceBetween,
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
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      if (_nameController.text.isEmpty ||
                          _usernameController.text.isEmpty ||
                          _passwordController.text.isEmpty ||
                          _selectedSelfUrlName == null) {
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
                        _selectedSelfUrlName!,
                      );
                      _nameController.clear();
                      _usernameController.clear();
                      _passwordController.clear();
                      _selectedSelfUrlName = null;
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
              );
            },
          ),
        );
      },
    );
  }

  void _showEditContactDialog(Map<String, String> contact, int index) {
    _nameController.text = contact["name"]!;
    _usernameController.text = contact["username"]!;
    _passwordController.text = contact["password"]!;
    _selectedSelfUrlName = contact["selfUrl"]!;
    _defaultSelfCodeController.text = contact["defaultSelfCode"] ?? '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                title: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'ویرایش حساب کاربری',
                    style: TextStyle(
                      fontFamily: 'Shabnam',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 20,
                      ),
                      TextField(
                        controller: _nameController,
                        textAlign: TextAlign.right,
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
                        decoration: InputDecoration(
                          labelText: 'پسورد',
                          labelStyle: const TextStyle(fontFamily: 'Shabnam'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedSelfUrlName,
                            hint: const Text(
                              'انتخاب آدرس وب سایت',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontFamily: 'Shabnam'),
                            ),
                            items: selfUrlsMap.keys.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    value,
                                    style:
                                        const TextStyle(fontFamily: 'Shabnam'),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setDialogState(() {
                                _selectedSelfUrlName = newValue;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _defaultSelfCodeController,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          labelText: 'سلف پیش فرض',
                          labelStyle: const TextStyle(fontFamily: 'Shabnam'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actionsAlignment: MainAxisAlignment.spaceBetween,
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
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      if (_nameController.text.isEmpty ||
                          _usernameController.text.isEmpty ||
                          _passwordController.text.isEmpty ||
                          _selectedSelfUrlName == null) {
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
                      int? defaultSelfCode =
                          int.tryParse(_defaultSelfCodeController.text);

                      editContact(
                        index,
                        _nameController.text,
                        _usernameController.text,
                        _passwordController.text,
                        _selectedSelfUrlName!,
                        defaultSelfCode,
                      );
                      _nameController.clear();
                      _usernameController.clear();
                      _passwordController.clear();
                      _selectedSelfUrlName = null;
                      _defaultSelfCodeController.clear();
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
              );
            },
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
        fontFamily: 'shabnam',
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
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final actualSelfUrl =
                                selfUrlsMap[contact['selfUrl']];

                            if (actualSelfUrl == null) {
                              return;
                            }
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WebViewApp(
                                  username: contact['username']!,
                                  password: contact['password']!,
                                  selfUrl: actualSelfUrl,
                                  defaultSelfCode: int.tryParse(
                                      contact['defaultSelfCode'] ?? ''),
                                  onDefaultSelfSelected: (newSelfCode) {
                                    editContact(
                                      index,
                                      contact['name']!,
                                      contact['username']!,
                                      contact['password']!,
                                      contact['selfUrl']!,
                                      newSelfCode,
                                    );
                                  },
                                ),
                              ),
                            );
                            loadContacts();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact['name']!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(contact['username']!),
                              ],
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        child: Icon(Icons.edit),
                        onTap: () {
                          _showEditContactDialog(contact, index);
                        },
                      ),
                      SizedBox(
                        width: 16,
                      ),
                      Icon(Icons.arrow_forward_ios),
                      SizedBox(
                        width: 16,
                      )
                    ],
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
