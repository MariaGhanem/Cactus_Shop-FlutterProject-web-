import 'package:cactus_shop/constants.dart';
import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  MyButton({required VoidCallback this.onPress, required String this.text});
  VoidCallback onPress;
  String text;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPress,
      child: Text(
        '$text',
        style: kButtonStyle,
      ),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(
          Color(0xFFe8dccb),
        ),
        shadowColor: MaterialStateProperty.all(
          Color(0xFF69534c),
        ),
        elevation: MaterialStateProperty.all(9),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        padding: MaterialStateProperty.all(
          EdgeInsets.symmetric(horizontal: 32, vertical: 6),
        ),
      ),
    );
  }
}
