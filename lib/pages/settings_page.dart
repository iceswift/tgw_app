import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gold_app/main.dart'; // Import to access SettingsController
import 'package:gold_app/widgets/main_layout_scaffold.dart';
import 'package:gold_app/utils/ad_config.dart';
import 'package:gold_app/pages/terms_privacy_page.dart';
import 'package:gold_app/pages/pin_code_page.dart';
import 'package:intl/intl.dart';

class SettingsPage extends StatelessWidget {
  final SettingsController controller;

  const SettingsPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // Languages map removed (unused)

    return MainLayoutScaffold(
      adUnitId: AdConfig.settingsPageBanner,
      headerHeight: 310.0,
      header: _buildAppHeader(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'การแสดงผล'),
          const SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingItem(
                context,
                icon: _getThemeIcon(controller.themeMode),
                title: 'ธีมแอปพลิเคชัน',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ThemeMode>(
                      value: controller.themeMode,
                      dropdownColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFFD4AF37), // Premium Gold
                      ),
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (ThemeMode? newValue) {
                        if (newValue != null) {
                          controller.setThemeMode(newValue);
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.brightness_auto_rounded,
                                size: 18,
                                color: controller.themeMode == ThemeMode.system
                                    ? const Color(0xFFD4AF37)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              const Text('อัตโนมัติ'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.wb_sunny_rounded,
                                size: 18,
                                color: controller.themeMode == ThemeMode.light
                                    ? const Color(0xFFD4AF37)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              const Text('โหมดสว่าง'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.dark_mode_rounded,
                                size: 18,
                                color: controller.themeMode == ThemeMode.dark
                                    ? const Color(0xFFD4AF37)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              const Text('โหมดมืด'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'เกี่ยวกับ'),
          const SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingItem(
                context,
                icon: Icons.mail_outline,
                title: 'ติดต่อผู้พัฒนา',
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
                onTap: () => _showContactDialog(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.05),
                ),
              ),
              _buildSettingItem(
                context,
                icon: Icons.description_outlined,
                title: 'ข้อตกลงและนโยบายความเป็นส่วนตัว',
                subtitle: controller.termsAcceptedDate != null
                    ? 'ยอมรับแล้วเมื่อ: ${DateFormat('d MMM yyyy HH:mm', 'th').format(DateTime.parse(controller.termsAcceptedDate!))}'
                    : null,
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsPrivacyPage(),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.05),
                ),
              ),
              _buildSettingItem(
                context,
                icon: Icons.info_outline,
                title: 'เวอร์ชันแอปพลิเคชัน',
                trailing: Text(
                  '1.0.0',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(context, 'ความปลอดภัย'),
          const SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingItem(
                context,
                icon: Icons.lock_outline_rounded,
                title: 'ล็อคแอปพลิเคชัน (PIN)',
                trailing: Switch.adaptive(
                  value: controller.isAppLockEnabled,
                  activeColor: const Color(0xFFD4AF37),
                  onChanged: (value) {
                    if (value) {
                      // Enable: Go to Setup
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const PinCodePage(initialMode: PinMode.setup),
                        ),
                      );
                    } else {
                      // Disable: Go to Disable (Verify first)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PinCodePage(
                            initialMode: PinMode.disable,
                            onSuccess: () {
                              // Already handled in PinCodePage
                            },
                          ),
                        ),
                      );
                    }
                  },
                ),
                onTap: null, // Tap handled by switch
              ),
            ],
          ),
          const SizedBox(height: 24),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildAppHeader(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: _RotatableCard(controller: controller),
          ),
        ),
      ],
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.wb_sunny_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFD4AF37), // Premium Gold
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    Color? iconColor,
    required String title,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (iconColor ?? const Color(0xFFD4AF37)).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor ?? const Color(0xFFD4AF37),
                size: 22,
              ),
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
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[200] : Colors.grey[800],
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.45,
              ),
              child: trailing,
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.mail_outline, color: Color(0xFFD4AF37)),
              SizedBox(width: 12),
              Text(
                'ติดต่อผู้พัฒนา',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'หากพบปัญหาการใช้งาน หรือมีข้อเสนอแนะ\nสามารถติดต่อเราได้ที่',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'thaigoldview@outlook.com',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      color: Colors.grey,
                      onPressed: () {
                        Clipboard.setData(
                          const ClipboardData(text: 'thaigoldview@outlook.com'),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('คัดลอกอีเมลแล้ว')),
                          );
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ปิด', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }
}

