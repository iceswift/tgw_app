import 'package:flutter/material.dart';
import 'package:gold_app/widgets/main_layout_scaffold.dart';

class TermsPrivacyPage extends StatelessWidget {
  const TermsPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white.withOpacity(0.9) : Colors.black87;
    final subTextColor = isDark
        ? Colors.white.withOpacity(0.7)
        : Colors.black54;

    return MainLayoutScaffold(
      header: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Centered Title
          const Center(
            child: Text(
              'ข้อตกลงและนโยบาย',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Center(
              child: Column(
                children: [
                  Text(
                    'เอกสารทางกฎหมาย',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37), // Gold
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'นโยบายความเป็นส่วนตัวและข้อกำหนดการใช้งาน',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: subTextColor),
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
            const SizedBox(height: 32),

            // Intro
            Text(
              '    เอกสารฉบับนี้จัดทำขึ้นเพื่ออธิบายแนวทางการคุ้มครองข้อมูลส่วนบุคคล และกำหนดเงื่อนไขการใช้งานแอปพลิเคชัน Gold App ("Thai Gold View") ซึ่งเป็นแอปพลิเคชันเวอร์ชันฟรีที่สนับสนุนโดยโฆษณา (Ad-Supported) โปรดอ่านเอกสารฉบับนี้อย่างละเอียดก่อนใช้งาน',
              style: TextStyle(fontSize: 14, color: textColor, height: 1.6),
            ),
            const SizedBox(height: 32),

            // 1. Privacy Policy
            _buildSectionTitle(
              context,
              '1. นโยบายความเป็นส่วนตัว (Privacy Policy)',
            ),
            _buildParagraph(
              context,
              'เราให้ความสำคัญกับความเป็นส่วนตัวของผู้ใช้งาน และดำเนินการตามหลักการคุ้มครองข้อมูลส่วนบุคคลที่สอดคล้องกับกฎหมายที่เกี่ยวข้อง (PDPA)',
            ),

            _buildSubSectionTitle(
              context,
              '1.1 การเก็บรวบรวมและใช้ข้อมูลส่วนบุคคล',
            ),
            _buildParagraph(
              context,
              'แอปพลิเคชัน Thai Gold View **ไม่ได้มีการเก็บรวบรวมข้อมูลส่วนบุคคลที่ระบุตัวตนได้** (Personally Identifiable Information - PII) ในการเข้าใช้งานพื้นฐาน แอปพลิเคชันไม่ได้จัดเก็บข้อมูลบัตรเครดิตหรือข้อมูลทางการเงินใดๆ ของผู้ใช้งาน',
            ),
            _buildBulletPoint(
              context,
              'ไม่มีระบบลงทะเบียนด้วยอีเมลหรือเบอร์โทรศัพท์',
            ),
            _buildBulletPoint(
              context,
              'การใช้งานแอปพลิเคชันทำได้ทันทีโดยไม่ต้องผูกบัญชี',
            ),
            _buildBulletPoint(context, 'ไม่มีการร้องขอชื่อ นามสกุล หรืออีเมล'),
            _buildBulletPoint(context, 'ไม่มีการติดตามตัวตนของผู้ใช้งาน'),

            _buildSubSectionTitle(context, '1.2 การจัดเก็บข้อมูลภายในอุปกรณ์'),
            _buildParagraph(
              context,
              'ข้อมูลบางประเภทจะถูกจัดเก็บไว้ภายในอุปกรณ์ของท่านเท่านั้น (Local Storage) เพื่อความสะดวกในการใช้งาน เช่น การตั้งค่าธีมแอป หรือประวัติการคำนวณ โดยข้อมูลเหล่านี้จะไม่ถูกส่งออกภายนอก',
            ),

            _buildSubSectionTitle(context, '1.3 โฆษณาและการวิเคราะห์'),
            _buildParagraph(
              context,
              'เราใช้บริการ Google AdMob เพื่อแสดงโฆษณาภายในแอปพลิเคชัน บริการนี้อาจมีการใช้รหัสระบุตัวตนสำหรับโฆษณา (Advertising ID) เพื่อนำเสนอโฆษณาที่เหมาะสมสำหรับผู้ใช้ นอกจากนี้เรายังใช้ข้อมูลสถิติพื้นฐานเพื่อปรับปรุงประสิทธิภาพของแอปพลิเคชัน',
            ),

            const SizedBox(height: 32),

            // 2. Terms of Service
            _buildSectionTitle(context, '2. ข้อกำหนดและเงื่อนไขการใช้งาน'),

            _buildSubSectionTitle(context, '2.1 การยอมรับข้อตกลง'),
            _buildParagraph(
              context,
              'การดาวน์โหลดและใช้งานแอปพลิเคชันถือว่าผู้ใช้ยอมรับข้อกำหนดฉบับนี้แล้ว',
            ),

            _buildSubSectionTitle(context, '2.2 วัตถุประสงค์'),
            _buildParagraph(
              context,
              'แอปพลิเคชันนี้จัดทำขึ้นเพื่อ **ให้ข้อมูลเท่านั้น (Informational Purposes Only)** เพื่ออำนวยความสะดวกในการตรวจสอบราคาทองคำ',
            ),

            _buildSubSectionTitle(
              context,
              '2.3 การปฏิเสธความรับผิด (Disclaimer)',
            ),
            _buildBulletPoint(
              context,
              '**ความถูกต้อง:** ข้อมูลอาจมีความล่าช้าหรือคลาดเคลื่อน เราไม่รับประกันความถูกต้อง 100%',
            ),
            _buildBulletPoint(
              context,
              '**ไม่ใช่คำแนะนำการลงทุน:** ข้อมูลในแอปไม่ใช่คำแนะนำทางการเงิน ผู้ใช้ควรใช้วิจารณญาณก่อนตัดสินใจ',
            ),

            _buildSubSectionTitle(context, '2.5 ทรัพย์สินทางปัญญา'),
            _buildParagraph(
              context,
              'ซอร์สโค้ดและการออกแบบเป็นลิขสิทธิ์ของผู้พัฒนา ส่วนข้อมูลราคาและเครื่องหมายการค้าของร้านทองเป็นของเจ้าของลิขสิทธิ์นั้นๆ',
            ),

            const SizedBox(height: 32),

            // 3. Contact
            _buildSectionTitle(context, '3. ช่องทางการติดต่อ'),
            _buildParagraph(
              context,
              'หากมีข้อสงสัย สามารถติดต่อผู้พัฒนาได้ที่:',
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email_outlined, color: subTextColor, size: 20),
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

            const SizedBox(height: 60), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
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

  Widget _buildSubSectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Simple logic to bold specific parts if needed, but for now standard text
    final parts = text.split('**');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
            height: 1.6,
            fontFamily: 'Roboto', // Or app default
          ),
          children: List.generate(parts.length, (index) {
            // Even index = normal, Odd index = bold
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

  Widget _buildBulletPoint(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: Color(0xFFD4AF37), // Gold bullet
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? Colors.white.withOpacity(0.9)
                      : Colors.black87,
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
