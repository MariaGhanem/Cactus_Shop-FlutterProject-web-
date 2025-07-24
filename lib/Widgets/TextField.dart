import 'package:cactus_shop/screens/InformationPage.dart';
import 'package:flutter/material.dart';

class TextFieldInput extends StatefulWidget {
  final TextEditingController textEditingController;
  final String hintText;
  final bool isPass;

  const TextFieldInput({
    Key? key,
    required this.textEditingController,
    this.isPass = false,
    required this.hintText,
  }) : super(key: key);

  @override
  State<TextFieldInput> createState() => _TextFieldInputState();
}

class _TextFieldInputState extends State<TextFieldInput> {
  bool _isObscured = true; // State variable for password visibility

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      child: TextField(textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 20),
        controller: widget.textEditingController,
        obscureText: widget.isPass ? _isObscured : false, // Obscure text only for password fields
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: Colors.black45, fontSize: 18),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(10),
          ),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: kBrownColor, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey.shade200,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 20,
          ),
          prefixIcon: widget.isPass // Show suffix icon only for password fields
              ? GestureDetector(
            onTap: () {
              setState(() {
                _isObscured = !_isObscured; // Toggle state on tap
              });
            },
            child: Icon(
              _isObscured ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
          )
              : null, // No icon for non-password fields
        ),
      ),
    );
  }
}




