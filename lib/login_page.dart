import 'dart:async';
import 'dart:convert';
import 'dart:io';

// import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:android_intent_plus/android_intent.dart' as androidIntent;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dgplay/api_service.dart';
import 'package:dgplay/functions.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants/api_constants.dart' as globals;
import 'screen_selection_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  TextEditingController _usernameFieldController = TextEditingController();
  TextEditingController _passwordFieldController = TextEditingController();
  bool isLoginById = false;
  bool apiCall = false;
  var _loginResult;
  var user_id, custid, msg, username;

  Future? api;
  String serialno = "";
  String device_name = "", uuid = "", device_info = "", allDeviceData = "";
  TextEditingController codeController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    checkInternetConnection();
  }

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'version.securityPatch': build.version.securityPatch,
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release,
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.incremental': build.version.incremental,
      'version.codename': build.version.codename,
      'version.baseOS': build.version.baseOS,
      'board': build.board,
      'bootloader': build.bootloader,
      'brand': build.brand,
      'device': build.device,
      'display': build.display,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'supported32BitAbis': build.supported32BitAbis,
      'supported64BitAbis': build.supported64BitAbis,
      'supportedAbis': build.supportedAbis,
      'tags': build.tags,
      'type': build.type,
      'isPhysicalDevice': build.isPhysicalDevice,
      // 'systemFeatures': build.systemFeatures,
    };
  }

  String idGenerator() {
    final now = DateTime.now();
    return now.microsecondsSinceEpoch.toString();
  }

  Future<void> getdeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    // print("Model TV : " + androidInfo.model);
    // print("TV Id: " + androidInfo.id);
    // print("ID : " + androidInfo.id);
    // print("Brand : " + androidInfo.brand);

    bool isTV = androidInfo.systemFeatures.contains('android.software.leanback_only');
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    // await sharedPreferences.setString('serialno', androidInfo.id);
    // String deviceId = await PlatformDeviceId.getDeviceId ?? "";

    String serialno = sharedPreferences.getString("serialNo") ?? "";

    if (serialno.isEmpty) {
      serialno = idGenerator();
    }

    await sharedPreferences.setString('serialNo', serialno);

    device_name = androidInfo.model;
    device_info = androidInfo.brand;

    // setState(() {
    // serialno = androidInfo.id;

    allDeviceData = jsonEncode(androidInfo.data);
    //   device_name = androidInfo.model;
    //   device_info = androidInfo.brand;
    // });
