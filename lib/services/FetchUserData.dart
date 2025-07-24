import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserType {
  guest,
  user,
  admin,
}

class UserRoleResult {
  final UserType userType;
  final String? userName;

  UserRoleResult({required this.userType, this.userName});
}

class UserDataService {
  static User? get currentUser => FirebaseAuth.instance.currentUser;

  static String? get uid => currentUser?.uid;

  static String? get email => currentUser?.email;

  /// 🔹 اسم افتراضي من الإيميل
  static String? get defaultName => email?.split('@')[0];

  /// 🔹 جلب الاسم من قاعدة البيانات أو الإيميل
  static Future<String?> fetchUserNameFromFirestore() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final name = userDoc.data()?['name'];
      return name ?? defaultName;
    } catch (e) {
      return defaultName;
    }
  }

  /// 🔹 جلب الاسم الحالي للمستخدم
  static Future<String?> getCurrentUserName() async {
    if (currentUser == null) return null;
    return await fetchUserNameFromFirestore();
  }

  /// 🔹 جلب UID المستخدم الحالي
  static Future<String?> getCurrentUserUid() async {
    return uid;
  }

  /// 🔹 جلب نوع المستخدم (ضيف - مستخدم - أدمن) مع اسمه
  static Future<UserRoleResult> getUserRole() async {
    if (currentUser == null) {
      return UserRoleResult(userType: UserType.guest);
    }

    String userName = await fetchUserNameFromFirestore() ?? '';

    try {
      final adminSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .where('email', isEqualTo: email)
          .get();

      final isAdmin = adminSnapshot.docs.isNotEmpty;

      return UserRoleResult(
        userType: isAdmin ? UserType.admin : UserType.user,
        userName: userName,
      );
    } catch (e) {
      return UserRoleResult(
        userType: UserType.user,
        userName: userName,
      );
    }
  }
}
