import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? _webViewController;
  late final  PullToRefreshController pullToRefreshController;
  final urlController = TextEditingController();
  double progress = 0;
  String url = '';

  // Future<Directory?>? _externalDocumentsDirectory =
  //     getExternalStorageDirectory();

  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      javaScriptEnabled: true,
      useShouldOverrideUrlLoading: true,
      useOnDownloadStart: true,
      allowFileAccessFromFileURLs: true,
      mediaPlaybackRequiresUserGesture: false,
    ),
    android: AndroidInAppWebViewOptions(
      initialScale: 100,
      allowFileAccess: true,
      useShouldInterceptRequest: true,
      useHybridComposition: true,
    ),
    ios: IOSInAppWebViewOptions(
      allowsInlineMediaPlayback: true,
    ),
  );

  late StreamSubscription subscription;
  var isDeviceConnected;
  bool isAlertSet = false;

  @override
  void initState() {
    pullToRefreshController = PullToRefreshController();
    getConnectivity();
    getsupScription;
    super.initState();
  }

  getsupScription() =>
      subscription = Connectivity().onConnectivityChanged.listen(
        (ConnectivityResult result) async {
          isDeviceConnected = await InternetConnectionChecker().hasConnection;
          if (!isDeviceConnected && isAlertSet == false) {
            showDialogBox();
            setState(() => isAlertSet = true);
          }
        },
      );

  getConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return  showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                "No Internet Connection",
                style: TextStyle(color: Colors.red),
              ),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      // showDialogBox();
                      // setState(() => isAlertSet = true);
                    },
                    child: Text("Ok"))
              ],
            );
          });
    }
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: exit,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    InAppWebView(
                      key: webViewKey,
                      initialUrlRequest: URLRequest(
                        // url: Uri.parse('www.allmedicin.com'),
                        url: Uri.parse('https://www.allmedicin.com/'),
                        headers: {},
                      ), // "https://unsplash.com/photos/odxB5oIG_iA"
                      initialOptions: options,
                       pullToRefreshController: pullToRefreshController,
                      // onDownloadStart: (controller, url) async {
                      //   downloading a file in a webview application
                      //   print("onDownloadStart $url");
                      //   await FlutterDownloader.enqueue(
                      //     url: url.toString(), // url to download
                      //     savedDir: (await getExternalStorageDirectory())!.path,
                      //     // the directory to store the download
                      //     fileName: 'downloads',
                      //     headers: {},
                      //     showNotification: true,
                      //     openFileFromNotification: true,
                      //   );
                      // },
                      onWebViewCreated: (controller) {
                        _webViewController = controller;
                      },
                      onLoadStart: (controller, url) {
                        setState(() {
                          this.url = url.toString();
                          urlController.text = this.url;
                        });
                      },
                      androidOnPermissionRequest:
                          (controller, origin, resources) async {
                        return PermissionRequestResponse(
                            resources: resources,
                            action: PermissionRequestResponseAction.GRANT);
                      },
                      onLoadStop: (controller, url) async {
                        pullToRefreshController.endRefreshing();
                        setState(() {
                          this.url = url.toString();
                          urlController.text = this.url;
                        });
                      },
                      onLoadError: (controller, url, code, message) {
                        pullToRefreshController.endRefreshing();
                      },
                      onProgressChanged: (controller, progress) {
                        if (progress == 100) {
                          pullToRefreshController.endRefreshing();
                        }
                        setState(() {
                          this.progress = progress / 100;
                          urlController.text = this.url;
                        });
                      },
                      onUpdateVisitedHistory:
                          (controller, url, androidIsReload) {
                        setState(() {
                          this.url = url.toString();
                          urlController.text = this.url;
                        });
                      },
                      onConsoleMessage: (controller, consoleMessage) {
                        print(consoleMessage);
                      },
                    ),
                    progress < 1.0
                        ? LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.lightBlueAccent),
                          )
                        : Center(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  showDialogBox() => showCupertinoDialog<String>(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: const Text('No Connection'),
          content: const Text('Please check your internet connectivity'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                Navigator.pop(context, 'Cancel');
                setState(() => isAlertSet = false);
                isDeviceConnected = await Connectivity().checkConnectivity();
                if (!isDeviceConnected && isAlertSet == false) {
                  showDialogBox();
                  setState(() => isAlertSet = true);
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );

  Future<bool> exit() async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Are you sure exit this app"),
          actions: [
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text("Ok"))
          ],
        );
      },
    );
  }
}
