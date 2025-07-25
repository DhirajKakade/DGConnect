import 'dart:async';
import 'dart:io';

import 'package:dgplay/api_service.dart';
import 'package:dgplay/functions.dart';
import 'package:dgplay/screen_selection_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PlayList extends StatefulWidget {
  final SharedPreferences prefs;
  final String screenid, serialno, custid, userid, username;

  const PlayList({super.key, required this.prefs, required this.screenid, required this.serialno, required this.custid, required this.userid, required this.username});

  @override
  State<PlayList> createState() => _PlayListState();
}

class _PlayListState extends State<PlayList> {
  dynamic timer;
  int index = 0;
  late Player player;
  late VideoController videoController;
  List<dynamic> data = [];
  Map<String, dynamic> selectedData = {};
  var webController;
  bool isLoading = true;

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    SchedulerBinding.instance.addPostFrameCallback(
      (timeStamp) {
        initPlayer();
        getData();
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    if (timer != null) {
      timer?.cancel();
    }
    player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  PackageInfo? info;
  getData() async {
    // info = await PackageInfo.fromPlatform();
    bool isData = await initData();
    if (isData) {
      updateData();
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    // data.clear();
    return Scaffold(
      body: Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: isLoading
            ? appLogo(size)
            : selectedData.isEmpty
                ? const Center(child: Text("No data available", style: TextStyle(color: Colors.white)))
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      if (selectedData["media_type"] == "mp4") ...[
                        MaterialVideoControlsTheme(
                            normal: const MaterialVideoControlsThemeData(displaySeekBar: false, bottomButtonBar: [
                              MaterialPositionIndicator(),
                            ],controlsHoverDuration: Duration(seconds: 1)),
                            fullscreen: const MaterialVideoControlsThemeData(
                              displaySeekBar: false,
                              automaticallyImplySkipNextButton: false,
                              automaticallyImplySkipPreviousButton: false,
                            ),
                            child: Video(controller: videoController, width: double.infinity, height: double.infinity, fit: BoxFit.fill, wakelock: true, fill: Colors.transparent, alignment: Alignment.center)),

                        // Video(controller: videoController, width: double.infinity, height: double.infinity, fit: BoxFit.fill, wakelock: true, fill: Colors.transparent, alignment: Alignment.center)
                      ] else if (selectedData["media_type"] == "jpg" || selectedData["media_type"] == "png" || selectedData["media_type"] == "jpeg") ...[
                        Image.file(
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.fill,
                          File(selectedData["file"] ?? ""),
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.white, size: 30),
                        ),
                      ] else if (selectedData["media_type"] == "tag" && webController != null) ...[
                        if (selectedData["file"] != "") ...[WebViewWidget(controller: webController)] else ...[Image.asset("name")],
                      ],
                      // Align(alignment: Alignment.bottomCenter, child: Padding(
                      //   padding: const EdgeInsets.only(bottom: 8.0),
                      //   child: Text(info != null ? info!.version : ""),
                      // ))
                    ],
                  ),
      ),
      floatingActionButton: Opacity(
          // hiding the child widget
          opacity: 0,
          child: ElevatedButton(
            onPressed: () async {
              onScreenSelection(context, widget.prefs, widget.serialno, widget.userid, widget.custid, widget.username);
            },
            child: null,
          )),
    );
  }

  Future<void> initPlayer() async {
    player = Player(configuration: const PlayerConfiguration(logLevel: MPVLogLevel.debug));
    videoController = VideoController(player, configuration: const VideoControllerConfiguration(enableHardwareAcceleration: true, hwdec: 'no'));
    player.stream.completed.listen((completed) {
      if (completed) {
        updateTime(0, data);
      }
    });
  }

  updateData() async {
    if (data.isEmpty) {
      return;
    }
    await player.stop();
    selectedData.addAll(data[index]);
    int iDuration = int.tryParse(selectedData["duration_sec"]) ?? 0;
    String mediaUrl = selectedData["media_url"];

    if (selectedData["media_type"] != "tag") {
      String dbMediaFile = widget.prefs.getString(mediaUrl) ?? "";
      if (dbMediaFile.isEmpty) {
        var fetchedFile = await DefaultCacheManager().getSingleFile(mediaUrl);
        widget.prefs.setString(mediaUrl, fetchedFile.path);
        selectedData["file"] = fetchedFile.path;
      } else {
        selectedData["file"] = dbMediaFile;
      }
      debugPrint("playing media::: ${selectedData["media_id"]},${selectedData["media_type"]} ${selectedData["file"]}");

      if (selectedData["media_type"] == "mp4") {
        await player.open(Media(selectedData["file"]), play: true,);
        // await player.add(Media(selectedData["file"]));
      } else {
        updateTime(iDuration, data);
      }
    } else {
      webController = WebViewController.fromPlatformCreationParams(const PlatformWebViewControllerCreationParams())
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
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
              if (mounted) {
                setState(() {
                  selectedData["file"] = "assets/logo.png";
                });
              }
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
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message.message)));
          },
        )
        ..loadRequest(Uri.parse(mediaUrl));

      updateTime(iDuration, data);
    }

    setState(() {});
  }

  updateTime(int iDuration, List<dynamic> data) {
    if (iDuration == 0) {
      if (index < data.length - 1) {
        index++;
        updateData();
      } else {
        index = 0;
        updateData();
      }
    } else {
      timer = Timer(Duration(seconds: iDuration), () async {
        if (index < data.length - 1) {
          index++;
          updateData();
        } else {
          index = 0;
          updateData();
        }
      });
    }

    updateCount(selectedData);
  }

  updateCount(data) async {
    String screenid = widget.prefs.getString('screenid') ?? "";
    String userid = widget.prefs.getString('userid') ?? "";
    String custid = widget.prefs.getString('custid') ?? "";
    String media_id = data["media_id"];

    DateTime now = DateTime.now();

    String date = now.day.toString() + "_" + now.month.toString() + "_" + now.year.toString();

    int lastCount = widget.prefs.getInt('count_' + media_id + "_" + screenid + "_" + userid + "_" + date) ?? 0;
    lastCount = lastCount + 1;

    widget.prefs.setInt('count_' + media_id + "_" + screenid + "_" + userid + "_" + date, lastCount);
    debugPrint(date.toString());
    // await checkForcedUpdate({"serial_no": widget.serialno, "screen_id" : screenid, "device_uuid" : widget.serialno});

    if (lastCount > 2) {
      // DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      // AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      String formattedDate = "${now.year}-${now.month}-${now.day}";
      Map<String, String> body = {
        'device_id': widget.serialno, 'screen_id': screenid, 'customer_id': custid, 'user_id': userid, 'media_id': media_id, // 2022-10-01
        'report_date': formattedDate, 'count': '$lastCount',
      };

      widget.prefs.setInt('count_' + media_id + "_" + screenid + "_" + userid + "_" + date, 0);

      try {
        await ApiService().updateCountServer(body, 'count_' + media_id + "_" + screenid + "_" + userid + "_" + date, widget.prefs);
        bool isForceUpdate = await ApiService().checkForcedUpdate({"serial_no": widget.serialno, "screen_id": screenid, "device_uuid": widget.serialno}, widget.prefs, widget.serialno, widget.screenid, widget.custid, widget.userid);
        if (isForceUpdate) {
          initData();
        }
      } catch (e) {
        String s = widget.prefs.getString("lastDate") ?? "";
        if (s.isEmpty) {
          widget.prefs.setString("lastDate", date);
        }
      }
    }
  }

  initData() async {
    String screenid = widget.prefs.getString("screenid") ?? "";
    if (screenid.isEmpty) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => ScreenSelectionPage(user_id: widget.userid, customer_id: widget.custid, serialno: widget.serialno),
        ),
        (route) => false,
      );
      isLoading = false;
      return false;
    } else {
      List<dynamic> playList = await ApiService().getPlayList(widget.prefs, widget.serialno, screenid, widget.custid, widget.userid);

      if (playList.isNotEmpty) {
        data.clear();
        data.addAll(playList);
      }

      isLoading = false;
      return true;
    }
  }
}
