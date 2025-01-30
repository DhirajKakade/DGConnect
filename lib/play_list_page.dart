import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dgplay/functions.dart';
import 'package:dgplay/screen_selection_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:xml2json/xml2json.dart';

import 'constants/api_constants.dart' as globals;

class PlayListPage extends StatefulWidget {
  String screenid, serialno, custid, userid, username;

  PlayListPage({Key? key, required this.screenid, required this.serialno, required this.userid, required this.custid, required this.username}) : super(key: key);

  @override
  State<PlayListPage> createState() => _PlayListPageState();
}

class _PlayListPageState extends State<PlayListPage> with WidgetsBindingObserver {
  // StreamSubscription<QuerySnapshot>? _eventsSubscription;
  Future? api;
  var controller;
  var webController;

  //CachedVideoPlayerController controller;

  int index = 0;
  int currentIndex = 0;

  SharedPreferences? sharedPreferences;

  void onViewPlayerCreated(viewPlayerController) {
    this.viewPlayerController = viewPlayerController;
    viewPlayerController.resumeVideo();
  }

  late MethodChannel _channel;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    // ToastContext().init(context);

    _channel = const MethodChannel('bms_video_player');
    _channel.setMethodCallHandler(_handleMethod);

    initDb();
    print(widget.serialno);

