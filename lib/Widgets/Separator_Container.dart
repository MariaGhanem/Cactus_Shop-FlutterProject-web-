import 'package:cactus_shop/constants.dart';
import 'package:flutter/material.dart';
class SeparatorContainer extends StatelessWidget {
  String text;

  SeparatorContainer({
    required String this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: double.infinity,
      color:  Color(0xFFf0eae4),
      child:  Center(
        child: Text(
          '$text',
          style: kHeadingOne,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}