/*
    isInternet();*/
    // registerDevice(androidInfo.model, androidInfo.id, uuid, androidInfo.brand,_readAndroidBuildData(androidInfo).toString());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          body: Stack(
            children: <Widget>[
              Center(
                child: Container(
                  alignment: Alignment.topCenter,
                  child: const Card(
                    color: Colors.white,
                    elevation: 0.0,
                  ),
                ),
              ),
              if (packageInfo != null) ...[
                Container(
                    padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * .15, right: 20.0, left: 20.0),
                    child: Container(
                        alignment: Alignment.topCenter,
                        child: Text(
                          packageInfo!.appName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30, color: Colors.white),
                        ))),
              ],
              Center(
                child: Container(
                  width: MediaQuery.sizeOf(context).width / 2,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      Image.asset("assets/logo.png"),
                      TextField(
                        controller: _usernameFieldController,
                        keyboardType: TextInputType.text,
                        textAlign: TextAlign.left,
                        cursorColor: Colors.black,
                        style: const TextStyle(
                          fontFamily: "WorkSansSemiBold",
                          fontSize: 18.0,
                          color: Colors.black,
                        ),
                        decoration: const InputDecoration(
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                          contentPadding: EdgeInsets.all(16.0),
                          labelText: 'Email Id',
                          labelStyle: TextStyle(color: Colors.black),
                          prefixIcon: Icon(Icons.person_outline, color: Colors.black, size: 20.0),
                        ),
                      ),
                      TextField(
                        controller: _passwordFieldController,
                        keyboardType: TextInputType.text,
                        textAlign: TextAlign.left,
                        cursorColor: Colors.black,
                        style: const TextStyle(
                          fontFamily: "WorkSansSemiBold",
                          fontSize: 18.0,
                          color: Colors.black,
                        ),
                        obscureText: true,
                        decoration: const InputDecoration(
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                          contentPadding: EdgeInsets.all(16.0),
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Colors.black),
                          prefixIcon: Icon(Icons.lock, color: Colors.black, size: 20.0),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: isLoginById
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                      ))
                                    : ButtonTheme(
                                        minWidth: MediaQuery.of(context).size.width * 0.10,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                          ), // color: Colors.white,
                                          child: const Text(
                                            'LOGIN BY ID',
                                            style: TextStyle(color: Colors.white),
                                            maxLines: 1,
                                          ),
                                          onPressed: () async {
                                            //   https://ads.dgplay.live/API/Mobile/AuthCode/web
                                            // ApiService().authCodeLogin;
                                            dynamic action = await showDialog(
                                              context: context,

                                              builder: (context) => AlertDialog(
                                                scrollable: true,
                                                title: const Text("Enter Code"),
                                                content: TextField(
                                                  autofocus: true,
                                                  decoration: const InputDecoration(
                                                    hintText: "CF413F-619",
                                                    border: UnderlineInputBorder(
                                                      borderSide: BorderSide(color: Colors.red),
                                                    ),
                                                    focusedBorder: UnderlineInputBorder(
                                                      borderSide: BorderSide(color: Colors.red), // Focused underline color
                                                    ),
                                                  ),
                                                  controller: codeController,
                                                  cursorColor: Colors.red,
                                                ),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: const Text("Close", style: TextStyle(color: Colors.black),)),
                                                  MaterialButton(
                                                      color: Colors.red,
                                                      textColor: Colors.white,
                                                      onPressed: () {
                                                        Navigator.pop(context, true);
                                                      },
                                                      child: const Text("Connect"))
                                                ],
                                              ),
                                            );

                                            if (action != null && action && codeController.text.isNotEmpty) {

                                              SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

                                              String serialNo = sharedPreferences.getString("serialNo") ?? "";

                                              if (serialNo.isEmpty) {
                                                serialNo = idGenerator();
                                              }

                                              await sharedPreferences.setString('serialNo', serialNo);
                                              if (context.mounted) {
                                                await ApiService().authCodeLogin(context, sharedPreferences, codeController.text, serialNo);
                                              }
                                            }
                                          },
                                        ),
                                      ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: apiCall
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                      ))
                                    : ButtonTheme(
                                        minWidth: MediaQuery.of(context).size.width * 0.10,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                          ), // color: Colors.white,
                                          child: const Text(
                                            'LOGIN',
                                            maxLines: 1,
                                            style: TextStyle(color: Colors.white),
                                          ),
                                          onPressed: () async {
                                            FocusScope.of(context).requestFocus(new FocusNode());

                                            if (_usernameFieldController.text == "" || _passwordFieldController.text == "") {
                                              // Toast.show("Both emailId and password are required", duration: 5, gravity: Toast.bottom);
                                              showSnack(context, "Both emailId and password are required");
                                              // || connectivityResult == ConnectivityResult.ethernet || connectivityResult == ConnectivityResult.mobile
                                            } else {
                                              setState(() {
                                                apiCall = true;
                                              });

                                              SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

                                              serialno = sharedPreferences.getString("serialNo") ?? "";

                                              if (serialno.isEmpty) {
                                                serialno = idGenerator();
                                                await sharedPreferences.setString('serialNo', serialno);
                                              }

                                              print("SERIAL NO : $serialno");

                                              _loginResult = await loginUser(_usernameFieldController.text, _passwordFieldController.text, serialno);
                                              if (await _loginResult == true) {
                                                // Toast.show(msg, duration: 5, gravity: Toast.bottom);
                                                if (context.mounted) {
                                                  // showSnack(context, msg);
                                                }

                                                print("USER ID : $user_id + CUST ID : $custid");
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) => ScreenSelectionPage(
                                                            user_id: user_id,
                                                            customer_id: custid,
                                                            serialno: serialno, /*user_name: username,*/
                                                          )),
                                                );
                                                print("Success Login");
                                              } else {
                                                setState(() {
                                                  apiCall = false;
                                                });
                                                // Toast.show(msg, duration: 5, gravity: Toast.bottom);

                                                if (context.mounted) {
                                                  showSnack(context, msg);
                                                }

                                                print("Failed Login");
                                              }
                                            }
                                          },
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8),
                        child: MaterialButton(
                          onPressed: () async {
                            if (Platform.isAndroid) {
                              PackageInfo packageInfo = await PackageInfo.fromPlatform();
                              androidIntent.AndroidIntent intent = androidIntent.AndroidIntent(
                                action: 'action_application_details_settings', data: 'package:${packageInfo.packageName}', // replace com.example.app with your applicationId
                              );
                              await intent.launch();
                            }
                          },
                          child: const Text("Uninstall"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // floatingActionButton: Opacity(
          //     // hiding the child widget
          //     opacity: 0,
          //     child: ElevatedButton(
          //       onPressed: () {
          //         isInternet();
          //       }, child: Container(),
          //     )),
        ));
  }

  PackageInfo? packageInfo;
  Future<bool> checkInternetConnection() async {
    try {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

      serialno = sharedPreferences.getString("serialNo") ?? "";

      if (serialno.isEmpty) {
        serialno = idGenerator();
        await sharedPreferences.setString('serialNo', serialno);
      }

      packageInfo = await PackageInfo.fromPlatform();

      var response = await http.get(Uri.parse('https://google.com'));
      if (response.statusCode == 200) {
        await getdeviceInfo();
        await registerDevice(device_name, serialno, uuid, device_info, allDeviceData);

        if (mounted) {
          setState(() {});
        }

        return true;
      } else {
        if (mounted) {
          setState(() {});
        }
        return false;
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }

      return false;
    }
  }

  // Future<bool> isInternet() async {
  //
  //   var connectivityResult = await (Connectivity().checkConnectivity());
  //   if (connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi || connectivityResult == ConnectivityResult.ethernet) {
  //     await getdeviceInfo();
  //     await registerDevice(device_name, serialno, uuid, device_info, allDeviceData);
  //     return true;
  //   } else {
  //     return false;
  //   }
  // }

  Future<dynamic> registerDevice(String device_name, String serial_no, String uuid, String device_info, full_device_details) async {
    var apiUrl = Uri.parse("${globals.base_url}/registerDevice");
    Map<String, String> headers = {'content-type': 'application/x-www-form-urlencoded'};

    Map<String, String> body = {
      'device_name': device_name,
      'serial_no': serial_no,
      'device_uuid': serial_no,
      'device_details': device_info,
      'full_device_details': full_device_details,
    };

    try {
      final ioc = HttpClient();
      ioc.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      final httpClient = IOClient(ioc);

      final response = await httpClient.post(apiUrl, body: body, headers: headers);

//      http.Response response = await http.post(apiUrl, body: body, headers: headers);

      var data = json.decode(response.body);

      if (data['status'] == '1') {
        print("Device Registered Successfully");
        // Toast.show("Device Registered Successfully", gravity: Toast.bottom, duration: 3);
        if (mounted) {
          showSnack(context, "Device Registered Successfully");
        }
      } else {
        // print("Failed to Register Device");
        // Toast.show("Failed to Register Device.Check Internet connection", gravity: Toast.bottom, duration: 3);
        if (mounted) {
          showSnack(context, "Failed to Register Device.Check Internet connection");
        }
      }

      print("DATA : $data");
      return data;
    } catch (e) {
      debugPrint(e.toString());
      // Toast.show("Failed to Register Device.Check Internet connection", gravity: Toast.bottom, duration: 3);
      if (mounted) {
        showSnack(context, "Failed to Register Device.Check Internet connection");
      }
    }
  }

  Future<dynamic> loginUser(String useremail, String password, String serial_no) async {
    var apiUrl = Uri.parse("${globals.base_url}/AuthUser");

    Map<String, String> headers = {'content-type': 'application/x-www-form-urlencoded'};

    print("Login api $serial_no");

    Map<String, String> body = {
      'user_email': useremail,
      'password': password,
      'serial_no': serial_no,
    };

    final ioc = HttpClient();
    ioc.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    final httpClient = IOClient(ioc);

    final response = await httpClient.post(apiUrl, body: body, headers: headers);

    // http.Response response = await http.post(apiUrl, body: body, headers: headers);

    print(utf8.decode(response.bodyBytes));
    var data = json.decode(utf8.decode(response.bodyBytes));

    print("LOGIN DATA : $data");
    if (data['status'] == '1') {
      print(data['data']['user_id']);
      print(data['data']['customer_email']);
      setState(() {
        username = data['data']['email_id'];
        if (data['customer_id'] == "" || data['customer_id'] == null) {
          user_id = data['data']['user_id'];
          custid = "0";
          msg = data['message'];
          username = data['data']['email_id'];
        } else {
          custid = data['customer_id'];
          user_id = data['data']['user_id'];
          msg = data['message'];
          username = data['data']['email_id'];
        }
      });
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setString('result', 'true');
      await sharedPreferences.setString('username', username);
      await sharedPreferences.setString('serialNo', serialno);
      await sharedPreferences.setString('userid', user_id);
      await sharedPreferences.setString('custid', custid);
      return true;
    } else {
      setState(() {
        msg = data['message'];
      });
      return false;
    }
  }
}