    /* if (!kIsWeb) {
      final docUser = Firestore.instance
          .collection('brandm')
          .document("${widget.serialno}");
      // .document("${widget.serialno}_${widget.screenid}");

      docUser.setData({"device_id": true});

      Firestore.instance
          .collection('brandm')
          .document("${widget.serialno}")
          .snapshots()
          .listen((DocumentSnapshot documentSnapshot) async {
        if (documentSnapshot.exists) {
          print("Hello");

          if (documentSnapshot.data.containsValue(true)) {
            documentSnapshot.reference.updateData({"device_id": false});
            getPlayList(
                widget.serialno, widget.screenid, widget.custid, widget.userid);
            print("UPDATED");

            print("APICALL");
          } else if (documentSnapshot.data.containsValue(false)) {
            print("NOT UPDATED");
          }

          //api call
          // data update
        } else {
          print('Document does not exist on the database');
        }
      });
    }*/
  }

  initDb() async {
    sharedPreferences = await SharedPreferences.getInstance();
    isRunningAds = true;
    // isInternet();
    checkInternetConnection();
  }

  // Future<bool> isInternet() async {
  //   var connectivityResult = await (Connectivity().checkConnectivity());
  //   if (connectivityResult == ConnectivityResult.wifi || connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.ethernet) {
  //     // I am connected to a WIFI network, make sure there is actually a net connection.
  //     if (true) {
  //       // Wifi detected & internet connection confirmed.
  //       if (!kIsWeb) {
  //         final docUser = FirebaseFirestore.instance.collection('unitglo-ads').doc(widget.serialno);
  //         // .document("${widget.serialno}_${widget.screenid}");
  //
  //         docUser.set({"device_id": true});
  //
  //         FirebaseFirestore.instance.collection('unitglo-ads').doc(widget.serialno).snapshots().listen((documentSnapshot) async {
  //           if (documentSnapshot.exists) {
  //             print("FCM CALL DETECT");
  //
  //             if (documentSnapshot.data()!.containsValue(true)) {
  //               documentSnapshot.reference.update({"device_id": false});
  //               getPlayList(widget.serialno, widget.screenid, widget.custid, widget.userid);
  //               print("UPDATED");
  //
  //               print("APICALL");
  //             } else if (documentSnapshot.data()!.containsValue(false)) {
  //               print("NOT UPDATED");
  //             }
  //             //api call
  //             // data update
  //           } else {
  //             print('Document does not exist on the database');
  //           }
  //         });
  //       }
  //       // Toast.show("Connection OK", gravity: Toast.bottom, duration: 5);
  //
  //       showSnack(context, "Connection OK");
  //
  //       String s = sharedPreferences?.getString("lastDate") ?? "";
  //       if (s.isNotEmpty) {
  //         for (int i = 0; i < sharedPreferences!.getKeys().length; i++) {
  //           if (sharedPreferences!.getKeys().elementAt(i).toString().contains("count_")) {
  //             // debugPrint("keeyyyyy y ::: "+);
  //             // // sharedPreferences.setInt('count_' + media_id + "_" + screenid + "_" + userid+"_"+date, 0);
  //
  //             String data = sharedPreferences!.getKeys().elementAt(i).toString();
  //             //count_30_22_2_3_10_2022
  //             if (data.contains("_")) {
  //               List<String> split = data.split("_");
  //               if (split.length > 6) {
  //                 String media_id = split[1];
  //                 String screenid = split[2];
  //                 String userid = split[3];
  //                 String custid = sharedPreferences!.getString('custid') ?? "";
  //
  //                 DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //                 AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  //
  //                 // String deviceId = await PlatformDeviceId.getDeviceId??"";
  //                 // String deviceId = await PlatformDeviceId.getDeviceId??"";
  //                 String deviceId = androidInfo.id;
  //                 int lastCount = sharedPreferences!.getInt(data) ?? 0;
  //
  //                 Map<String, String> body = {
  //                   'device_id': deviceId, 'screen_id': screenid, 'customer_id': custid, 'user_id': userid, 'media_id': media_id, // 2022-10-01
  //                   'report_date': s.replaceAll("_", "-"), 'count': '$lastCount',
  //                 };
  //                 if (lastCount != 0) {
  //                   await updateCountServer(body, data);
  //                 }
  //               }
  //             }
  //           }
  //         }
  //       }
  //
  //       return true;
  //     } else {
  //       // Wifi detected but no internet connection found.
  //
  //       getOfflinePlayList();
  //       // Toast.show("1 - No Internet Connection.Local DATA initialize",
  //       //     gravity: Toast.bottom, duration: 5);
  //       //
  //       showSnack(context, "1 - No Internet Connection.Local DATA initialize");
  //       return false;
  //     }
  //   } else {
  //     getOfflinePlayList();
  //     // Toast.show("2 - No Internet Connection.Local DATA initialize",
  //     //     gravity: Toast.bottom, duration: 5);
  //     showSnack(context, "2 - No Internet Connection.Local DATA initialize");
  //     // Neither mobile data or WIFI detected, not internet connection found.
  //     return false;
  //   }
  // }

  Future<bool> checkInternetConnection() async {
    try {
      var response = await http.get(Uri.parse('https://google.com'));
      if (response.statusCode == 200) {
        if (!kIsWeb) {
          final docUser = FirebaseFirestore.instance.collection('unitglo-ads').doc(widget.serialno);
          // .document("${widget.serialno}_${widget.screenid}");

          docUser.set({"device_id": true});

          FirebaseFirestore.instance.collection('unitglo-ads').doc(widget.serialno).snapshots().listen((documentSnapshot) async {
            if (documentSnapshot.exists) {
              print("FCM CALL DETECT");

              if (documentSnapshot.data()!.containsValue(true)) {
                try {
                  DefaultCacheManager manager = DefaultCacheManager();
                  await manager.emptyCache();
                  manager.store.emptyMemoryCache();
                  documentSnapshot.reference.update({"device_id": false});
                  final Directory tempDir = await getTemporaryDirectory();
                  final Directory libCacheDir = Directory("${tempDir.path}/libCachedImageData");
                  await libCacheDir.delete(recursive: true);
                } catch (_) {}

                if (timer != null) {
                  timer.cancel();
                }

                await getPlayList(widget.serialno, widget.screenid, widget.custid, widget.userid);
                print("UPDATED");

                print("APICALL");
              } else if (documentSnapshot.data()!.containsValue(false)) {
                print("NOT UPDATED");
              }
              //api call
              // data update
            } else {
              print('Document does not exist on the database');
            }
          });
        }
        // Toast.show("Connection OK", gravity: Toast.bottom, duration: 5);

        showSnack(context, "Connection OK");

        String s = sharedPreferences?.getString("lastDate") ?? "";
        if (s.isNotEmpty) {
          for (int i = 0; i < sharedPreferences!.getKeys().length; i++) {
            if (sharedPreferences!.getKeys().elementAt(i).toString().contains("count_")) {
              // debugPrint("keeyyyyy y ::: "+);
              // // sharedPreferences.setInt('count_' + media_id + "_" + screenid + "_" + userid+"_"+date, 0);

              String data = sharedPreferences!.getKeys().elementAt(i).toString();
              //count_30_22_2_3_10_2022
              if (data.contains("_")) {
                List<String> split = data.split("_");
                if (split.length > 6) {
                  String media_id = split[1];
                  String screenid = split[2];
                  String userid = split[3];
                  String custid = sharedPreferences!.getString('custid') ?? "";

                  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
                  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

                  // String deviceId = await PlatformDeviceId.getDeviceId??"";
                  // String deviceId = await PlatformDeviceId.getDeviceId??"";
                  String deviceId = androidInfo.id;
                  int lastCount = sharedPreferences!.getInt(data) ?? 0;

                  Map<String, String> body = {
                    'device_id': deviceId, 'screen_id': screenid, 'customer_id': custid, 'user_id': userid, 'media_id': media_id, // 2022-10-01
                    'report_date': s.replaceAll("_", "-"), 'count': '${lastCount}',
                  };
                  if (lastCount != 0) {
                    await updateCountServer(body, data);
                  }
                }
              }
            }
          }
        }

        return true;
      } else {
        getOfflinePlayList();
        // Toast.show("2 - No Internet Connection.Local DATA initialize",
        //     gravity: Toast.bottom, duration: 5);
        showSnack(context, "2 - No Internet Connection.Local DATA initialize");

        return false;
      }
    } catch (e) {
      getOfflinePlayList();
      // Toast.show("2 - No Internet Connection.Local DATA initialize",
      //     gravity: Toast.bottom, duration: 5);
      showSnack(context, "2 - No Internet Connection.Local DATA initialize");

      return false;
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    if (controller != null) {
      controller.dispose();
    }
    controller = null;
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isIOS) {
      _channel.invokeMethod('pauseVideo', 'pauseVideo');
    }
    super.dispose();
  }

  dynamic data;

  @override
  Widget build(BuildContext context) {
    // print(data);

    return WillPopScope(
      onWillPop: () {
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (data != null && data['data'].isNotEmpty && index != -1) ...[
                if (data['data'][index]['media_type'] == "mp4") ...[
                  if (controller != null) ...[
                    Expanded(
                      child: Container(
                        // height: MediaQuery.of(context).size.height,
                        width: double.infinity, color: Colors.black, //VideoPlayer(controller)
                        //CachedVideoPlayer(controller)
                        child: Center(child: VideoPlayer(controller)),
                      ),
                    ),
                  ]
                ] else if (data['data'][index]['media_type'] == "tag") ...[
                  if (webController != null) ...[
                    Expanded(
                        child: WebViewWidget(
                      controller: webController,

                    )),
                  ]

                  // Expanded(
                  //   child: Center(
                  //     child: HtmlWidget(
                  //       '''<iframe src="${data['data'][index]['media_url']}"></iframe>''',
                  //     ),
                  //   ),
                  // ),
                  // Expanded(
                  //   child: Container(
                  //     width: double.infinity,
                  //     color: Colors.black,
                  //     child: BmsVideoPlayer(onCreated: onViewPlayerCreated, x: 0.0, y: 0.0, width: MediaQuery.sizeOf(context).width, height: MediaQuery.sizeOf(context).height),
                  //   ),
                  // )
                ] else ...[
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: Colors.black,
                      child: Center(
                        child: CachedNetworkImage(
                          imageUrl: data['data'][index]['media_url'],
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ]
              ] else ...[
                const CircularProgressIndicator(),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  "Loading Screens",
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  "If it takes too long check screens added or logout and restart",
                  style: TextStyle(fontSize: 10, color: Colors.black),
                ),
              ]
            ],
          ),
        ),
        floatingActionButton: Opacity(
            // hiding the child widget
            opacity: 0,
            child: ElevatedButton(
              onPressed: () async {
                _onScreenSelection(context);
              },
              child: null,
            )),
      ),
    );
  }

  checkVastTag(String mediaUrl) async {
    var data = await http.get(Uri.parse(mediaUrl));
    dynamic responseJson = utf8.decode(data.bodyBytes);

    if (responseJson) {
      if (responseJson.toString().contains("<Vast")) {
        final myTransformer = Xml2Json();
        myTransformer.parse(responseJson);
        var json = myTransformer.toOpenRally();
        print(json);
      }
    }
  }

  bool isRunningAds = true;

  dynamic isDelay;
  dynamic timer;

  updateData() {
    if (isRunningAds && mounted) {
      debugPrint("MOUNTED : $mounted");

      if (index == -1) {
        return;
      }
      if (data['data'] != null && data['data'].isNotEmpty) {
        debugPrint("duration_sec ::: " + data['data'][index]['duration_sec']);

        if (isDelay != null) {
          isDelay = null;
        }

        timer = Timer(Duration(seconds: int.parse(data['data'][index]['duration_sec'])), () async {
          if (controller != null) {
            controller.dispose();
            controller = null;
          }

          print("MOUNTED : $mounted");
          if (mounted) {
            index++;
            if (data['data'].length == index) {
              index = 0;
            }
            updateCount(data['data'][index]);

            if (data['data'][index]['media_type'] == 'jpeg' || data['data'][index]['media_type'] == 'png' || data['data'][index]['media_type'] == 'jpg' || data['data'][index]['media_type'] == 'gif' || data['data'][index]['media_type'] == 'tag') {
              print(index.toString() + " " + data['data'][index]['media_type'].toString());

              if (data['data'][index]['media_type'] == 'tag') {
                String mediaUrl = data['data'][index]['media_url'];

                late final PlatformWebViewControllerCreationParams params;
                if (WebViewPlatform.instance is WebKitWebViewPlatform) {
                  params = WebKitWebViewControllerCreationParams(
                    allowsInlineMediaPlayback: true,
                    mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
                  //   initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow, allowsInlineMediaPlayback: true

                  );
                } else {
                  params = const PlatformWebViewControllerCreationParams();
                }

                final WebViewController controller = WebViewController.fromPlatformCreationParams(params);
                // #enddocregion platform_features
                controller
                  ..setJavaScriptMode(JavaScriptMode.unrestricted)
                  ..setBackgroundColor(const Color(0x00000000))
                  ..setNavigationDelegate(
                    NavigationDelegate(
                      onProgress: (int progress) {
                        debugPrint('WebView is loading (progress : $progress%)');
                      },
                      onPageStarted: (String url) {
                        debugPrint('Page started loading: $url');
                      },
                      onPageFinished: (String url) {
                        debugPrint('Page finished loading: $url');
                      },
                      onWebResourceError: (WebResourceError error) {
                        debugPrint('''Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}''');
                      },
                      onNavigationRequest: (NavigationRequest request) {
                        return NavigationDecision.navigate;
                      },
                      onUrlChange: (UrlChange change) {
                        debugPrint('url change to ${change.url}');
                      },
                      onHttpAuthRequest: (HttpAuthRequest request) {
                        // openDialog(request);
                      },
                    ),
                  )
                  ..addJavaScriptChannel(
                    'Toaster',
                    onMessageReceived: (JavaScriptMessage message) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message.message)),
                      );
                    },
                  )
                  ..loadRequest(Uri.parse(mediaUrl));
                if (controller.platform is AndroidWebViewController) {
                  AndroidWebViewController.enableDebugging(true);
                  (controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
                }

                // checkVastTag(mediaUrl);

                webController = controller;
              }

              if (mounted == true) {
                setState(() {
                  updateData();
                });
              }
            } else if (data['data'][index]['media_type'] == 'mp4') {
              bool is_pay_call = false;

              if (controller != null) {
                controller.dispose();
                is_pay_call = false;
              }

              print(index.toString() + " " + data['data'][index]['media_type'].toString());

              // CachedVideoPlayerController.network(data['data'][index]['media_url'])
              //                   ..initialize().then((_) {

              // url = "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4";
              // url = "https://dr.sf-converter.com/download?id=f65c77fc10df48040bb29daf7358ea59ad3e5c59d8989c0ac5c544f717ee7585&payload=1*eJzVlVuPokgUx7%2BK6aTraXGA4jpJZYKIQqvdXkZtfTGICCUUlFzFzX73LXB2pjf7NJtsspOYH4cq6pw651T9%2Ff0pT8vM89dZ%2FPT5KSwKmn%2F%2B9Kmu636TlkV59PteSj7VbuGFXyokW9fjgbvA0dB4%2Bu3bSuf00wvd8oTTv0fMMshxXJ5wV%2BkcZ4kf9YM0DWK%2Fwic%2F7Vx1Fo3d5uh60Rf%2FRnHmI0FRoCrwmiQCH6Nx6dCd3uxmc7vE9UqSptd6aABMkcjLfUGT%2B6Ig9VUB4BNKOWOWrd5KbpDJZXTeX7RRORzpo%2Fl2%2Frpo3o92M93tXbuwXM2tQ4ALN0CCxINH0uhbkiDzryXbSJ7HqPFzQEJkvANCEBSeRVPUAUnQh6TY2Lc3JckbQHLklmwsO5WAVIgwYAQBjZEoAeoRESUpwAkuvDo5HWmOBEEURJltgnqoWYoVrWfTwbIQAt6%2BR3ESRGv96yXUymhdg4pmFRIAwcRHXcGfxRGhEkhydH%2Bdaby92CfKYLr002CZD47LheGAAGddGl7sJ0iSVInXITiVGRJVpS8JPIhJwWouCxDyogw1GYo8D7oxBSqapusqOFes3hBEvk%2FdGFd%2B5%2FDM%2BsWS4nkBqrCtDDNVUVKAh7bWAGTHa07QOQMF%2B0xmXiXINors%2BT5dltvDyx3uZwHL2s1cVrNH75kXHzNg2uLUgvWorXDXobas33vDXtpytpPUY2xrwx5tbdgjyRlY6oxt4uzBUmZkyYL4r6AkbBeQFu0XpF1DOidVuwvaxvjQKrYQB8gYQ%2FNwM%2BrlwgmN16qAszq2yW5sptSEzoSTD1Z2vtyid7WypBdhSE0nEOXlxcCDkx%2FdL6c3EZqmZfjN%2FLq1M3VZjNKzKJ715dC7Yim61JKZBM9wyH6gC%2Fh25RcvWhswOIfShLqCO7e45qQtXg8ETzZvpnwpptsyCa3h4LpO8PuSHGamszCDWHBVXKRKQe5nyLnzcc0tStFcXA%2Fb2Z7fqCvZsKvQtDLjEZBd5O5O%2FooXGSrAbS12pWB7HgUodZQ7Kh3VlgrfnVax4%2BPkSh3VjlpLtSXUpY5yR6Wj2vExq%2F%2BaytE162eVQ1BURZHhD%2BmAykfpgFBQWKlVSfgPpEP%2BV9LxOAz%2FU%2FEwnMCvBW1yGVClMqnpH%2BW3tNxlV7yxFvft5WWmnc3LZjrdlEUemc54ZqQ0zTfZaLvPPD2gurXah%2B%2BEl%2FdDMdDoVNkUTrRZj%2Bj%2BH6Kxw14zs1fka71y%2BQiquaOr%2BH7Iho6zC23LPtzIYq1r1tgwWtGYnHehM4N73RvYTTEZccn9tm9S3fp6tGA0Gma3wyU4vK1e1ovvolHgIvaZYphp5PdWRfvX1ON6K9%2FN06QnSMyeMzPNMLOMGLOZIsS9W28Vun5vjOOY%2BXj0MTeKp88%2FlOOPPwESps61*1663691514*8bdea65d04b922d5";

              // await VideoCompress.setLogLevel(0);
              // final info = await VideoCompress.compressVideo(
              //   fetchedFile.path,
              //   quality: VideoQuality.MediumQuality,
              //   deleteOrigin: false,
              //   includeAudio: true,
              // );

              try {
                String mediaUrl = data['data'][index]['media_url'];
                var fetchedFile = await DefaultCacheManager().getSingleFile(mediaUrl);

                debugPrint("Playing Video");

                // controller = VideoPlayerController.file(fetchedFile);
                // await controller.initialize();
                // final chewieController = ChewieController(
                //   videoPlayerController: controller,
                //   autoPlay: true,
                //   looping: true,
                // );
                // final playerWidget = Chewie(
                //   controller: chewieController,
                // );
                // /data/user/0/com.unitglo.cmsads/cache/libCachedImageData/f6ec5820-def6-11ef-a475-e5492005a26d.mp4

                controller = VideoPlayerController.file(fetchedFile, videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false, allowBackgroundPlayback: false))
                  ..initialize().then((_) {
                    // controller = VideoPlayerController.network(url)..initialize().then((_) {
                    // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.

                    if (mounted) {
                      setState(() {
                        controller.play();
                        is_pay_call = true;
                      });

                      controller.addListener(() {
                        if (controller != null) {
                          if (is_pay_call && !controller.value.isPlaying) {
                            is_pay_call = false;
                            if (mounted) {
                              setState(() {
                                updateData();
                              });
                            }
                          }
                        }
                      });
                    }
                  }).catchError((error) {
                    debugPrint(error.toString());
                    updateData();
                  });
              } catch (e) {
                debugPrint(e.toString());
                updateData();
              }
            } else {
              setState(() {});
            }
          }
        });

        // await Future.delayed(Duration(seconds: int.parse(data['data'][index]['duration_sec'])));
      }
    }
  }

  updateCount(data) async {
    // deviceId, date, screenId, mediaId, count, userid

    // 0 = {map entry} "media_id" -> "24"
    // 1 = {map entry} "media_type" -> "mp4"
    // 2 = {map entry} "media_url" -> "https://ads.unitglo.com/WebApp/uploads/Media/2///1664268749-dW5pdGdsbw.mp4"
    // 3 = {map entry} "duration_sec" -> "2"
    // 4 = {map entry} "loop_count" -> "1"

    String screenid = sharedPreferences!.getString('screenid') ?? "";
    String userid = sharedPreferences!.getString('userid') ?? "";
    String custid = sharedPreferences!.getString('custid') ?? "";
    String media_id = data["media_id"];

    DateTime now = DateTime.now();

    String date = now.day.toString() + "_" + now.month.toString() + "_" + now.year.toString();

    int lastCount = sharedPreferences!.getInt('count_' + media_id + "_" + screenid + "_" + userid + "_" + date) ?? 0;
    lastCount = lastCount + 1;

    sharedPreferences!.setInt('count_' + media_id + "_" + screenid + "_" + userid + "_" + date, lastCount);
    debugPrint(date.toString());

    if (lastCount > 10) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      // String deviceId = await PlatformDeviceId.getDeviceId??"";
      String deviceId = androidInfo.id;

      String formattedDate = now.year.toString() + "-" + now.month.toString() + "-" + now.day.toString();
      Map<String, String> body = {
        'device_id': deviceId, 'screen_id': screenid, 'customer_id': custid, 'user_id': userid, 'media_id': media_id, // 2022-10-01
        'report_date': formattedDate, 'count': '${lastCount}',
      };

      sharedPreferences!.setInt('count_' + media_id + "_" + screenid + "_" + userid + "_" + date, 0);

      try {
        await updateCountServer(body, 'count_' + media_id + "_" + screenid + "_" + userid + "_" + date);
      } catch (e) {
        String s = sharedPreferences!.getString("lastDate") ?? "";
        if (s.isEmpty) {
          sharedPreferences!.setString("lastDate", date);
        }
      }
    }
  }

  updateCountServer(body, key) async {
    var apiUrl = Uri.parse('${globals.base_url}/setDeviceReport');
    Map<String, String> headers = {
      'content-type': 'application/x-www-form-urlencoded',
    };

    // http.Response response = await http.post(apiUrl, body: body, headers: headers);
    final ioc = HttpClient();
    ioc.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    final httpClient = IOClient(ioc);

    final response = await httpClient.post(apiUrl, body: body, headers: headers);

    var data = json.decode(utf8.decode(response.bodyBytes));
    if (data["status"] == "1") {
      sharedPreferences!.remove(key);
    }
  }

  _onScreenSelection(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Navigate Back"),
          content: const Text("Go Back to Screen Selection Page ?"),
          actions: <Widget>[
            ElevatedButton(
              child: const Text("NO"),
              onPressed: () {
                Navigator.of(context).pop(context);
              },
            ),
            ElevatedButton(
              autofocus: true,
              onPressed: () async {
                isRunningAds = false;
                SharedPreferences preferences = await SharedPreferences.getInstance();
                await preferences.remove("screenid");
                await preferences.remove("apidata");

                print("PLAYLIST DATA : ${widget.serialno}");
                print("PLAYLIST DATA : ${widget.userid}");
                print("PLAYLIST DATA : ${widget.custid}");
                print("PLAYLIST DATA : ${widget.username}");

                DefaultCacheManager manager = DefaultCacheManager();
                manager.emptyCache(); //clears all data in cache.
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => ScreenSelectionPage(
                          serialno: widget.serialno,
                          user_id: widget.userid,
                          customer_id: widget.custid, /* user_name: widget.username,*/
                        ),
                      ),
                      (route) => false);
                }
                dispose();
              },
              child: const Text("YES"),
            ),
          ],
        );
      },
    );
  }

  Future getPlayList(String serialno, String screenid, String custid, String userid) async {
    var apiUrl = Uri.parse('${globals.base_url}/getPlaylist');

    print(apiUrl);

    Map<String, String> headers = {
      'content-type': 'application/x-www-form-urlencoded',
    };
    Map<String, String> body = {
      'serial_no': serialno,
      'screen_id': screenid,
      'customer_id': custid,
      'user_id': userid,
    };

    // http.Response response = await http.post(apiUrl, body: body, headers: headers);
    final ioc = HttpClient();
    ioc.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    final httpClient = IOClient(ioc);

    final response = await httpClient.post(apiUrl, body: body, headers: headers);

    print(response);

    var data = json.decode(utf8.decode(response.bodyBytes));
    print("DATA MY : $data");

    this.data = null;
    index = -1;

    if (mounted && controller != null) {
      controller.dispose();
    }
    //data
    List list = [];

    // if mp4 and loop count >1 for(int i =1: i<loopcount:i++){data.add_video url }
    if (data["data"] != null) {
      for (int i = 0; i < data["data"].length; i++) {
        // if (data['data'][i]['media_type'] == 'tag') {
        //   var uri = Uri.parse("https://web.unitglo.com/demo.html"
        //       // data['data'][i]["media_url"]
        //       );
        //   var htmlData = await http.get(uri);
        //   dynamic responseJson = utf8.decode(htmlData.bodyBytes);
        //
        //   data['data'][i]['htmlData'] = responseJson;
        // }

        if (data['data'][i]['media_type'] == 'mp4') {
          int loopCount = int.tryParse(data['data'][i]['loop_count']) ?? 1;
          for (int j = 0; j < loopCount; j++) {
            list.add(data['data'][i]);
          }
        } else {
          list.add(data['data'][i]);
        }
      }
    }
    this.data = {"data": list};
    if (list.isNotEmpty) {
      index = 0;
    }
    sharedPreferences!.setString('apidata', jsonEncode(data));
    if (timer != null) {
      timer.cancel();
    }
    updateData();

    print("DATA : ${this.data["data"]}");
    print("-----");
    print("Full Api Data ${data}");
    return data;
  }

  getOfflinePlayList() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var shared_data = jsonDecode((sharedPreferences.getString('apidata') ?? ""));

    //print("SHARED DATA : ${jsonDecode(shared_data)}");
    //Toast.show("SHARED DATA : ${jsonDecode(shared_data)}",duration: 15, gravity: Toast.bottom);

    data = null;
    index = -1;

    if (mounted && controller != null) {
      controller.dispose();
    }

    //data
    List list = [];

    // if mp4 and loop count >1 for(int i =1: i<loopcount:i++){data.add_video url }
    if (shared_data["data"].length > 0) {
      for (int i = 0; i < shared_data["data"].length; i++) {
        if (shared_data['data'][i]['media_type'] == 'mp4') {
          int loop_count = (int.parse(shared_data['data'][i]['loop_count']) != null) ? int.parse(shared_data['data'][i]['loop_count']) : 1;
          for (int j = 0; j < loop_count; j++) {
            list.add(shared_data['data'][i]);
          }
        } else {
          list.add(shared_data['data'][i]);
        }
      }
    }

    if (list.isNotEmpty) {
      index = 0;
    }

    data = {"data": list};

    if (timer != null) {
      timer.cancel();
    }

    updateData();

    print("Offline Data : ${data["data"]}");
    print("-----");
    print("Offline Api Data $data");
  }

  var viewPlayerController;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        viewPlayerController.resumeVideo();
        break;
      case AppLifecycleState.paused:
        viewPlayerController.pauseVideo();
        break;
      default:
        break;
    }
  }

  bool isNormalScreen = true;

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'fullScreen':
        isNormalScreen = false;
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        setState(() {});
        break;
      case 'normalScreen':
        isNormalScreen = true;
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        setState(() {});
        break;
    }
  }
}

