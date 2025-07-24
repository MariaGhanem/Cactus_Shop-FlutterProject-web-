import 'package:cactus_shop/constants.dart';
import 'package:flutter/material.dart';

class ImageDisplay extends StatelessWidget {
  final String text;
  final ImageProvider imageProvider;
  final VoidCallback onTap;

  ImageDisplay({
    required this.text,
    required this.imageProvider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Expanded(
              child: SizedBox(
                height: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(text, style: kHeadingTwo),
            ),
          ],
        ),
      ),
    );
  }
}
