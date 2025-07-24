import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';
import '../services/FetchUserData.dart';

class CustomBottomNavBar extends StatefulWidget {
  const CustomBottomNavBar({super.key});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  bool isAdmin = false;
  int unreadOrders = 0;

  @override
  void initState() {
    super.initState();
    checkIfAdmin();
  }

  Future<void> checkIfAdmin() async {
    final userRoll = await UserDataService.getUserRole();
    if (userRoll.userType == UserType.guest)
      return;
    else if (userRoll.userType == UserType.admin) {
      print(userRoll.userType);
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('opened', isEqualTo: false)
          .get();

      setState(() {
        isAdmin = true;
        unreadOrders = ordersSnapshot.docs.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      onTap: (int index) {
        if (index == 0) {
          Navigator.pushNamed(context, '/information');
        } else if (index == 1) {
          Navigator.pushNamed(context, '/delivery');
        } else if (index == 2) {
          Navigator.pushNamed(context, '/welcome');
        } else if (index == 3) {
          Navigator.pushNamed(context, '/cart');
        } else if (index == 4) {
          Navigator.pushNamed(context, '/profile');
        } else if (index == 5 && isAdmin) {
          Navigator.pushNamed(context, '/orders');
        }
      },
      backgroundColor: Colors.brown[50],
      type: BottomNavigationBarType.fixed,
      items: [
        buildBottomNavigationBarItem(label: '', icon: Icons.info),
        BottomNavigationBarItem(
          label: '',
          icon: FaIcon(
            FontAwesomeIcons.truckFast,
            color: kBrownColor,
            size: 30,
          ),
        ),
        buildBottomNavigationBarItem(label: '', icon: Icons.home),
        buildBottomNavigationBarItem(
            label: '', icon: Icons.shopping_cart_sharp),
        buildBottomNavigationBarItem(label: '', icon: Icons.person),
        if (isAdmin)
          BottomNavigationBarItem(
            label: '',
            icon: Stack(
              alignment: Alignment.topRight,
              children: [
                const Icon(Icons.notifications, size: 30, color: kBrownColor),
                if (unreadOrders > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  BottomNavigationBarItem buildBottomNavigationBarItem(
          {required String label, required IconData icon}) =>
      BottomNavigationBarItem(
        label: label,
        icon: Icon(
          icon,
          color: kBrownColor,
          size: 30,
        ),
      );
}
