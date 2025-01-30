import 'dart:io';

import 'package:dgplay/login_page.dart';
import 'package:dgplay/play_list_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  String checklogin = sharedPreferences.getString("result")??"";
  String userid = sharedPreferences.getString('userid')??"";
  String custid = sharedPreferences.getString('custid')??"";
  String serialno = sharedPreferences.getString('serialno')??"";
  String screenid = sharedPreferences.getString('screenid')??"";
  HttpOverrides.global = MyHttpOverrides();

  // runApp(MainPage());
  runApp(MainPage(
    checkLogin: checklogin,
    custid: custid,
    userid: userid,
    serialno: serialno,
    screenid: screenid,
  ));
}

class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}


class MainPage extends StatelessWidget {
  final String checkLogin, custid, userid, serialno, screenid;

  const MainPage(
      {Key? key,
      required this.checkLogin,
      required this.userid,
      required this.custid,
      required this.serialno,
      required this.screenid})
      : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    print(checkLogin);
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.accept): const ActivateIntent(),
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Brand-M',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: /*SplashApp()*/ /* VideoPlayerApp()*/ /*ScreenSelectionPage(
              user_id: '2', customer_id: '1', serialno: '1234')*/
            checkLogin != "true"
                ? const LoginPage()
                : PlayListPage(
                    username: "",
                    screenid: screenid,
                    serialno: serialno,
                    custid: custid,
                    userid: userid),
      ),
    );
  }
}
