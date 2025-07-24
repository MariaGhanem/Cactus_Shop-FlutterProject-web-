import 'package:cactus_shop/constants.dart';
import 'package:flutter/material.dart';

showSnackBar(BuildContext context, String text) {
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: kBrownColor,

    ),
  );
}
