import 'dart:async';

// import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:dgplay/functions.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

extension ParseToString on ConnectivityResult {
  String toValue() {
    return toString().split('.').last;
  }
}

class ConnectivityStatusExample extends StatefulWidget {
  const ConnectivityStatusExample({super.key});

  @override
  State<StatefulWidget> createState() {
    return _ConnectivityStatusExampleState();
  }
}

class _ConnectivityStatusExampleState extends State<ConnectivityStatusExample> {

  @override
  initState() {
    super.initState();
    checkInternetConnection();
  }


  Future<bool> checkInternetConnection() async {
    try {
      var response = await http.get(Uri.parse('https://google.com'));
      if (response.statusCode == 200) {
        if(mounted) {
          showSnack(context, "Device Registered Successfully");
        }

        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }


  // Future<bool> isInternet() async {
  //   var connectivityResult = await (Connectivity().checkConnectivity());
  //   if (connectivityResult == ConnectivityResult.wifi || connectivityResult == ConnectivityResult.ethernet || connectivityResult == ConnectivityResult.mobile) {
  //     if (true) {
  //       if(mounted) {
  //         showSnack(context, "Device Registered Successfully");
  //       }
  //       return true;
  //     }
  //   } else {
  //     // Neither mobile data or WIFI detected, not internet connection found.
  //     return false;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Internet'),
        backgroundColor: Colors.teal,
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              child: const Text('Check internet connection'),
              onPressed: () => checkInternetConnection(),
            ),
          ],
        ),
      ),
    );
  }
}
