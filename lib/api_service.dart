import 'dart:convert';
import 'dart:io';

import 'package:dgplay/constants/api_constants.dart';
import 'package:dgplay/play_list_new_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  authCodeLogin(BuildContext context, SharedPreferences prefs, String code, String serialNo) async {
    http.Response response = await http.post(Uri.parse("$base_url/AuthCode/mobile"),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'code': code,
          'serial_no': serialNo,
        }));
    if (response.statusCode == 200 || response.statusCode == 201) {
      var data = json.decode(utf8.decode(response.bodyBytes));
      if (data["status"] == "1") {
        String customer_id = data["customer_id"] ?? "";
        String user_id = data["user_id"] ?? "";
        String screen_id = data["screen_id"] ?? "";
        print(data);
        // prefs

        prefs.setString("serialNo", serialNo);
        prefs.setString("screenid", screen_id);
        prefs.setString("custid", customer_id);
        prefs.setString("userid", user_id);
        prefs.setString("result", "true");

        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => PlayList(
                      prefs: prefs,
                      serialno: serialNo,
                      custid: customer_id,
                      userid: user_id,
                      screenid: screen_id,
                      username: "",
                    )),
            (route) => false,
          );
        }
      }
    }
  }

  getPlayList(SharedPreferences pref, String serialno, String screenid, String custid, String userid) async {
    List<dynamic> data = [];
    try {
      http.Response response = await http.post(Uri.parse("$base_url/getPlaylist"), headers: {
        'content-type': 'application/x-www-form-urlencoded',
      }, body: {
        'serial_no': serialno,
        'screen_id': screenid,
        'customer_id': custid,
        'user_id': userid,
      });
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        data.clear();
        data.addAll(responseData["data"]);
        pref.setString("apiData", jsonEncode(responseData["data"]));
        return data;
      }
    } catch (e) {
      print("error: ${e.toString()}");
    }
    data.clear();
    String apiData = pref.getString("apiData") ?? "";
    if (apiData.isNotEmpty) {
      data.addAll(jsonDecode(apiData));
    }
    return data;
  }

  updateCountServer(body, key, SharedPreferences prefs) async {
    var apiUrl = Uri.parse('$base_url/setDeviceReport');
    Map<String, String> headers = {
      'content-type': 'application/x-www-form-urlencoded',
    };

    // http.Response response = await http.post(apiUrl, body: body, headers: headers);
    final ioc = HttpClient();
    ioc.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    final httpClient = IOClient(ioc);

    final response = await httpClient.post(apiUrl, body: body, headers: headers);

    if (response.statusCode == 200 || response.statusCode == 201) {
      var data = json.decode(utf8.decode(response.bodyBytes));
      if (data["status"] == "1") {
        prefs.remove(key);
      }
    }
  }

  checkForcedUpdate(body, SharedPreferences prefs, String serialno, String screenid, String custid, String userid) async {
    var apiUrl = Uri.parse('$base_url/checkForcedUpdate');
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
        return true;
      }
    }
    return false;
  }
}
