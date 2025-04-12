import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewApp extends StatefulWidget {
  final String username;
  final String password;

  const WebViewApp({super.key, required this.username, required this.password});

  @override
  State<WebViewApp> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  late WebViewController controller;
  List<String> itemList = [];
  int? selectedIndex;
  bool getFood = false;

  @override
  void initState() {
    super.initState();
    initializeWebViewController();
  }

  @override
  void dispose() {
    controller.clearCache();
    super.dispose();
  }

  void initializeWebViewController() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('Flutter', onMessageReceived: handleJavaScriptMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: handlePageFinished,
        ),
      )
      ..loadRequest(Uri.parse('http://food.guilan.ac.ir/index.rose'));
  }

  void handleJavaScriptMessage(JavaScriptMessage message) {
    if (!mounted) return;

    final String jsonString = message.message;
    if (jsonString == "Done") {
      setState(() => getFood = true);
    } else {
      processLabels(jsonString);
    }
  }

  void processLabels(String jsonString) {
    try {
      final List<dynamic> decodedList = jsonDecode(jsonString);
      final List<String> labelList = decodedList.map((item) => item.toString()).toList();
      final List<String> extractedTexts = [];

      for (String label in labelList) {
        List<String> parts = label.split('|').map((part) => part.trim()).toList();
        if (parts.length > 1) {
          extractedTexts.add(parts[1]);
        }
      }

      if (mounted) {
        setState(() {
          itemList = extractedTexts;
          if (itemList.isNotEmpty && selectedIndex == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _showItemSelectionDialog();
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در پردازش لیست غذاها: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Shabnam'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> handlePageFinished(String url) async {
    print('Page finished loading: $url');
    if (!mounted) return;

    try {
      if (url == 'http://food.guilan.ac.ir/index.rose') {
        await autoLogin();
      } else if (url == 'http://food.guilan.ac.ir/index/index.rose') {
        await openFoodPage();
      } else if (url == 'https://food.guilan.ac.ir/nurture/user/multi/reserve/showPanel.rose?selectedSelfDefId=4') {
        await _getHtmlContent();
      } else if (url == 'https://food.guilan.ac.ir/nurture/user/multi/reserve/reserve.rose') {
        await _getHtmlContent();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در بارگذاری صفحه: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Shabnam'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> autoLogin() async {
    final String username = widget.username;
    final String password = widget.password;

    final String jsCode = '''
      function checkAndLogin() {
        const checkbox = document.getElementById('redirect-remember');
        if (checkbox && checkbox.checked) {
          checkbox.checked = false;
          document.getElementById('btn-redirect-cancel').click();
        }
        document.querySelector('#username').value = '$username';
        document.querySelector('#password').value = '$password';
        const submitButton = document.querySelector('button[type="submit"]');
        if (submitButton && submitButton.disabled) {
          submitButton.disabled = false;
          submitButton.click();
        }
      }
      setTimeout(checkAndLogin, 1500);
    ''';

    try {
      await controller.runJavaScript(jsCode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در ورود به سیستم: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Shabnam'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> openFoodPage() async {
    const String jsCode = '''
      window.location.href = 'https://food.guilan.ac.ir/nurture/user/multi/reserve/showPanel.rose?selectedSelfDefId=4';
    ''';
    try {
      await controller.runJavaScript(jsCode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در انتقال به صفحه غذا: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Shabnam'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _getHtmlContent() async {
    const String jsCode = '''
      const labels = Array.from(document.querySelectorAll('label'));
      const filteredLabels = labels
        .filter(label => label.getAttribute('for')?.startsWith('userWeekReserves.selected') ?? false)
        .map(label => label.textContent);
      Flutter.postMessage(JSON.stringify(filteredLabels));
    ''';
    try {
      await controller.runJavaScript(jsCode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در دریافت لیست غذاها: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Shabnam'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showItemSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'انتخاب غذا',
                style: TextStyle(
                  fontFamily: 'Shabnam',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: itemList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      itemList[index],
                      style: const TextStyle(fontFamily: 'Shabnam'),
                    ),
                    onTap: () {
                      if (mounted) {
                        setState(() => selectedIndex = index);
                      }
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                      _refreshAndCheckElement(selectedIndex!);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: const Text(
                  'انصراف',
                  style: TextStyle(fontFamily: 'Shabnam', color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refreshAndCheckElement(int index) async {
    try {
      // await controller.reload();

      String jsCode = '''
        location. reload()
        window.alert = function(message){
          console.log("acc"+message);
          return true;
        }    
        var element = document.getElementById('buyFreeFoodIconSpanuserWeekReserves.selected$index');
        if (element) {
          Flutter.postMessage("Done");
          console.log('Element clicked: buyFreeFoodIconSpanuserWeekReserves.selected$index');
          document.querySelector('img[src="/images/buy.png"]').click();
          document.getElementById('doReservBtn').click();
        } else {
          console.log('Element not found: buyFreeFoodIconSpanuserWeekReserves.selected$index');
        }
      ''';

      Future.delayed(const Duration(milliseconds: 500), () async {
        if (!mounted) return;

        if (!getFood) {
          try {
            await controller.runJavaScript(jsCode);
            if (mounted && !getFood) {
              _refreshAndCheckElement(index);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'خطا در بروزرسانی: ${e.toString()}',
                    style: const TextStyle(fontFamily: 'Shabnam'),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } else if (mounted) {
          setState(() {
            itemList.clear();
            selectedIndex = null;
            getFood = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در بررسی غذا: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Shabnam'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_forward_ios_rounded)),
          ],
          leading: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                const String jsCode = '''
                    window.location.href = 'https://food.guilan.ac.ir/accessMgmt/action/logout.rose';
                  ''';

                await controller.runJavaScript(jsCode);

                if (mounted && context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted && context.mounted && ScaffoldMessenger.of(context).mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'خطا در خروج از سیستم: ${e.toString()}',
                        style: const TextStyle(fontFamily: 'Shabnam'),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ),
        floatingActionButton: selectedIndex== null ? Container() : FloatingActionButton(
          onPressed: () {
            setState(() {


              getFood = true;
            });
          },

          child:const Icon(Icons.stop),
          foregroundColor: Colors.white,
          backgroundColor: Colors.purple,

          shape: CircleBorder(),
        )  ,
        body: Column(
          children: [
            Expanded(
              child: WebViewWidget(controller: controller),
            ),
            if (selectedIndex != null && itemList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'غذا انتخاب شده: ${itemList[selectedIndex!]}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Shabnam',
                    fontSize: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
