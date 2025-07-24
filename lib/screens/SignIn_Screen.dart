import 'package:cactus_shop/Widgets/MyButton.dart';
import 'package:cactus_shop/Widgets/MySafeScaffold.dart';
import 'package:cactus_shop/Widgets/TextField.dart';
import 'package:cactus_shop/constants.dart';
import 'package:cactus_shop/Widgets/ShowSnackBar.dart';
import 'package:cactus_shop/helper/showLoadingDialog.dart';
import 'package:cactus_shop/screens/SignUp_page.dart';
import 'package:cactus_shop/screens/Welcome_Page.dart';
import 'package:cactus_shop/services/forgot_pass.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/CartProvider.dart';
import '../services/FetchUserData.dart';
import '../services/authentication.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isChecked = false; // Remember Me checkbox state

  @override
  void initState() {
    super.initState();
    loadUserCredentials();
  }

  // Load saved credentials
  void loadUserCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      emailController.text = prefs.getString('email') ?? '';
      passwordController.text = prefs.getString('password') ?? '';
      isChecked = prefs.getBool('rememberMe') ?? false;

    });
  }

  // Save credentials if Remember Me is checked
  void saveUserCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (isChecked) {
      await prefs.setString('email', emailController.text);
      await prefs.setString('password', passwordController.text);
      await prefs.setBool('rememberMe', true);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('rememberMe', false);
    }
  }

  // Sign-In Function
  void SignInUser() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      showSnackBar(context, "يرجى تعبئة جميع الحقول");
      return;
    }

    showLoadingDialog(context); // ✅ أضف هذا السطر هنا قبل بدء العملية

    String res = await AuthMethod().SignInUser(
      email: emailController.text,
      password: passwordController.text,
      context: context,
    );

    hideLoadingDialog(context); // ✅ يغلق Dialog بعد إتمام العملية

    if (res == "تم تسجيل الدخول بنجاح") {
      saveUserCredentials();
        Navigator.of(context).pushReplacementNamed("/welcome");
    } else {
      showSnackBar(context, res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return MySafeScaffold(
      backgroundColor: kBrownColor,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: kBrownColor,
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.05),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.15),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.05,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(40)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'مرحبًا بعودتك',
                      style: kButtonStyle.copyWith(
                        fontSize: screenWidth * 0.08,
                        color: kBrownColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'قم بتسجيل الدخول للمتابعة',
                      style: kHeadingTwo.copyWith(
                        fontSize: screenWidth * 0.04,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    TextFieldInput(
                      textEditingController: emailController,
                      hintText: "البريد الإلكتروني",
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextFieldInput(
                      textEditingController: passwordController,
                      hintText: "كلمة السر",
                      isPass: true,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Row(
                      textDirection: TextDirection.rtl,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              Checkbox(
                                value: isChecked,
                                onChanged: (value) {
                                  setState(() {
                                    isChecked = value!;
                                  });
                                },
                              ),
                              Flexible(
                                child: Text(
                                  'تذكرني',
                                  style: kHeadingTwo.copyWith(
                                      fontSize: screenWidth * 0.05),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const ForgotPassword(),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    MyButton(onPress: SignInUser, text: "تسجيل الدخول"),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: TextDirection.rtl,
                children: [
                  Text(
                    "لا تمتلك حساب؟",
                    style: TextStyle(
                        fontSize: screenWidth * 0.05, color: Colors.white),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/signUpScreen');
                    },
                    child: Text(
                      "أنشئ حسابك الآن",
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        color: Color(0xFFe8dccb),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
