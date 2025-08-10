import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import '../../main.dart';
import 'dart:convert';

// Simple enum for legacy compatibility
enum SurveyType { initial, biweekly, wellbeing }

final Set<JavaScriptChannelParams> jsChannels = [
  JavaScriptChannelParams(
      name: 'Print',
      onMessageReceived: (JavaScriptMessage message) {
        print(message.message);
      }),
].toSet();

// ignore: must_be_immutable
class MyWebView extends StatefulWidget {
  final String selectedUrl;
  String generatedUrl = "";
  final String locationHistoryJSON;
  final String locationSharingMethod;
  final String surveyElementCode;
  final SurveyType? surveyType; // Add survey type for Qualtrics
  final bool isQualtricsSurvey; // Flag to determine survey platform
  
  MyWebView(
    this.selectedUrl, 
    this.locationHistoryJSON,
    this.locationSharingMethod, 
    this.surveyElementCode, {
    this.surveyType,
    this.isQualtricsSurvey = false,
  });
  
  @override
  _MyWebViewState createState() => _MyWebViewState(
    selectedUrl,
    locationHistoryJSON, 
    locationSharingMethod, 
    surveyElementCode,
    surveyType: surveyType,
    isQualtricsSurvey: isQualtricsSurvey,
  );
}

class _MyWebViewState extends State<MyWebView> {
  final String selectedUrl;
  String generatedUrl = "";
  final String locationHistoryJSON;
  final String locationSharingMethod;
  final String surveyElementCode;
  final SurveyType? surveyType;
  final bool isQualtricsSurvey;
  String userUUID = GlobalData.userUUID;
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  late WebViewController _webViewcontroller;

  _MyWebViewState(
    this.selectedUrl, 
    this.locationHistoryJSON,
    this.locationSharingMethod, 
    this.surveyElementCode, {
    this.surveyType,
    this.isQualtricsSurvey = false,
  });

  @override
  void initState() {
    super.initState();
    //if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    // Initialize platform-specific controller
    late final PlatformWebViewControllerCreationParams params;
    if (Platform.isAndroid) {
      params = const PlatformWebViewControllerCreationParams();
    } else if (Platform.isIOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      //..loadRequest(Uri.parse(selectedUrl))
      ..addJavaScriptChannel(
        'Print',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('JavaScript channel message: ${message.message}');
          // Handle Qualtrics survey completion
          if (message.message == 'SURVEY_COMPLETED') {
            debugPrint('Qualtrics survey completed, returning to app');
            Navigator.pop(context);
          }
          // Handle field population feedback for testing
          else if (message.message.startsWith('FIELDS_POPULATED:')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Survey fields populated successfully'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
          else if (message.message.startsWith('FIELDS_ERROR:')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Field population issue - check survey setup'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
            if (url == "https://ee.kobotoolbox.org/thanks" ||
                url == "https://ee-eu.kobotoolbox.org/thanks") {
              debugPrint('MOVING TO THANKS PAGE');
              Navigator.pop(context);
            }
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
            
            if (isQualtricsSurvey) {
              // Handle Qualtrics survey
              _setupQualtricsSurvey();
            } else {
              // Handle KoboToolbox survey (legacy)
              if (url != "https://ee.kobotoolbox.org/thanks" &&
                  url != "https://ee-eu.kobotoolbox.org/thanks" &&
                  (locationSharingMethod == '1' ||
                      locationSharingMethod == '3')) {
                _setFormLocationHistory();
              }
            }
          },
          onProgress: (int progress) {
            debugPrint("WebView is loading (progress : $progress%)");
          },
          // New method to enable gesture navigation
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(selectedUrl)); // Use selectedUrl directly instead of GlobalProjectData

    _webViewcontroller = controller;
    _controller.complete(controller);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Project',
            style: TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // This drop down menu demonstrates that Flutter widgets can be shown over the web view.
        /*actions: <Widget>[
          NavigationControls(_controller.future),
        ],*/
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushNamed('/');
          },
          //      actions: <Widget>[
          //       NavigationControls(_controller.future),
          //    ],
        ),
      ), // We're using a Builder here so we have a context that is below the Scaffold
      // to allow calling Scaffold.of(context) so we can show a snackbar.
      body: Builder(builder: (BuildContext context) {
        //generatedUrl = selectedUrl + "?&d[user_id]=" + userUUID + "&d[experiment_status]=" + active_project_status;
        print('userURL web 2: $selectedUrl');
        print('userUUID web 2: $userUUID');
        print('Selected URL: $selectedUrl'); // Use selectedUrl directly
        return WebViewWidget(
          controller: _webViewcontroller,
        );
      }),
    );
  }

  void _setFormLocationHistory() async {
    //sleep(Duration(seconds: 1));

    //await _webViewcontroller.runJavaScript(
    //'var event = new Event("change", {bubbles: true,}); var this_input = document.getElementsByName("/$surveyElementCode/location_history")[0]; this_input.style.visibility="hidden"; this_input.value = "$locationHistoryJSON"; this_input.dispatchEvent(event);');
    try {
      await _webViewcontroller.runJavaScript('''
      try {
        var event = new Event("change", {bubbles: true});
        var elementName = "/${surveyElementCode}/location_history";
        var this_input = document.getElementsByName(elementName)[0];
        
        if (!this_input) {
          console.error("Element not found: " + elementName);
          return;
        }
        
        this_input.style.visibility = "hidden";
        this_input.value = ${_escapeJsString(locationHistoryJSON)};
        this_input.dispatchEvent(event);
      } catch(e) {
        console.error("JavaScript error: " + e.message);
      }
    ''');
    } catch (e) {
      debugPrint('Error executing JavaScript: $e');
    }
  }

  void _setupQualtricsSurvey() async {
    if (surveyType == null) {
      debugPrint('Survey type not specified for Qualtrics survey');
      return;
    }

    try {
      // Note: New architecture uses API sync instead of webview injection
      // This webview is now primarily for display purposes
      
      // Simple embedded data injection for participant ID
      final surveyJavaScript = '''
        // Set participant UUID in Qualtrics embedded data
        if (typeof Qualtrics !== 'undefined' && Qualtrics.SurveyEngine) {
          Qualtrics.SurveyEngine.setEmbeddedData('participant_uuid', '${GlobalData.userUUID}');
          console.log('✅ Participant UUID set in Qualtrics embedded data');
        } else {
          console.log('⚠️ Qualtrics not available for embedded data');
        }
      ''';

      // Execute the simplified script
      await _webViewcontroller.runJavaScript(surveyJavaScript);
      
      debugPrint('Qualtrics survey setup completed with embedded data API');
    } catch (e) {
      debugPrint('Error setting up Qualtrics survey: $e');
    }
  }
}

// Helper to properly escape strings for JavaScript
String _escapeJsString(String input) {
  // JSON encode gives us proper JS string escaping
  String jsonEncoded = json.encode(input);
  return jsonEncoded;
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
