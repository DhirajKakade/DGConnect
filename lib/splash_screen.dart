
import 'package:flutter/material.dart';

class SplashApp extends StatefulWidget {
  @override
  _SplashAppState createState() => _SplashAppState();
}

class _SplashAppState extends State<SplashApp> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // ToastContext().init(context);
  }

  @override
  Widget build(BuildContext context) {
    print("SPLASH SCREEN : ----------");
    return const Scaffold();

    //   SplashScreen(
    //   seconds: 5,
    //   navigateAfterSeconds: LoginPage(),
    //   title: const Text(
    //     'Powered By Unitglo',
    //     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
    //   ),
    //   image: Image.asset("assets/unitglo.png"),
    //   backgroundColor: Colors.white,
    //   styleTextUnderTheLoader: const TextStyle(),
    //   photoSize: 100.0,
    //   onClick: () => print("Flutter Egypt"),
    //   loaderColor: Colors.red,
    // );
  }
}
