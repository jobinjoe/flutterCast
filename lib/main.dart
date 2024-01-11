import 'package:cast/device.dart';
import 'package:cast/discovery_service.dart';
import 'package:cast/session.dart';
import 'package:cast/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cast Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const Scaffold(
        body: WebView(),
      ),
      routes: {
        Cast.route: (context) => const Cast(),
      },
    );
  }
}

class WebView extends StatefulWidget {
  const WebView({super.key});

  @override
  State<WebView> createState() => _WebViewState();
}

class _WebViewState extends State<WebView> {
  final webViewController = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(const Color(0x00000000))
    ..setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          // Update loading bar.
        },
        onPageStarted: (String url) {},
        onPageFinished: (String url) {},
        onWebResourceError: (WebResourceError error) {},
        onNavigationRequest: (NavigationRequest request) {
          if (request.url.startsWith('https://www.youtube.com/')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    )
    ..loadRequest(Uri.parse('http://192.168.1.106:4200/physioAssist'));

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: WebViewWidget(controller: webViewController),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          height: 40,
          width: 40,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              child: IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, Cast.route);
                },
                icon: const Icon(Icons.cast, color: Colors.white),
              ),
            ),
          ),
        )
      ],
    );
  }
}

class Cast extends StatefulWidget {
  static String route = '/cast';
  const Cast({super.key});

  @override
  State<Cast> createState() => _CastState();
}

class _CastState extends State<Cast> {
  Future<List<CastDevice>>? _future;

  @override
  void initState() {
    super.initState();
    _startSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<List<CastDevice>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error.toString()}',
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data!.isEmpty) {
            return const Column(
              children: [
                Center(
                  child: Text(
                    'No Chromecast founded',
                  ),
                ),
              ],
            );
          }

          return Column(
            children: snapshot.data!.map((device) {
              return ListTile(
                title: Text(device.name),
                onTap: () {
                  // _connectToYourApp(context, device);
                  _connectAndPlayMedia(context, device);
                },
              );
            }).toList(),
          );
        },
      ),
    );
    // return FutureBuilder<List<CastDevice>>(
    //   future: _future,
    //   builder: (context, snapshot) {
    //     if (snapshot.hasError) {
    //       return Center(
    //         child: Text(
    //           'Error: ${snapshot.error.toString()}',
    //         ),
    //       );
    //     } else if (!snapshot.hasData) {
    //       return const Center(
    //         child: CircularProgressIndicator(),
    //       );
    //     }
    //
    //     if (snapshot.data!.isEmpty) {
    //       return const Column(
    //         children: [
    //           Center(
    //             child: Text(
    //               'No Chromecast founded',
    //             ),
    //           ),
    //         ],
    //       );
    //     }
    //
    //     return Column(
    //       children: snapshot.data!.map((device) {
    //         return ListTile(
    //           title: Text(device.name),
    //           onTap: () {
    //             // _connectToYourApp(context, device);
    //             _connectAndPlayMedia(context, device);
    //           },
    //         );
    //       }).toList(),
    //     );
    //   },
    // );
  }

  void _startSearch() {
    _future = CastDiscoveryService().search();
  }

  // Future<void> _connectToYourApp(
  //     BuildContext context, CastDevice object) async {
  //   final session = await CastSessionManager().startSession(object);
  //
  //   session.stateStream.listen((state) {
  //     if (state == CastSessionState.connected) {
  //       const snackBar = SnackBar(content: Text('Connected'));
  //       ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //
  //       _sendMessageToYourApp(session);
  //     }
  //   });
  //
  //   session.messageStream.listen((message) {
  //     print('receive message: $message');
  //   });
  //
  //   session.sendMessage(CastSession.kNamespaceReceiver, {
  //     'type': 'LAUNCH',
  //     'appId': 'Youtube', // set the appId of your app here
  //   });
  // }

  // void _sendMessageToYourApp(CastSession session) {
  //
  //   session.sendMessage('urn:x-cast:namespace-of-the-app', {
  //     'type': 'sample',
  //   });
  // }

  Future<void> _connectAndPlayMedia(
      BuildContext context, CastDevice object) async {
    final session = await CastSessionManager().startSession(object);

    session.stateStream.listen((state) {
      if (state == CastSessionState.connected) {
        const snackBar = SnackBar(content: Text('Connected'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    });

    var index = 0;

    session.messageStream.listen((message) {
      index += 1;

      debugPrint('receive message: $message');

      if (index == 2) {
        Future.delayed(const Duration(seconds: 5)).then((x) {
          _sendMessagePlayVideo(session);
        });
      }
    });

    session.sendMessage(CastSession.kNamespaceReceiver, {
      'type': 'LAUNCH',
      'appId': 'CC1AD845', // set the appId of your app here
    });
  }

  void _sendMessagePlayVideo(CastSession session) {
    debugPrint('_sendMessagePlayVideo');

    var message = {
      // Here you can plug an URL to any mp4, webm, mp3 or jpg file with the proper contentType.
      // 'contentId':
      //     'http://commondatastorage.googleapis.com/gtv-videos-bucket/big_buck_bunny_1080p.mp4',
      // 'contentId':
      //     'http://192.168.3.175:5000/push_up_feed?video_type=video&username=Jobin',
      'contentId':
          'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8',
      'contentType': 'video/mp4',
      'streamType': 'LIVE', //BUFFERED or LIVE

      // Title and cover displayed while buffering
      'metadata': {
        'type': 0,
        'metadataType': 0,
        'title': "Big Buck Bunny",
        'images': [
          {
            'url':
                'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg'
          }
        ]
      }
    };

    session.sendMessage(CastSession.kNamespaceMedia, {
      'type': 'LOAD',
      'autoPlay': true,
      'currentTime': 0,
      'media': message,
    });
  }
}
