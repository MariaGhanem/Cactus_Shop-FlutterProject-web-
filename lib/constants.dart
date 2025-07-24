import 'package:flutter/material.dart';

const kBrownColor = Color(0xFF241e1d);

const kButtonStyle = TextStyle(
    color: Color(0xFF69534c),
    fontSize: 30,
    fontWeight: FontWeight.bold,
    fontFamily: 'PlaypenSansArabic');

const kAppBarStyle = TextStyle(
    color: kBrownColor,
    fontSize: 25,
    fontWeight: FontWeight.bold,
    fontFamily: 'PlaypenSansArabic');

const kHeadingOne = TextStyle(
    color: kBrownColor,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontFamily: 'PlaypenSansArabic');

const kHeadingTwo = TextStyle(
    color: kBrownColor,
    fontSize: 10,
    fontWeight: FontWeight.bold,
    fontFamily: 'PlaypenSansArabic');

const kHeading = TextStyle(
    color: Color(0xFF69534c),
    fontSize: 15,
    fontWeight: FontWeight.bold,
    fontFamily: 'Pacifico');

final kOutlinedButton= OutlinedButton.styleFrom(
  side: const BorderSide(color: Colors.white, width: 2),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(30),
  ),
  padding: const EdgeInsets.symmetric(
      horizontal: 22, vertical: 5),
);