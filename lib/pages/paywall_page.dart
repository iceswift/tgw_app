import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:gold_app/services/purchase_service.dart';
import 'package:gold_app/pages/terms_privacy_page.dart';
import 'package:purchases_flutter/object_wrappers.dart'; // For Offerings/Package types

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  Offerings? _offerings;
  bool _isLoading = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    final offerings = await PurchaseService().getOfferings();
    if (mounted) {
      setState(() {
        _offerings = offerings;
        _isLoading = false;
      });
    }
  }

  Future<void> _makePurchase(Package package) async {
    setState(() => _isPurchasing = true);
    try {
      final success = await PurchaseService().purchasePackage(package);
      if (success && mounted) {
        Navigator.pop(context); // Close Paywall on success
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isPurchasing = true);
    try {
      await PurchaseService().restorePurchases();
      // Check status again? Usually PurchaseService/SDK handles listener
      // We can check manually:
      if (await PurchaseService().isPro && mounted) {
        Navigator.pop(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบประวัติการซื้อสมาชิก')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            )
          : Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 200,
                      pinned: true,
                      backgroundColor: backgroundColor,
                      elevation: 0,
                      leading: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: isDark ? Colors.white : Colors.black,
                            size: 20,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFFD4AF37).withOpacity(0.1),
                                backgroundColor,
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 60),
                              const Icon(
                                Icons.stars_rounded,
                                size: 64,
                                color: Color(0xFFD4AF37),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'อัปเกรดเป็น Gold',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ปลดล็อคฟีเจอร์ระดับพรีเมียม',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Benefits List
                            _buildBenefitItem(
                              context,
                              icon: Icons.block,
                              title: 'ไม่มีโฆษณากวนใจ',
                              subtitle: 'ใช้งานแอปได้อย่างลื่นไหล รวดเร็ว',
                            ),
                            const SizedBox(height: 16),
                            _buildBenefitItem(
                              context,
                              icon: Icons.file_download_outlined,
                              title: 'บันทึกรูปภาพราคาทอง',
                              subtitle:
                                  'แชร์ราคาทองให้เพื่อนหรือลูกค้าได้ทันที',
                            ),
                            const SizedBox(height: 16),
                            _buildBenefitItem(
                              context,
                              icon: Icons.lock_outline,
                              title: 'ล็อคแอปด้วยรหัส PIN',
                              subtitle: 'เพิ่มความปลอดภัยและความเป็นส่วนตัว',
                            ),

                            const SizedBox(height: 40),

                            // Subscription Cards
                            if (kIsWeb) ...[
                              Container(
                                padding: const EdgeInsets.all(20),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.phone_iphone_rounded,
                                      color: Colors.blue[600],
                                      size: 40,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'ไม่รองรับบนเว็บไซต์',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.blue[300]
                                            : Colors.blue[800],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'การอัปเกรดเป็นระดับ Gold สามารถทำได้ผ่านแอปพลิเคชันบนมือถือ (iOS/Android) เท่านั้น เพื่อประสบการณ์ที่สมบูรณ์แบบ กรุณาดาวน์โหลดแอป',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        height: 1.5,
                                        color: isDark
                                            ? Colors.grey[300]
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (_offerings != null &&
                                _offerings!.current != null &&
                                _offerings!
                                    .current!
                                    .availablePackages
                                    .isNotEmpty) ...[
                              // Yearly Package (Prioritize if exists)
                              ..._offerings!.current!.availablePackages
                                  .where(
                                    (p) => p.packageType == PackageType.annual,
                                  )
                                  .map(
                                    (p) => _buildSubscriptionCard(
                                      context,
                                      p,
                                      isBestValue: true,
                                    ),
                                  ),

                              const SizedBox(height: 16),

                              // Monthly Package
                              ..._offerings!.current!.availablePackages
                                  .where(
                                    (p) => p.packageType == PackageType.monthly,
                                  )
                                  .map(
                                    (p) => _buildSubscriptionCard(context, p),
                                  ),
                            ] else ...[
                              const Text(
                                'ไม่พบข้อมูลแพ็คเกจ กรุณาลองใหม่ภายหลัง',
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Restore Button
                            if (!kIsWeb)
                              TextButton(
                                onPressed: _restorePurchases,
                                child: Text(
                                  'กู้คืนการซื้อเดิม',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 12),

                            // Terms & Privacy
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const TermsPrivacyPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'ข้อตกลงและเงื่อนไข',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[500],
                                      fontSize: 12,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                Text(
                                  '  •  ',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const TermsPrivacyPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'นโยบายความเป็นส่วนตัว',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[500],
                                      fontSize: 12,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Loading Overlay
                if (_isPurchasing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildBenefitItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFFD4AF37), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    Package package, {
    bool isBestValue = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceString = package.storeProduct.priceString;
    final title = package.packageType == PackageType.annual
        ? 'รายปี (คุ้มที่สุด)'
        : 'รายเดือน';
    final description = package.packageType == PackageType.annual
        ? 'จ่ายทีเดียว ใช้งานได้ยาวนานตลอด 12 เดือน'
        : 'ยืดหยุ่น ยกเลิกได้ตลอดเวลา';

    return GestureDetector(
      onTap: () => _makePurchase(package),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isBestValue
              ? const Color(0xFFD4AF37).withOpacity(0.1)
              : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isBestValue
                ? const Color(0xFFD4AF37)
                : Colors.grey.withOpacity(0.2),
            width: isBestValue ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            if (isBestValue)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ขายดีที่สุด 🔥',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              priceString,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isBestValue
                    ? const Color(0xFFD4AF37)
                    : (isDark ? Colors.white : Colors.black),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'สมัครสมาชิก',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors
                      .white, // In dark mode, if container is white, text should be black?
                  // Logic fix:
                  // BestValue -> Gold BG -> White Text
                  // NotBest -> (Dark Mode -> White BG -> Black Text) / (Light Mode -> Black BG -> White Text)
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ).apply(color: !isBestValue && isDark ? Colors.black : Colors.white),
              // Apply color override based on logic above
            ),
          ],
        ),
      ),
    );
  }
}

extension TextStyleApply on Text {
  Text apply({Color? color}) {
    return Text(
      data!,
      textAlign: textAlign,
      style: style?.copyWith(color: color) ?? TextStyle(color: color),
    );
  }
}