class _RotatableCard extends StatefulWidget {
  final SettingsController controller;

  const _RotatableCard({required this.controller});

  @override
  State<_RotatableCard> createState() => _RotatableCardState();
}

class _RotatableCardState extends State<_RotatableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _angle = 0.0;
  double _velocity = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _controller.addListener(() {
      if (!_isDragging && _velocity.abs() > 0.001) {
        setState(() {
          _angle += _velocity;
          _velocity *= 0.95; // Friction decay
        });
      }
    });
    _controller.repeat(); // Keep ticking for physics loop
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      // Slower sensitivity (0.005 instead of 0.01)
      _angle -= details.delta.dx * 0.005;
      _velocity = -details.delta.dx * 0.005;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      // Inherit velocity from drag
      _velocity = -details.velocity.pixelsPerSecond.dx * 0.0001;
    });
  }

  void _onTap() {
    // Spin 360 degrees (2*pi)
    setState(() {
      _velocity = 0.15; // Impulse spin
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate if showing back
    // Normalize angle to 0..2PI
    final normalizedAngle = (_angle % (2 * 3.14159));
    final isBack =
        normalizedAngle > (3.14159 / 2) && normalizedAngle < (3 * 3.14159 / 2);

    return GestureDetector(
      onTap: _onTap,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // Perspective
          ..rotateY(_angle),
        alignment: Alignment.center,
        child: isBack
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(3.14159), // Mirror back
                child: _buildBackSide(),
              )
            : _buildFrontSide(),
      ),
    );
  }

  Widget _buildFrontSide() {
    // Format Join Date
    String joinDateStr = '-';
    if (widget.controller.joinDate != null) {
      final date = DateTime.parse(widget.controller.joinDate!);
      joinDateStr = DateFormat('d MMM yyyy', 'th').format(date);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFD4AF37), // Gold
            Color(0xFFFFE57F), // Vibrant Light Gold
            Color(0xFFD4AF37), // Gold
            Color(0xFFAA8A26), // Dark Gold
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.4),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.star_rounded,
              size: 150,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thai Gold View',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'ราคาทองคำวันนี้',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'GOLD MEMBER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'วันที่เข้าร่วม',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        joinDateStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Text(
                      'Standard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackSide() {
    return Container(
      width: double.infinity,
      height: 220, // Approximate height to match front
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD4AF37),
          width: 2,
        ), // Gold border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2C2C2C), // Dark Grey
            Color(0xFF000000), // Black
            Color(0xFF1A1A1A), // Dark Grey
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.2, 0.5, 0.9],
        ),
      ),
      child: Stack(
        children: [
          // 1. Watermark Texture
          Positioned(
            bottom: -30,
            left: -30,
            child: Icon(
              Icons.verified_user_rounded,
              size: 180,
              color: const Color(0xFFD4AF37).withOpacity(0.05),
            ),
          ),

          // 2. Shine Effect (Diagonal Light)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0.0),
                  ],
                  begin: const Alignment(-1.0, -1.0),
                  end: const Alignment(1.0, 1.0),
                  stops: const [0.4, 0.5, 0.6],
                ),
              ),
            ),
          ),

          // 3. Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFD4AF37),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ขอขอบคุณ',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ที่ไว้วางใจใช้งานแอปพลิเคชันของเรา\nขอให้ความมั่งคั่งและความสำเร็จอยู่กับท่านเสมอครับ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.6,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
