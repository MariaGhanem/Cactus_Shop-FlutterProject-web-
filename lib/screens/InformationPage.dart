import 'package:cactus_shop/constants.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../helper/BottomNavigationBar.dart';

const kBrownColor = Color(0xFF6B4226);

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  final List<Map<String, String>> coreValues = [
    {'title': 'الجودة', 'description': 'نلتزم بأعلى معايير الجودة في جميع منتجاتنا وخدماتنا.'},
    {'title': 'الاستدامة', 'description': 'نلتزم بممارسات تحافظ على البيئة وتخدم الأجيال القادمة.'},
    {'title': 'الابتكار المحلي', 'description': 'نفخر بأن جميع منتجاتنا تُصنع بأيادٍ فلسطينية محترفة..'},
  ];

  final List<Map<String, String>> journey = [
    {'year': '2016', 'event': 'انطلاقة المشروع كفكرة بسيطة مع منتج من الألوفيرا وزبدة الشيا.'},
    {'year': '2017', 'event': 'تم التوسيع إلى زيت الرموش وزيادة المنتجات مع تسليم شخصي في مدن الضفة'},
    {'year': '2018', 'event': 'إضافة مجموعة جديدة من المنتجات و افتتاح أول محل خاص واستقبال الزبائن مباشرة. '},
    {'year': '2023', 'event': 'إغلاق المحل والتركيز على التوصيل مع الحفاظ على الجودة والخدمة'},
    {'year': 'اليوم', 'event': 'أكثر من 30 منتج طبيعي للعناية بالبشرة والشعر مع توصيل فوري'},
  ];

  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(
          'من نحن',
          style: GoogleFonts.tajawal(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white
          ),
        ),
        ),
        backgroundColor: const Color(0xFFFAF6F0),
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.45,
                child: Image.asset('images/background.jpg', fit: BoxFit.cover),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'من شغف صغير إلى حلم كبير',
                               style: kHeadingOne.copyWith(color: Colors.brown),
                              // GoogleFonts.tajawal(
                              //   fontSize: 22,
                              //   fontWeight: FontWeight.bold,
                              //   color: kBrownColor,
                              // ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'بدأت رحلتنا قبل أكثر من 7 سنوات بشغف تحوّل إلى مشروع يقدم أفضل منتجات العناية الطبيعية.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.tajawal(fontSize: 16, height: 1.6, color: kBrownColor),
                            ),
                            const SizedBox(height: 20),
                            Text(
                                  'نؤمن أن الطبيعة هي المصدر الحقيقي للجمال والصحة. بدأنا رحلتنا لتقديم منتجات طبيعية وعضوية للعناية بالبشرة والجسم مصنوعة بأيدي فلسطينية، ونحرص على اختيار أفضل المكونات من قلب الطبيعة. رؤيتنا أن نصبح الخيار الأول لكل من يبحث عن جودة وصدق وفعالية.',
                                  style:kHeadingTwo,
                                  //GoogleFonts.tajawal(fontSize: 16, height: 1.8, color: Colors.brown[800]),
                                  textAlign: TextAlign.center,

                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: Text(
                          'قيمنا الأساسية',
                          style: GoogleFonts.tajawal(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: kBrownColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 250,
                        child: PageView.builder(
                          itemCount: coreValues.length,
                          controller: PageController(viewportFraction: 0.85),
                          onPageChanged: (index) {
                            setState(() => currentPage = index);
                          },
                          itemBuilder: (context, index) {
                            final item = coreValues[index];
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: EdgeInsets.symmetric(horizontal: 10, vertical: currentPage == index ? 0 : 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item['title']!,
                                    style: GoogleFonts.tajawal(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: kBrownColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    item['description']!,
                                    style: GoogleFonts.tajawal(fontSize: 16, height: 1.6),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: Text(
                          'رحلتنا',
                          style: GoogleFonts.tajawal(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: kBrownColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...journey.map((item) => _buildTimelineItem(item)).toList(),
                      const SizedBox(height: 30),
                      _buildContactSection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavBar(),
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, String> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(width: 16, height: 16, decoration: const BoxDecoration(shape: BoxShape.circle, color: kBrownColor)),
              Container(width: 2, height: 60, color: kBrownColor),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['year']!, style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold, color: kBrownColor)),
                const SizedBox(height: 6),
                Text(item['event']!, style: GoogleFonts.tajawal(fontSize: 16, height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Divider(height: 30),
        Text(
          'تواصلوا معنا',
          style: GoogleFonts.tajawal(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: kBrownColor,
          ),
        ),
        const SizedBox(height: 15),
        _buildContactRow(Icons.phone, '+970 59 228 9849'),
        _buildContactRow(Icons.location_on, 'فلسطين - جنين'),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(FontAwesomeIcons.instagram, 'https://www.instagram.com/cactus.shop.ps2?utm_source=ig_web_button_share_sheet&igsh=ZDNlZDc0MzIxNw=='),
            const SizedBox(width: 15),
            _buildSocialIcon(FontAwesomeIcons.whatsapp, 'https://api.whatsapp.com/message/6FIZHRUPNYXBD1?autoload=1&app_absent=0'),
            const SizedBox(width: 15),
            _buildSocialIcon(FontAwesomeIcons.facebook, 'https://www.facebook.com/profile.php?id=100054224901024'),
          ],
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String info) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: kBrownColor),
          const SizedBox(width: 10),
          Text(info, style: GoogleFonts.tajawal(fontSize: 16, color: Colors.brown)),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String url) {
    return InkWell(
      onTap: () async {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        }
      },
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.brown[50],
        child: FaIcon(icon, size: 20, color: Colors.brown),
      ),
    );
  }
}
