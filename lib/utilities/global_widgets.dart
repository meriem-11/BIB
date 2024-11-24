import 'package:flutter/material.dart';

class GlobalWidgets {
  BuildContext context;
  GlobalWidgets (this.context);
  void showSnackBar({required String content ,Color?backgroundColor}){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(content ,textAlign: TextAlign.center,),
      duration: const Duration(seconds: 2),
      backgroundColor: backgroundColor ?? Colors.black,
      ),
    );
  }
}