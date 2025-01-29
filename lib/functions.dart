import 'package:flutter/material.dart';

showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green, duration: const Duration(seconds: 5),));
}
