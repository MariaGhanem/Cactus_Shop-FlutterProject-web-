import 'package:flutter/material.dart';

void showLoadingDialog(BuildContext context) {
  showDialog(
    barrierDismissible: false, // user can't tap outside to dismiss
    context: context,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );
}

void hideLoadingDialog(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop(); // close dialog
}
