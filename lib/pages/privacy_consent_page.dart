import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyConsentPage extends StatefulWidget {
  final VoidCallback onAccepted;
  const PrivacyConsentPage({super.key, required this.onAccepted});

  @override
  State<PrivacyConsentPage> createState() => _PrivacyConsentPageState();
}

class _PrivacyConsentPageState extends State<PrivacyConsentPage> {
  Future<void> _onAccept() async {
    final prefs = await SharedPreferences.getInstance();
    final success1 = await prefs.setBool('is_terms_accepted', true);
    final success2 = await prefs.setString(
      'terms_accepted_date',
      DateTime.now().toIso8601String(),
    );

    if (!mounted) return;

    if (!success1 || !success2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึกข้อมูลไม่สำเร็จ: พื้นที่จัดเก็บเต็ม'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Trigger parent callback to switch UI
    widget.onAccepted();
  }

  void _onDecline() {
    // Close the app
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white.withOpacity(0.9) : Colors.black87;
    final subTextColor = isDark
        ? Colors.white.withOpacity(0.7)
        : Colors.black54;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Header
            const Icon(Icons.shield_outlined, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              "ข้อตกลงและนโยบาย",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "โปรดอ่านและยอมรับก่อนเข้าใช้งาน",
              style: TextStyle(color: subTextColor),
            ),

            // Content
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'เอกสารทางกฎหมาย',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFD4AF37), // Gold
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'นโยบายความเป็นส่วนตัวและข้อกำหนดการใช้งาน',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: subTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'มีผลบังคับใช้ตั้งแต่: 19 มกราคม 2569',
                              style: TextStyle(
                                fontSize: 12,
                                color: subTextColor.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Intro
                      Text(
                        '    เอกสารฉบับนี้จัดทำขึ้นเพื่ออธิบายแนวทางการคุ้มครองข้อมูลส่วนบุคคล และกำหนดเงื่อนไขการใช้งานแอปพลิเคชัน Gold App ("Thai Gold View") ซึ่งพัฒนาและให้บริการโดยผู้พัฒนาแอปพลิเคชัน โปรดอ่านเอกสารฉบับนี้อย่างละเอียดก่อนใช้งาน',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 1. Privacy Policy
                      _buildSectionTitle(
                        '1. นโยบายความเป็นส่วนตัว (Privacy Policy)',
                      ),
                      _buildParagraph(
                        'เราให้ความสำคัญกับความเป็นส่วนตัวของผู้ใช้งาน และดำเนินการตามหลักการคุ้มครองข้อมูลส่วนบุคคลที่สอดคล้องกับกฎหมายที่เกี่ยวข้อง (PDPA)',
                        textColor,
                      ),

                      _buildSubSectionTitle(
                        '1.1 การเก็บรวบรวมและใช้ข้อมูลส่วนบุคคล',
                        textColor,
                      ),
                      _buildParagraph(
                        'แอปพลิเคชัน Thai Gold View **ไม่ได้จัดเก็บข้อมูลบัตรเครดิตหรือข้อมูลทางการเงิน** ของผู้ใช้งานโดยตรง ข้อมูลการชำระเงินทั้งหมดจะถูกดำเนินการผ่านระบบ Secure Payment ของ Apple App Store หรือ Google Play Store\n\nอย่างไรก็ตาม เราอาจตรวจสอบสถานะการเป็นสมาชิก (Subscription Status) ของท่านผ่าน Receipt Validation เพื่อปลดล็อกฟีเจอร์ Premium',
                        textColor,
                      ),
                      _buildBulletPoint(
                        'ไม่มีระบบลงทะเบียนด้วยอีเมลหรือเบอร์โทรศัพท์ (No Email/Phone Register)',
                        textColor,
                      ),
                      _buildBulletPoint(
                        'การระบุตัวตนสมาชิกทำผ่านบัญชี Apple ID หรือ Google Account ของท่านโดยตรง',
                        textColor,
                      ),
                      _buildBulletPoint(
                        'ไม่มีการร้องขอชื่อ นามสกุล หรืออีเมล',
                        textColor,
                      ),
                      _buildBulletPoint(
                        'ไม่มีการติดตามตัวตนของผู้ใช้งาน',
                        textColor,
                      ),

                      _buildSubSectionTitle(
                        '1.2 การจัดเก็บข้อมูลภายในอุปกรณ์',
                        textColor,
                      ),
                      _buildParagraph(
                        'ข้อมูลบางประเภทจะถูกจัดเก็บไว้ภายในอุปกรณ์ของท่านเท่านั้น (Local Storage) เพื่อความสะดวกในการใช้งาน เช่น การตั้งค่าธีมแอป หรือประวัติการคำนวณ โดยข้อมูลเหล่านี้จะไม่ถูกส่งออกภายนอก',
                        textColor,
                      ),

                      _buildSubSectionTitle('1.3 บริการภายนอก', textColor),
                      _buildParagraph(
                        'แอปพลิเคชันเชื่อมต่ออินเทอร์เน็ตเพื่อดึงข้อมูลราคาทองคำจากแหล่งข้อมูลสาธารณะ การใช้งานลิงก์ภายนอกจะอยู่ภายใต้นโยบายของเว็บไซต์นั้นๆ',
                        textColor,
                      ),

                      const SizedBox(height: 24),

                      // 2. Terms of Service
                      _buildSectionTitle('2. ข้อกำหนดและเงื่อนไขการใช้งาน'),

                      _buildSubSectionTitle('2.1 การยอมรับข้อตกลง', textColor),
                      _buildParagraph(
                        'การดาวน์โหลดและใช้งานแอปพลิเคชันถือว่าผู้ใช้ยอมรับข้อกำหนดฉบับนี้แล้ว',
                        textColor,
                      ),

                      _buildSubSectionTitle('2.2 วัตถุประสงค์', textColor),
                      _buildParagraph(
                        'แอปพลิเคชันนี้จัดทำขึ้นเพื่อ **ให้ข้อมูลเท่านั้น (Informational Purposes Only)** เพื่ออำนวยความสะดวกในการตรวจสอบราคาทองคำ',
                        textColor,
                      ),

                      _buildSubSectionTitle(
                        '2.3 การปฏิเสธความรับผิด (Disclaimer)',
                        textColor,
                      ),
                      _buildBulletPoint(
                        '**ความถูกต้อง:** ข้อมูลอาจมีความล่าช้าหรือคลาดเคลื่อน เราไม่รับประกันความถูกต้อง 100%',
                        textColor,
                      ),
                      _buildBulletPoint(
                        '**ไม่ใช่คำแนะนำการลงทุน:** ข้อมูลในแอปไม่ใช่คำแนะนำทางการเงิน ผู้ใช้ควรใช้วิจารณญาณก่อนตัดสินใจ',
                        textColor,
                      ),

                      _buildSubSectionTitle(
                        '2.4 บริการสมาชิก (Premium Service)',
                        textColor,
                      ),
                      _buildBulletPoint(
                        '**การชำระเงิน:** การสมัครสมาชิก Gold Member จะถูกเรียกเก็บเงินผ่านบัญชี Apple ID หรือ Google Play ของท่านเมื่อยืนยันการสั่งซื้อ',
                        textColor,
                      ),
                      _buildBulletPoint(
                        '**การต่ออายุอัตโนมัติ:** แพ็กเกจสมาชิกจะต่ออายุโดยอัตโนมัติภายใน 24 ชั่วโมงก่อนสิ้นสุดรอบบิล เว้นแต่ท่านจะยกเลิกก่อนเวลาอย่างน้อย 24 ชั่วโมง',
                        textColor,
                      ),
                      _buildBulletPoint(
                        '**การยกเลิก:** ท่านสามารถจัดการหรือยกเลิกการสมัครสมาชิกได้ที่การตั้งค่าบัญชี (Account Settings) ใน App Store หรือ Play Store หลังการสั่งซื้อ',
                        textColor,
                      ),

                      _buildSubSectionTitle('2.5 ทรัพย์สินทางปัญญา', textColor),
                      _buildParagraph(
                        'ซอร์สโค้ดและการออกแบบเป็นลิขสิทธิ์ของผู้พัฒนา ส่วนข้อมูลราคาและเครื่องหมายการค้าของร้านทองเป็นของเจ้าของลิขสิทธิ์นั้นๆ',
                        textColor,
                      ),

                      const SizedBox(height: 24),

                      // 3. Contact
                      _buildSectionTitle('3. ช่องทางการติดต่อ'),
                      _buildParagraph(
                        'หากมีข้อสงสัย สามารถติดต่อผู้พัฒนาได้ที่:',
                        textColor,
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.email_outlined,
                              color: subTextColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'thaigoldview@outlook.com',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "ยอมรับเงื่อนไขทั้งหมด",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _onDecline,
                    child: const Text(
                      "ไม่ยอมรับ (ออกจากแอป)",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFD4AF37), // Gold
        ),
      ),
    );
  }

  Widget _buildSubSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text, Color textColor) {
    final parts = text.split('**');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 14,
            color: textColor,
            height: 1.6,
            fontFamily: 'Roboto',
          ),
          children: List.generate(parts.length, (index) {
            final isBold = index % 2 != 0;
            return TextSpan(
              text: parts[index],
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text, Color textColor) {
    final parts = text.split('**');
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFFD4AF37),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  height: 1.6,
                  fontFamily: 'Roboto',
                ),
                children: List.generate(parts.length, (index) {
                  final isBold = index % 2 != 0;
                  return TextSpan(
                    text: parts[index],
                    style: TextStyle(
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
