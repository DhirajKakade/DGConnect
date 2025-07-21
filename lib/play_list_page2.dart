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
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'constants/api_constants.dart' as globals;

class PlayListPage extends StatefulWidget {
  String screenid, serialno, custid, userid, username;

  PlayListPage({super.key, required this.screenid, required this.serialno, required this.userid, required this.custid, required this.username});

  @override
  State<PlayListPage> createState() => _PlayListPageState();
}

class _PlayListPageState extends State<PlayListPage> with WidgetsBindingObserver {
  // StreamSubscription<QuerySnapshot>? _eventsSubscription;
  Future? api;
  var controller;

  late Player player;
  late final VideoController videoController;
  late final StreamSubscription<bool> playingSubscription;

  var webController;

  //CachedVideoPlayerController controller;

  int index = 0;
  int currentIndex = 0;

  SharedPreferences? sharedPreferences;
  bool isNormalScreen = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    // ToastContext().init(context);

    SchedulerBinding.instance.addPostFrameCallback((_) => initDb(true));
  }

  Future<void> _initPlayer() async {
    player = Player(
      configuration: const PlayerConfiguration(
        logLevel: MPVLogLevel.debug,
      ),
    );
    videoController = VideoController(
      player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true,
        hwdec: 'no',
      ),
    );

    playingSubscription = player.stream.playing.listen((isPlaying) {
      if (isPlaying) {
        print("✅ Video started playing");
        // updateData();
        // You can setState or trigger your logic here
      } else {

        print("⏸️ Video paused or stopped");
        if((isDataLoaded && data != null && data['data'].isNotEmpty && index != -1) && data['data'][index]['media_type'] == "mp4") {
          updateData();
        }
      }
    });
  }

  initDb(bool isFirstUpdate) async {
    sharedPreferences = await SharedPreferences.getInstance();
    isRunningAds = true;
    // isInternet();
    checkInternetConnection(isFirstUpdate);
  }

  Future<bool> checkInternetConnection(bool isFirstUpdate) async {
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

              await getPlayList(
                widget.serialno,
                widget.screenid,
                widget.custid,
                widget.userid,
              );
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

      if (context.mounted) {
        // showSnack(context, "Connection OK");
      }

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
                // String deviceId = androidInfo.id;

                String serialno = sharedPreferences!.getString("serialNo") ?? "";

                if (serialno.isEmpty) {
                  serialno = idGenerator();
                }

                int lastCount = sharedPreferences!.getInt(data) ?? 0;

                Map<String, String> body = {
                  'device_id': serialno, 'screen_id': screenid, 'customer_id': custid, 'user_id': userid, 'media_id': media_id, // 2022-10-01
                  'report_date': s.replaceAll("_", "-"), 'count': '$lastCount',
                };
                if (lastCount != 0) {
                  await updateCountServer(body, data);
                  await checkForcedUpdate(body);
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

    try {} catch (e) {
      getOfflinePlayList();
      // Toast.show("2 - No Internet Connection.Local DATA initialize",
      //     gravity: Toast.bottom, duration: 5);
      showSnack(context, "2 - No Internet Connection.Local DATA initialize");

      return false;
    }
  }

  @override
  void dispose() {
    player.dispose();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    if (controller != null) {
      controller.dispose();
    }
    controller = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  dynamic data;

  bool isDataLoaded = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isDataLoaded && data != null && data['data'].isNotEmpty && index != -1) ...[
                    if (data['data'][index]['media_type'] == "tag") ...[
                      if (webController != null) ...[
                        Expanded(
                            child: WebViewWidget(
                          controller: webController,
                        )),
                      ]
                    ] else ...[
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: Colors.black,
                          child: Center(
                            child: CachedNetworkImage(
                              imageUrl: data['data'][index]['media_url'],
                              fit: BoxFit.fill,
                              height: double.infinity,
                              width: double.infinity,
                            ),
                          ),
                        ),
                      ),
                    ]
                  ] else ...[
                    if (isDataLoaded && data != null && data['data'].isEmpty) ...[
                      const Text(
                        "Data Not available",
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      )
                    ] else ...[
                      const CircularProgressIndicator(),
                      const SizedBox(
                        height: 16,
                      ),
                      const Text(
                        "Loading Screens",
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Text(
                        "If it takes too long check screens added or logout and restart",
                        style: TextStyle(fontSize: 10, color: Colors.black),
                      ),
                    ],
                  ]
                ],
              ),
              if ((isDataLoaded && data != null && data['data'].isNotEmpty && index != -1) && data['data'][index]['media_type'] == "mp4") ...[
                if (controller != null || true) ...[
                  Video(
                    controller: videoController,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.fill,
                    wakelock: true,
                    fill: Colors.transparent,
                    alignment: Alignment.center,
                  ),
                ]
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

  String idGenerator() {
    final now = DateTime.now();
    return now.microsecondsSinceEpoch.toString();
  }

  bool isRunningAds = true;

  dynamic isDelay;
  dynamic timer;
  bool isVeryFirstCall = true;

  updateData() {
    if (isRunningAds && mounted) {
      debugPrint("MOUNTED : $mounted");

      print("index:::: $index");
      if (index == -1) {
        return;
      }
      if (data['data'] != null && data['data'].isNotEmpty) {
        debugPrint("duration_sec ::: ${data['data'][index]['duration_sec']}");

        if (isDelay != null) {
          isDelay = null;
        }

        int iDuration = int.tryParse(data['data'][index]['duration_sec'].toString()) ?? 0;

        if (isVeryFirstCall) {
          iDuration = 1;
          isVeryFirstCall = false;
        }

        timer = Timer(Duration(seconds: iDuration), () async {
          await player.stop();

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
                    allowsInlineMediaPlayback: true, mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
                    //   initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow, allowsInlineMediaPlayback: true
                  );
                } else {
                  params = const PlatformWebViewControllerCreationParams();
                }

                WebViewController.fromPlatformCreationParams(params)
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

              try {
                String mediaUrl = data['data'][index]['media_url'];
                var fetchedFile = await DefaultCacheManager().getSingleFile(mediaUrl);

                debugPrint("Playing Video:: ${fetchedFile.path}");

                await player.open(Media(fetchedFile.path));
                setState(() {});
                is_pay_call = true;

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
    // await checkForcedUpdate({"serial_no": widget.serialno, "screen_id" : screenid, "device_uuid" : widget.serialno});

    if (lastCount > 2) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      String formattedDate = now.year.toString() + "-" + now.month.toString() + "-" + now.day.toString();
      Map<String, String> body = {
        'device_id': widget.serialno, 'screen_id': screenid, 'customer_id': custid, 'user_id': userid, 'media_id': media_id, // 2022-10-01
        'report_date': formattedDate, 'count': '$lastCount',
      };

      sharedPreferences!.setInt('count_' + media_id + "_" + screenid + "_" + userid + "_" + date, 0);

      try {
        await updateCountServer(body, 'count_' + media_id + "_" + screenid + "_" + userid + "_" + date);
        await checkForcedUpdate({"serial_no": widget.serialno, "screen_id": screenid, "device_uuid": widget.serialno});
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

    final ioc = HttpClient();
    ioc.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    final httpClient = IOClient(ioc);

    final response = await httpClient.post(apiUrl, body: body, headers: headers);

    if (response.statusCode == 200) {
      var data = json.decode(utf8.decode(response.bodyBytes));
      if (data["status"] == "1") {
        sharedPreferences!.remove(key);
      }
    }
  }

  checkForcedUpdate(body) async {
    var apiUrl = Uri.parse('${globals.base_url}/checkForcedUpdate');
    Map<String, String> headers = {
      'content-type': 'application/x-www-form-urlencoded',
    };
    final ioc = HttpClient();
    ioc.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    final httpClient = IOClient(ioc);
    final response = await httpClient.post(apiUrl, body: body, headers: headers);
    var data = json.decode(utf8.decode(response.bodyBytes));

    if (data["status"] != null && data["status"] is bool) {
      if (data["status"]) {
        await getPlayList(widget.serialno, widget.screenid, widget.custid, widget.userid);
      }
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

  Future getPlayList(
    String serialno,
    String screenid,
    String custid,
    String userid,
  ) async {
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

    isDataLoaded = true;

    if (mounted && controller != null) {
      controller.dispose();
    }
    //data
    List list = [];

    // if mp4 and loop count >1 for(int i =1: i<loopcount:i++){data.add_video url }
    if (data["data"] != null) {
      for (int i = 0; i < data["data"].length; i++) {
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
    } else {
      if (context.mounted) {
        setState(() {});
      }
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
    data = null;
    index = -1;
    isDataLoaded = true;

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
}
