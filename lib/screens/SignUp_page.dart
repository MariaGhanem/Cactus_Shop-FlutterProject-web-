import 'package:cactus_shop/Widgets/MyButton.dart';
import 'package:cactus_shop/Widgets/MySafeScaffold.dart';
import 'package:cactus_shop/Widgets/ShowSnackBar.dart';

import 'package:cactus_shop/Widgets/TextField.dart';
import 'package:cactus_shop/constants.dart';
import 'package:cactus_shop/services/authentication.dart';
import 'package:flutter/material.dart';

import '../helper/showLoadingDialog.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
  }

  void signupUser() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      showSnackBar(context, 'يرجى تعبئة جميع الحقول');
      return;
    }
    showLoadingDialog(context);
    String res = await AuthMethod().signupUser(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
    );
    hideLoadingDialog(context);

    if (res == "تم اضافة الحساب بنجاح") {
      Navigator.of(context).pushReplacementNamed('/welcome');
    } else {
      showSnackBar(context, res);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MySafeScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/logo.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SingleChildScrollView(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 30,
                      color: kBrownColor
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'إنشاء حساب جديد',
                      style: kButtonStyle.copyWith(
                        color: kBrownColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Row(
                      textDirection: TextDirection.rtl,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'لديك حساب بالفعل؟',
                          style: kHeadingTwo.copyWith(
                            fontSize: 18,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/signInScreen');
                          },
                          child: Text(
                            'تسجيل الدخول',
                            style: kHeadingTwo.copyWith(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    TextFieldInput(
                      textEditingController: nameController,
                      hintText: "اسم المستخدم",
                    ),
                    TextFieldInput(
                      textEditingController: emailController,
                      hintText: "البريد الإلكتروني",
                    ),
                    TextFieldInput(
                      textEditingController: phoneController,
                      hintText: "رقم الهاتف",
                    ),
                    TextFieldInput(
                      textEditingController: passwordController,
                      hintText: "كلمة السر",
                      isPass: true, // Enables password toggle feature
                    ),
                    SizedBox(height: 20),
                    MyButton(text: "إنشاء حساب", onPress: signupUser)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
