import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewApp extends StatefulWidget {
  final String username;
  final String password;
  final String selfUrl;
  final int? defaultSelfCode;
  final Function(int)? onDefaultSelfSelected;
  const WebViewApp({
    super.key,
    required this.username,
    required this.password,
    required this.selfUrl,
    this.defaultSelfCode,
    this.onDefaultSelfSelected,
  });
  @override
  State<WebViewApp> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  late WebViewController controller;
  List<String> itemList = [];
  int? selectedIndex;
  bool getFood = false;
  int _speed = 500;
  Map<String, int> selfOptions = {};
  int? selectedSelfCode;

  @override
  void initState() {
    super.initState();
    selectedSelfCode = widget.defaultSelfCode;
    initializeWebViewController();
  }

  @override
  void dispose() {
    controller.clearCache();
    super.dispose();
  }

  void _showSpeedDialog() {
    TextEditingController controller = TextEditingController(
      text: _speed.toInt().toString(),
    );

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('سرعت رفرش'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'میلی ثانیه',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لغو'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null && value >= 0) {
                  setState(() {
                    _speed = value;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('ذخیره', style: TextStyle()),
            ),
          ],
        ),
      ),
    );
  }

  void initializeWebViewController() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')
      ..addJavaScriptChannel(
        'Flutter',
        onMessageReceived: handleJavaScriptMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: handlePageFinished),
      )
      ..loadRequest(Uri.parse('${widget.selfUrl}/index.rose'));
  }

  void handleJavaScriptMessage(JavaScriptMessage message) {
    if (!mounted) return;

    final String jsonString = message.message;
    if (jsonString == "Done") {
      setState(() => getFood = true);
    } else if (jsonString.startsWith("SELF_OPTIONS:")) {
      processSelfOptions(jsonString.substring(13));
    } else {
      processLabels(jsonString);
    }
  }

  void processSelfOptions(String jsonString) {
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);

      final Map<String, int> extractedSelfOptions = {};

      decoded.forEach((key, value) {
        if (value is int) {
          extractedSelfOptions[key] = value;
        }
      });

      if (mounted && extractedSelfOptions.isNotEmpty) {
        setState(() {
          selfOptions = extractedSelfOptions;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && selectedSelfCode == null) {
            _showSelfSelectionDialog();
          } else if (mounted && selectedSelfCode != null) {
            openFoodPage();
          }
        });
      } else {}
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطا در پردازش لیست سلف‌ها: ${e.toString()}',
            style: const TextStyle(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void processLabels(String jsonString) {
    try {
      final List<dynamic> decodedList = jsonDecode(jsonString);
      final List<String> labelList =
          decodedList.map((item) => item.toString()).toList();
      final List<String> extractedTexts = [];

      for (String label in labelList) {
        List<String> parts =
            label.split('|').map((part) => part.trim()).toList();
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
              style: const TextStyle(),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> handlePageFinished(String url) async {
    if (!mounted) return;

    try {
      if (url == '${widget.selfUrl}/index.rose') {
        await autoLogin();
      } else if (url == '${widget.selfUrl}/index/index.rose') {
        if (selectedSelfCode != null) {
          openFoodPage();
        } else {
          await openReserveDialog();
          await extractSelfOptions();
        }
      } else if (url.startsWith(
        '${widget.selfUrl}/nurture/user/multi/reserve/showPanel.rose',
      )) {
        await _getHtmlContent();
      } else if (url ==
          '${widget.selfUrl}/nurture/user/multi/reserve/reserve.rose') {
        await _getHtmlContent();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در بارگذاری صفحه: ${e.toString()}',
              style: const TextStyle(),
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
              style: const TextStyle(),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> openReserveDialog() async {
    final String jsCode = '''
      (function() {
        
        const reserveLink = document.querySelector('span[onclick*="selectSelf.rose"]');
        
        if (reserveLink) {
          reserveLink.click();
          
          setTimeout(function() {
            const dialog = document.querySelector('.ui-dialog');

          }, 500);
        }
      })();
    ''';

    try {
      await controller.runJavaScript(jsCode);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطا در باز کردن دیالوگ: ${e.toString()}',
            style: const TextStyle(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> extractSelfOptions() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    const String jsCode = '''
    (function() {
      const selfOptionsMap = {};
      const selectElement = document.getElementById('selectself_selfListId');
      
      if (selectElement) {
        const options = selectElement.querySelectorAll('option');
        
        options.forEach(option => {
          const value = option.value;
          const text = option.textContent.trim();
          
          if (value && value !== '-1' && !isNaN(value)) {
            const selfName = text.split(' - ')[0].trim();
            selfOptionsMap[selfName] = parseInt(value);
          }
        });
        
        const dialogClose = document.querySelector('.ui-dialog-titlebar-close');
        if (dialogClose) dialogClose.click();
      }
      
      Flutter.postMessage('SELF_OPTIONS:' + JSON.stringify(selfOptionsMap));
    })();
  ''';

    try {
      await controller.runJavaScript(jsCode);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطا در پردازش لیست سلف‌ها: ${e.toString()}',
            style: const TextStyle(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> openFoodPage() async {
    if (selectedSelfCode != null) {
      final String url =
          '${widget.selfUrl}/nurture/user/multi/reserve/showPanel.rose?selectedSelfDefId=$selectedSelfCode';

      final String jsCode = '''
        window.location.href = '$url';
      ''';
      try {
        await controller.runJavaScript(jsCode);
      } catch (e) {
        // ...
      }
      return;
    }
    if (selectedSelfCode == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showSelfSelectionDialog();
      });
      return;
    }

    final String url =
        '${widget.selfUrl}/nurture/user/multi/reserve/showPanel.rose?selectedSelfDefId=$selectedSelfCode';

    final String jsCode = '''
    window.location.href = '$url';
  ''';
    try {
      await controller.runJavaScript(jsCode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در انتقال به صفحه غذا: ${e.toString()}',
              style: const TextStyle(),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSelfSelectionDialog() {
    if (selfOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لیست سلف‌ها خالی است'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'انتخاب سلف',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: selfOptions.length,
                itemBuilder: (context, index) {
                  final selfName = selfOptions.keys.elementAt(index);
                  final selfCode = selfOptions.values.elementAt(index);

                  return ListTile(
                    title: Text(selfName),
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          selectedSelfCode = selfCode;
                        });
                      }
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                        _showDefaultConfirmationDialog(selfCode, selfName);
                      }
                      openFoodPage();
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDefaultConfirmationDialog(int selfCode, String selfName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('انتخاب نهایی سلف'),
            content: Text(
                'آیا می‌خواهید "$selfName" را به عنوان سلف **پیش‌فرض** برای این حساب ذخیره کنید؟'),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (mounted) {
                    setState(() {
                      selectedSelfCode = selfCode;
                    });
                    openFoodPage();
                  }
                },
                child:
                    const Text('فقط رزرو', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (widget.onDefaultSelfSelected != null) {
                    widget.onDefaultSelfSelected!(selfCode);
                  }
                  Navigator.of(context).pop();
                  if (mounted) {
                    setState(() {
                      selectedSelfCode = selfCode;
                    });
                    openFoodPage();
                  }
                },
                child: const Text('ذخیره و رزرو'),
              ),
            ],
          ),
        );
      },
    );
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
              style: const TextStyle(),
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
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: itemList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(itemList[index], style: const TextStyle()),
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
                  style: TextStyle(color: Colors.red),
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
      String jsCode = '''
        location.reload()
        window.alert = function(message){
          return true;
        }    
        var element = document.getElementById('buyFreeFoodIconSpanuserWeekReserves.selected$index');
        if (element) {
          Flutter.postMessage("Done");
          console.log('Element clicked: buyFreeFoodIconSpanuserWeekReserves.selected$index');
          var img = element.closest('tr')?.querySelector('img[src="/images/buy.png"]');
          if (img) img.click();  
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
              Future.delayed(Duration(milliseconds: _speed), () {
                setState(() {
                  _refreshAndCheckElement(index);
                });
              });
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'خطا در بروزرسانی: ${e.toString()}',
                    style: const TextStyle(),
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
              style: const TextStyle(),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'shabnam',
      ),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_forward_ios_rounded),
              ),
            ],
            leadingWidth: 120,
            leading: Row(
              children: [
                SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    try {
                      final String jsCode = '''
                    window.location.href = '${widget.selfUrl}/accessMgmt/action/logout.rose';
                  ''';

                      await controller.runJavaScript(jsCode);

                      if (mounted && context.mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted &&
                          context.mounted &&
                          ScaffoldMessenger.of(context).mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'خطا در خروج از سیستم: ${e.toString()}',
                              style: const TextStyle(),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),
                SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.speed),
                  onPressed: () async {
                    _showSpeedDialog();
                  },
                ),
              ],
            ),
          ),
          floatingActionButton: selectedIndex == null
              ? Container()
              : FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      getFood = true;
                    });
                  },
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.purple,
                  shape: CircleBorder(),
                  child: const Icon(Icons.stop),
                ),
          body: Column(
            children: [
              Expanded(child: WebViewWidget(controller: controller)),
              if (selectedIndex != null && itemList.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'غذا انتخاب شده: ${itemList[selectedIndex!]}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
