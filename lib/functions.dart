import 'package:dgplay/screen_selection_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: Colors.green,
    duration: const Duration(seconds: 5),
  ));
}

onScreenSelection(BuildContext context, SharedPreferences prefs, String serialno, String userid, String custid, String username) {
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
              await prefs.remove("screenid");
              await prefs.remove("apidata");
              await prefs.remove("apiData");

              DefaultCacheManager manager = DefaultCacheManager();
              manager.emptyCache();

              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => ScreenSelectionPage(
                        serialno: serialno,
                        user_id: userid,
                        customer_id: custid, /* user_name: widget.username,*/
                      ),
                    ),
                    (route) => false);
              }
            },
            child: const Text("YES"),
          ),
        ],
      );
    },
  );
}
