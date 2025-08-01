import 'package:cactus_shop/Widgets/MyButton.dart';
import 'package:cactus_shop/Widgets/MySafeScaffold.dart';
import 'package:cactus_shop/Widgets/TextField.dart';
import 'package:cactus_shop/constants.dart';
import 'package:cactus_shop/Widgets/ShowSnackBar.dart';
import 'package:cactus_shop/helper/showLoadingDialog.dart';
import 'package:cactus_shop/services/forgot_pass.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    showLoadingDialog(context);

    String res = await AuthMethod().SignInUser(
      email: emailController.text,
      password: passwordController.text,
      context: context,
    );

    hideLoadingDialog(context);

    if (res == "تم تسجيل الدخول بنجاح") {
      saveUserCredentials();
      Navigator.of(context).pushReplacementNamed("/welcome");
    } else {
      showSnackBar(context, res);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isPortrait = mediaQuery.orientation == Orientation.portrait;

    // حجم الخط للعنوان: بين 18 و 28 (مثلاً)
    double baseTitleSize = isPortrait ? screenWidth * 0.08 : screenHeight * 0.08;
    double titleFontSize = baseTitleSize.clamp(18, 28);

    // حجم الخط للعناوين الفرعية: بين 14 و 20
    double baseSubtitleSize = isPortrait ? screenWidth * 0.045 : screenHeight * 0.045;
    double subtitleFontSize = baseSubtitleSize.clamp(14, 20);

    // حجم خط النصوص الثانوية: بين 12 و 18
    double baseTextSize = isPortrait ? screenWidth * 0.04 : screenHeight * 0.04;
    double textFontSize = baseTextSize.clamp(12, 18);

    // عرض الحاوية يتغير حسب الاتجاه
    double containerWidth = isPortrait ? screenWidth * 0.9 : screenWidth * 0.6;

    return MySafeScaffold(
      backgroundColor: kBrownColor,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: containerWidth,
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.04,
              horizontal: screenWidth * 0.05,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'مرحبًا بعودتك',
                  style: kButtonStyle.copyWith(
                    fontSize: titleFontSize,
                    color: kBrownColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  'قم بتسجيل الدخول للمتابعة',
                  style: kHeadingTwo.copyWith(
                    fontSize: subtitleFontSize,
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
                                fontSize: textFontSize,
                              ),
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
                SizedBox(height: screenHeight * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      "لا تمتلك حساب؟",
                      style: TextStyle(fontSize: textFontSize, color: Colors.black87),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/signUpScreen');
                      },
                      child: Text(
                        "أنشئ حسابك الآن",
                        style: TextStyle(
                          fontSize: textFontSize,
                          color: const Color(0xFFe8dccb),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
