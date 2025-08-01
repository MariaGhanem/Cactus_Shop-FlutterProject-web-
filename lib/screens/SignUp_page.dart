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
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height > size.width;

    return MySafeScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SizedBox(
            height: size.height,
            width: size.width,
            child: Image.asset(
              isPortrait ? 'images/logo.jpeg' : 'images/logo3.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // الوضع الطولي: نستخدم Column ونضع الكونتينر في الأسفل
          if (isPortrait)
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SingleChildScrollView(
                  child: _buildContainer(size, isPortrait),
                ),
              ],
            ),

          // الوضع العرضي: نستخدم Center لوضع الكونتينر في منتصف الشاشة
          if (!isPortrait)
            Center(
              child: SingleChildScrollView(
                child: _buildContainer(size, isPortrait),
              ),
            ),
        ],
      ),
    );
  }

// دالة تبني الكونتينر بحيث لا يتكرر الكود
  Widget _buildContainer(Size size, bool isPortrait) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPortrait ? 30 : size.width * 0.15,
        vertical: isPortrait ? 25 : size.height * 0.05,
      ),
      margin: EdgeInsets.only(
        bottom: isPortrait ? 0 : size.height * 0.05,
        left: isPortrait ? 0 : size.width * 0.1,
        right: isPortrait ? 0 : size.width * 0.1,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:  BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
          bottomLeft: isPortrait ? Radius.circular(0): Radius.circular(40),
          bottomRight: isPortrait ? Radius.circular(0): Radius.circular(40),

        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 30,
            color: kBrownColor,
          ),
        ],
      ),
      width: isPortrait ? double.infinity : size.width * 0.7,
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
          const SizedBox(height: 15),
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
            isPass: true,
          ),
          const SizedBox(height: 20),
          MyButton(text: "إنشاء حساب", onPress: signupUser),
        ],
      ),
    );
  }


}