class _VideoPlayerState extends State<BmsVideoPlayer> {
  String viewType = 'NativeUI';
  var viewPlayerController;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: nativeView(),
    );
  }

  nativeView() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: viewType,
        onPlatformViewCreated: onPlatformViewCreated,
        creationParams: <String, dynamic>{"x": widget.x, "y": widget.y, "width": widget.width, "height": widget.height, "videoURL": "https://storage.googleapis.com/gvabox/media/samples/stock.mp4"},
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else {
      return UiKitView(
        viewType: viewType,
        onPlatformViewCreated: onPlatformViewCreated,
        creationParams: <String, dynamic>{"x": widget.x, "y": widget.y, "width": widget.width, "height": widget.height, "videoURL": "https://storage.googleapis.com/gvabox/media/samples/stock.mp4"},
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
  }

  Future<void> onPlatformViewCreated(id) async {
    if (widget.onCreated == null) {
      return;
    }

    widget.onCreated(BmsVideoPlayerController.init(id));
  }
}

typedef BmsVideoPlayerCreatedCallback = void Function(BmsVideoPlayerController controller);

class BmsVideoPlayerController {
  final MethodChannel _channel = const MethodChannel('bms_video_player');

  BmsVideoPlayerController.init(int id);

  Future<void> loadUrl(String url) async {
    assert(url != null);
    return _channel.invokeMethod('loadUrl', url);
  }

  Future<void> pauseVideo() async {
    return _channel.invokeMethod('pauseVideo', 'pauseVideo');
  }

  Future<void> resumeVideo() async {
    return _channel.invokeMethod('resumeVideo', 'resumeVideo');
  }
}

class BmsVideoPlayer extends StatefulWidget {
  final BmsVideoPlayerCreatedCallback onCreated;
  final x;
  final y;
  final width;
  final height;

  const BmsVideoPlayer({
    super.key,
    required this.onCreated,
    @required this.x,
    @required this.y,
    @required this.width,
    @required this.height,
  });

  @override
  State<StatefulWidget> createState() => _VideoPlayerState();
}
