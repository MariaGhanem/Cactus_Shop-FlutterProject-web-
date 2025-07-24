import 'package:cactus_shop/constants.dart';
import 'package:cactus_shop/helper/BottomNavigationBar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class Delivery extends StatelessWidget {
  const Delivery({super.key});

  void _launchInstagram() async {
    const url = 'https://www.instagram.com/cactus.shop.ps2?utm_source=ig_web_button_share_sheet&igsh=ZDNlZDc0MzIxNw==';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'تعذر فتح الرابط';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              "images/delivary.jpg",
              fit: BoxFit.cover,
            ),
          ),

          // Dark overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),

          // Centered card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                ),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'خدمة التوصيل',
                      style: kHeadingOne.copyWith(
                        fontSize: 38,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'خدمة التوصيل متوفرة للمناطق التالية:',
                      style: kHeadingTwo.copyWith(
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'الضفة: 20 شيكل\nالقدس: 30 شيكل\nالداخل المحتل: 70 شيكل',
                      style: const TextStyle(
                        fontSize: 18,
                        color: kBrownColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const Divider(
                      color: Color(0x88FFFFFF),
                      thickness: 1.2,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'بعد اختيار منتجاتك، انتقلي إلى السلة لإتمام الطلب.\nالدفع عند الاستلام.',
                      style: kHeadingOne.copyWith(
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    Text(
                      "للمزيد من المعلومات تواصل معنا عبر الحساب التالي:",
                      style: kHeadingOne.copyWith(
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    InkWell(
                      onTap: _launchInstagram,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(FontAwesomeIcons.instagram, color: kBrownColor, size: 24),
                          SizedBox(width: 8),
                          Text(
                            "@cactus.shop.ps2",
                            style: TextStyle(
                              fontSize: 18,
                              color: kBrownColor,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}
