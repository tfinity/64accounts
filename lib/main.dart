import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
//import 'package:onesignal_flutter/onesignal_flutter.dart';
//import 'package:flutter_webview_pro/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '64 Account',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: '64 Account'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //var externalUserId = '192.168.1.15';
  String userId = " ";
  String url = "http://64account.com/";
  late PullToRefreshController pullToRefreshController;
  @override
  void initState() {
    super.initState();

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          controllerGlobal.reload();
        } else if (Platform.isIOS) {
          controllerGlobal.loadUrl(
              urlRequest: URLRequest(url: await controllerGlobal.getUrl()));
        }
      },
    );
    connectionCheck();
  }

  bool isConnected = true;
  var listener;

  connectionCheck() {
    listener = InternetConnectionChecker().onStatusChange.listen((status) {
      switch (status) {
        case InternetConnectionStatus.connected:
          setState(() {
            isConnected = true;
          });
          Future.delayed(const Duration(seconds: 5), () {
            setState(() {
              index = 1;
            });
          });
          break;
        case InternetConnectionStatus.disconnected:
          setState(() {
            isConnected = false;
            index = 0;
          });
          break;
      }
    });
  }

  @override
  void dispose() {
    listener.cancel();
    super.dispose();
  }

  int index = 0;

  late InAppWebViewController controllerGlobal;

  Future<bool> _exitApp(BuildContext context) async {
    if (await controllerGlobal.canGoBack()) {
      print("onwill goback");
      controllerGlobal.goBack();
      return false;
    } else {
      return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Container(
                height: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Do you want to exit?"),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              print('yes selected');
                              exit(0);
                            },
                            child: Text("Yes"),
                            style: ElevatedButton.styleFrom(
                                primary: Colors.red.shade800),
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                            child: ElevatedButton(
                          onPressed: () {
                            print('no selected');
                            Navigator.of(context).pop();
                          },
                          child:
                              Text("No", style: TextStyle(color: Colors.black)),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.white,
                          ),
                        ))
                      ],
                    )
                  ],
                ),
              ),
            );
          });
    }
  }

  bool isLoading = false;
  bool hideTopBar = true;
  int scrolled = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () => _exitApp(context),
        child: Scaffold(
          body: IndexedStack(
            index: index,
            children: [
              Container(
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        width: double.infinity,
                        child: Image.asset('assets/logo.png')),
                    if (!isConnected)
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),
                    isConnected
                        ? const CircularProgressIndicator()
                        : Image.asset(
                            'assets/connection.png',
                            scale: 15,
                          ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),
                    isConnected
                        ? const Text('')
                        : const Text(
                            'Connection Error!... Please check Your Internet'),
                  ],
                ),
              ),
              Column(
                children: [
                  hideTopBar
                      ? Row(
                          children: [
                            SizedBox(
                              width: 10,
                            ),
                            IconButton(
                              onPressed: () async {
                                _exitApp(context);
                              },
                              icon: Icon(Icons.arrow_back),
                            ),
                            Expanded(
                              child: Center(
                                child: Visibility(
                                  child: CircularProgressIndicator(),
                                  visible: isLoading,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                if (Platform.isAndroid) {
                                  controllerGlobal.reload();
                                } else if (Platform.isIOS) {
                                  controllerGlobal.loadUrl(
                                      urlRequest: URLRequest(
                                          url:
                                              await controllerGlobal.getUrl()));
                                }
                              },
                              icon: Icon(Icons.refresh),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                          ],
                        )
                      : SizedBox(
                          height: 0.1,
                        ),
                  Expanded(
                    child: InAppWebView(
                      onLoadStart: (controller, url) {
                        setState(() {
                          isLoading = true;
                        });
                      },
                      onLoadStop: (controller, url) {
                        pullToRefreshController.endRefreshing();
                        setState(() {
                          isLoading = false;
                        });
                      },
                      pullToRefreshController: pullToRefreshController,
                      initialUrlRequest: URLRequest(url: Uri.parse(url)),
                      onWebViewCreated: (controller) {
                        controllerGlobal = controller;
                      },
                      initialOptions: InAppWebViewGroupOptions(
                        crossPlatform: InAppWebViewOptions(
                          horizontalScrollBarEnabled: false,
                          verticalScrollBarEnabled: false,
                          supportZoom: false,
                        ),
                        android: AndroidInAppWebViewOptions(
                          useHybridComposition: true,
                          supportMultipleWindows: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
