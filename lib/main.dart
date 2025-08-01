import 'package:cactus_shop/AdminPages/OrdersPage.dart';
import 'package:cactus_shop/screens/SignIn_Screen.dart';
import 'package:cactus_shop/screens/SignUp_page.dart';
import 'package:provider/provider.dart';
import 'package:cactus_shop/firebase_options.dart';
import 'package:cactus_shop/screens/DeliveryPage.dart';
import 'package:cactus_shop/screens/InformationPage.dart';
import 'package:cactus_shop/screens/ProfilePage.dart';
import 'package:cactus_shop/screens/Welcome_Page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cactus_shop/helper/CartProvider.dart';
import 'package:cactus_shop/screens/Home_Page.dart';
import 'package:cactus_shop/screens/CartPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'AdminPages/editWelcomePage.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // عرض شاشة تحميل أولية
//   runApp(
//       const MaterialApp(
//         home: Scaffold(
//           body: Center(
//             child: CircularProgressIndicator(),
//           ),
//         ),
//         debugShowCheckedModeBanner: false,
//       )
//   );
//
//   // تهيئة Firebase مرة واحدة فقط
//   try {
//     if (Firebase.apps.isEmpty) {
//       await Firebase.initializeApp(
//         name: 'cactus_shop',
//         options: DefaultFirebaseOptions.currentPlatform,
//       );
//     }
//     await SharedPreferences.getInstance();
//   } catch (e) {
//     debugPrint('Firebase initialization error: $e');
//   }
//
//   // تشغيل التطبيق الرئيسي
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => CartProvider()),
//       ],
//       child: const MyApp(),
//     ),
//   );
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<bool>(
//       future: _initializeApp(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const MaterialApp(
//             home: Scaffold(
//               body: Center(
//                 child: CircularProgressIndicator(),
//               ),
//             ),
//             debugShowCheckedModeBanner: false,
//           );
//         }
//
//         return MaterialApp(
//           supportedLocales: const [Locale('ar')],
//           localizationsDelegates: const [
//             GlobalMaterialLocalizations.delegate,
//             GlobalWidgetsLocalizations.delegate,
//             GlobalCupertinoLocalizations.delegate,
//           ],
//           locale: const Locale('ar'),
//           title: 'Cactus Shop',
//           theme: ThemeData(primarySwatch: Colors.brown),
//           debugShowCheckedModeBanner: false,
//           home: HomePage(),
//           routes: {
//             '/information': (context) => const AboutUsPage(),
//             '/delivery': (context) => const Delivery(),
//             '/welcome': (context) => const WelcomePage(),
//             '/cart': (context) => const Cart(),
//             '/profile': (context) => const Profile(),
//             '/orders': (context) => const OrdersPage(),
//             '/editWelcomeBanner': (context) => const EditWelcomeBannerPage(),
//             '/signInScreen': (context) => const SignInScreen(),
//             '/signUpScreen': (context) => const SignUpScreen(),
//           },
//         );
//       },
//     );
//   }
//
//   Future<bool> _initializeApp() async {
//     try {
//       // انتظار أي عمليات تهيئة إضافية هنا إذا لزم الأمر
//       await Future.delayed(const Duration(milliseconds: 300)); // وقت محاكاة للتحميل
//       return true;
//     } catch (e) {
//       debugPrint('App initialization error: $e');
//       return false;
//     }
//   }
// }


// //web

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // شغل شاشة تحميل أولاً
  runApp(const LoadingApp());

  // ثم هيئ Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ثم شغل التطبيق الرئيسي بعد التهيئة
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current user (null if not logged in)
 // i delete this
 //    User? currentUser = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      locale: const Locale('ar'), // يمكنك لاحقًا جعله ديناميكيًا
      supportedLocales: const [
        Locale('ar'), // العربية
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      title: 'Cactus Shop',
      theme: ThemeData(primarySwatch: Colors.brown),
      debugShowCheckedModeBanner: false,
      home: HomePage(),
      routes: {
        '/information': (context) => AboutUsPage(),
        '/delivery': (context) => Delivery(),
        '/welcome': (context) => WelcomePage(),
        '/cart': (context) => Cart(),
        '/profile': (context) => Profile(),
        '/orders': (context) => OrdersPage(),
        '/editWelcomeBanner': (context) => EditWelcomeBannerPage(),
        '/signInScreen': (context) => SignInScreen(),
        '/signUpScreen': (context) => const SignUpScreen(),
      },
    );
  }
}

class LoadingApp extends StatelessWidget {
  const LoadingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white, // أو أي لون يناسبك
        body: Center(
          child: CircularProgressIndicator(color: Colors.brown), // لون التطبيق
        ),
      ),
    );
  }
}

