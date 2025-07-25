import 'dart:convert';
import 'dart:io';

import 'package:dgplay/functions.dart';
import 'package:dgplay/play_list_new_page.dart';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'constants/api_constants.dart' as globals;
import 'login_page.dart';

class ScreenSelectionPage extends StatefulWidget {
  final String user_id, customer_id, serialno /*, user_name*/;

  const ScreenSelectionPage({super.key, required this.user_id, required this.customer_id, required this.serialno /*, this.user_name*/
      });

  @override
  _ScreenSelectionPageState createState() => _ScreenSelectionPageState();
}

class _ScreenSelectionPageState extends State<ScreenSelectionPage> {
  // List<String> _locations = ['A', 'B'];
  int imageindex = 0;

  // String _selcted = 'A';

/*  List<ImageProvider> bg = [
    AssetImage("assets/iron.jpg"),
    AssetImage("assets/image.jpg"),
    AssetImage("assets/black.png")
  ];*/
  Future? api;
  String _classValue = "";
  String username = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print(widget.user_id);
    print(widget.customer_id);
    api = getScreenList(widget.user_id, widget.customer_id);
    getUsername();

    getDevice();
  }

  String buildNumber = "";

  getDevice() async {
    // DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    // AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    // print('Running on ${androidInfo.model}');

    WidgetsFlutterBinding.ensureInitialized();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String appName = packageInfo.appName;
    String packageName = packageInfo.packageName;
    String version = packageInfo.version;
    buildNumber = packageInfo.buildNumber;
  }

  Future getUsername() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      username = sharedPreferences.getString('username') ?? "";
      print(username);
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    print("USERNAME : $username");
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          "Ads",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          Center(
              child: Text(
            username,
            style: const TextStyle(color: Colors.white),
          )),
          const SizedBox(
            width: 10,
          ),
          InkWell(
            onTap: () {
              _logout(context);
            },
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(
                Icons.logout,
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(

            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width/5),
              child: SizedBox(
                  height: double.infinity,
                  width: double.infinity, // color: Colors.white70,
                  // decoration: const BoxDecoration(
                  //     image: DecorationImage(
                  //         image: AssetImage("assets/img.png"), fit: BoxFit.cover)),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: InkWell(
                                onTap: () async {
                                  String url = globals.base_url + "/checkBuild/" + buildNumber;
                                  // String url = "https://ads.unitglo.com/AJS-Application.apk";
                                  final Uri _url = Uri.parse(url);

                                  _launchUrl(_url);
                                }, // http://ads.dgplay.live
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8, bottom: 8.0),
                                  child: appLogo(size, path: "assets/logo.png", padding: 100),
                                )),
                          ),
                          // const Padding(
                          //   padding: EdgeInsets.all(16.0),
                          //   child: Text("MobiYoung"),
                          // ),

                          Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: FutureBuilder(
                                  future: api,
                                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                                    if (snapshot.hasData) {
                                      print(snapshot.data["data"][0]);

                                      print("Snapshot : ${snapshot.data}");
                                      print("----------");
                                      Map yourJson = snapshot.data;

                                      List<DropdownMenuItem<String>> _menuItems;

                                      List dataList = yourJson["data"];

                                      print("INDEX");
                                      _classValue = dataList[0]["screen_id"].toString();
                                      print((dataList[0]["screen_id"]).toString());

                                      _menuItems = List.generate(
                                        dataList.length,
                                        (i) => DropdownMenuItem(

                                          value: (dataList[i]["screen_id"]).toString(),
                                          child: Text(
                                            "${dataList[i]["screen_name"]}",
                                            style: const TextStyle(color: Colors.black),
                                          ),
                                        ),
                                      );
                                      return DropdownButtonFormField<String>(

                                        validator: (value) {
                                          if (value == "" || value == null) {
                                            return 'Please Select Your Screen';
                                          }
                                          return null;
                                        },
                                        decoration: const InputDecoration(
                                          filled: true,
                                          alignLabelWithHint: true,
                                          fillColor: Colors.white,
                                          hintText: "Your Screen",
                                          hintStyle: TextStyle(color: Colors.black87),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.black, width: 1.0, style: BorderStyle.solid),
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(12),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder( // Add this for when the field is focused
                                            borderSide: BorderSide(color: Colors.red, width: 2.0, style: BorderStyle.solid), // Example: blue border when focused
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(12),
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder( // Add this for when there's an error
                                            borderSide: BorderSide(color: Colors.red, width: 2.0, style: BorderStyle.solid), // Example: red border for errors
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(12),
                                            ),
                                          ),
                                          focusedErrorBorder: OutlineInputBorder( // Add this for when the field is focused and has an error
                                            borderSide: BorderSide(color: Colors.redAccent, width: 2.0, style: BorderStyle.solid), // Example: redAccent border for focused error
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(12),
                                            ),
                                        ),
                                        ),

                                        dropdownColor: Colors.white,
                                        items: _menuItems,
                                        value: _classValue,
                                        onChanged: (value) {
                                          setState(() {
                                            _classValue = value ?? "";
                                            imageindex = int.parse(_classValue);
                                            print("Image Index : $imageindex");

                                            print("Class");
                                            print(value);
                                            print(_classValue);
                                          });
                                        },
                                      );
                                    }

                                    return const Center(
                                        child: Column(
                                      children: [
                                        CircularProgressIndicator(
                                          color: Colors.red,
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Text("No Data Found start again"),
                                      ],
                                    ));
                                  }),
                              // ),
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.10,
                          ),
                          Center(
                            child: MaterialButton(
                                color: Colors.red,
                                onPressed: () async {
                                  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
                                  await sharedPreferences.setString('screenid', imageindex == 0 ? _classValue : imageindex.toString());
                                  print("SCREENSEELCTION : $imageindex");
                                  print("Class Value : $_classValue");

                                  Navigator.of(context).push(MaterialPageRoute<Map>(builder: (BuildContext context) {
                                    return PlayList(
                                      prefs: sharedPreferences,
                                      screenid: imageindex == 0 ? _classValue : imageindex.toString(),
                                      serialno: widget.serialno,
                                      userid: widget.user_id,
                                      custid: widget.customer_id,
                                      username: username,
                                    );
                                  }));
                                },
                                child: const Text(
                                  "Save",
                                  style: TextStyle(color: Colors.white),
                                )),
                          ),


                        ],
                      ),
                    ),
                  )),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text("Build Number : $buildNumber"),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(_url) async {
    if (!await launchUrl(_url)) {
      throw 'Could not launch $_url';
    }
  }

  _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Sign out confirmation"),
          content: const Text("Signing off will erase all data stored by the app on this device. Are you sure you want to logoff?"),
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
                SharedPreferences preferences = await SharedPreferences.getInstance();

                String serialNo = preferences.getString("serialNo") ?? "";
                await preferences.clear();

                preferences.setString("serialNo", serialNo);

                Navigator.of(context).pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
              },
              child: const Text("YES"),
            ),
          ],
        );
      },
    );
  }

  Future getScreenList(String userid, String custid) async {
    var apiUrl = Uri.parse('${globals.base_url}/getScreenList');

    print(apiUrl);

    Map<String, String> headers = {
      'content-type': 'application/x-www-form-urlencoded',
    };

    print("Headers");
    Map<String, String> body = {'user_id': '$userid', 'customer_id': '$custid'};

    print("ody");

    // (apiUrl, body: body, headers: headers);
    final ioc = HttpClient();
    ioc.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    final httpClient = IOClient(ioc);

    final response = await httpClient.post(apiUrl, body: body, headers: headers);
//    http.Response response = await http.post(apiUrl, body: body, headers: headers);

    print("REsisne $response");

    print(response);

    var data = json.decode(utf8.decode(response.bodyBytes));

    print("DATA : ${data["data"]}");
    print("-----");
    print("Full Api Data ${data}");
    return data;
  }
}

/*
*
*
* /*_locations.map((String value) {
                                    return new DropdownMenuItem<String>(
                                      value: value,
                                      child: new Text(value),
                                    );
                                  }).toList(),*/*/
