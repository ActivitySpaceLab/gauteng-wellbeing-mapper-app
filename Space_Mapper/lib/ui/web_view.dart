import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

const String userUUID_element = '/asRrkkAw4mUtpTDkjdzZzt/group_survey/userUUID';
const String userUUID_label = userUUID_element + ':label';

final Set<JavascriptChannel> jsChannels = [
  JavascriptChannel(
      name: 'Print',
      onMessageReceived: (JavascriptMessage message) {
        print(message.message);
      }),
].toSet();

// ignore: must_be_immutable
class MyWebView extends StatefulWidget {
  final String selectedUrl;
  final String locationHistoryJSON;
  MyWebView(this.selectedUrl, this.locationHistoryJSON);
  @override
  _MyWebViewState createState() =>
      _MyWebViewState(selectedUrl, locationHistoryJSON);
}

class _MyWebViewState extends State<MyWebView> {
  final String selectedUrl;
  final String locationHistoryJSON;

  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  late WebViewController _webViewcontroller;

  _MyWebViewState(this.selectedUrl, this.locationHistoryJSON);

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project'),
        // This drop down menu demonstrates that Flutter widgets can be shown over the web view.
        actions: <Widget>[
          NavigationControls(_controller.future),
        ],
      ),
      // We're using a Builder here so we have a context that is below the Scaffold
      // to allow calling Scaffold.of(context) so we can show a snackbar.
      body: Builder(builder: (BuildContext context) {
        return WebView(
          initialUrl: selectedUrl,
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            _controller.complete(webViewController);
            _webViewcontroller = webViewController;
          },
          onProgress: (int progress) {
            print("WebView is loading (progress : $progress%)");
          },
          javascriptChannels: <JavascriptChannel>{
            _toasterJavascriptChannel(context),
          },
          onPageStarted: (String url) {
            print('Page started loading: $url');
          },
          onPageFinished: (String url) {
            _setFormLocationHistory();
            print('Page finished loading: $url');
          },
          gestureNavigationEnabled: true,
        );
      }),
    );
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        });
  }

  void _setFormLocationHistory() async {
    sleep(Duration(seconds: 1));

    await _webViewcontroller.runJavascript(
        'var event = new Event("change", {bubbles: true,});                                                                                             var this_input = document.getElementsByName("/awLRwRXn4GTpdcq3aJE2WQ/Location_History")[0];                                               this_input.value = "test2";                                                                                                                 this_input.dispatchEvent(event);');
    print("Location History updated in webview.");
  }
}

class NavigationControls extends StatelessWidget {
  const NavigationControls(this._webViewControllerFuture);

  final Future<WebViewController> _webViewControllerFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: _webViewControllerFuture,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> snapshot) {
        final bool webViewReady =
            snapshot.connectionState == ConnectionState.done;
        final WebViewController? controller = snapshot.data;
        return Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.replay),
              onPressed: !webViewReady
                  ? null
                  : () {
                      controller!.reload();
                    },
            ),
          ],
        );
      },
    );
  }
}
