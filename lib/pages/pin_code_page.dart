import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gold_app/main.dart'; // To access SettingsController
// import 'package:local_auth/local_auth.dart'; // Future: Biometric

enum PinMode {
  verify, // Enter existing PIN to unlock
  setup, // Enter new PIN
  confirm, // Confirm new PIN
  disable, // Enter PIN to disable lock
}

class PinCodePage extends StatefulWidget {
  final PinMode initialMode;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const PinCodePage({
    super.key,
    this.initialMode = PinMode.verify,
    this.onSuccess,
    this.onCancel,
  });

  @override
  State<PinCodePage> createState() => _PinCodePageState();
}

class _PinCodePageState extends State<PinCodePage> {
  late PinMode _currentMode;
  String _inputPin = '';
  String _tempPin = ''; // For setup mode (first entry)
  String _message = '';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
    _updateMessage();
  }

  void _updateMessage() {
    setState(() {
      _isError = false; // Reset error on mode change
      switch (_currentMode) {
        case PinMode.verify:
          _message = 'กรุณาใส่รหัสผ่าน';
          break;
        case PinMode.setup:
          _message = 'ตั้งรหัสผ่านใหม่';
          break;
        case PinMode.confirm:
          _message = 'ยืนยันรหัสผ่านอีกครั้ง';
          break;
        case PinMode.disable:
          _message = 'ใส่รหัสผ่านเพื่อปิดการใช้งาน';
          break;
      }
    });
  }

  void _onKeyPress(String key) {
    if (_inputPin.length < 4) {
      setState(() {
        _inputPin += key;
        _isError = false;
      });
      HapticFeedback.lightImpact();

      if (_inputPin.length == 4) {
        _processPin();
      }
    }
  }

  void _onDelete() {
    if (_inputPin.isNotEmpty) {
      setState(() {
        _inputPin = _inputPin.substring(0, _inputPin.length - 1);
        _isError = false;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _processPin() async {
    // Small delay for UX
    await Future.delayed(const Duration(milliseconds: 200));

    switch (_currentMode) {
      case PinMode.verify:
      case PinMode.disable:
        final bool isValid = SettingsController().verifyPin(_inputPin);
        if (isValid) {
          if (_currentMode == PinMode.disable) {
            // Disable Logic
            // Disable Logic
            final success = await SettingsController().setAppLock(false);
            if (mounted) {
              if (success) {
                Navigator.pop(context); // Close page
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('บันทึกข้อมูลไม่สำเร็จ: พื้นที่จัดเก็บเต็ม'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } else {
            // Verify Logic (Unlock)
            SettingsController().unlockApp();
            if (widget.onSuccess != null) {
              widget.onSuccess!();
            } else {
              // Overlay mode: Do NOT pop. Logic in main.dart handles removal.
            }
          }
        } else {
          _triggerError('รหัสผ่านไม่ถูกต้อง');
        }
        break;

      case PinMode.setup:
        setState(() {
          _tempPin = _inputPin;
          _inputPin = '';
          _currentMode = PinMode.confirm;
          _updateMessage();
        });
        break;

      case PinMode.confirm:
        if (_inputPin == _tempPin) {
          // Success Setup
          // Success Setup
          final pinSuccess = await SettingsController().setPin(_inputPin);
          if (!pinSuccess) {
            if (mounted) {
              _triggerError('บันทึกรหัสผ่านไม่สำเร็จ: พื้นที่จัดเก็บเต็ม');
            }
            return;
          }

          final lockSuccess = await SettingsController().setAppLock(true);
          if (!lockSuccess) {
            if (mounted) {
              _triggerError('เปิดใช้งานล็อคไม่สำเร็จ: พื้นที่จัดเก็บเต็ม');
            }
            return;
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ตั้งรหัสผ่านเรียบร้อยแล้ว')),
            );
            Navigator.pop(context);
          }
        } else {
          _triggerError('รหัสผ่านไม่ตรงกัน กรุณาลองใหม่');
          // Reset to Setup
          await Future.delayed(const Duration(milliseconds: 1000));
          setState(() {
            _inputPin = '';
            _tempPin = '';
            _currentMode = PinMode.setup;
            _updateMessage();
          });
        }
        break;
    }
  }

  void _triggerError(String msg) {
    setState(() {
      _isError = true;
      _message = msg;
      _inputPin = '';
    });
    HapticFeedback.heavyImpact();
    // Shake animation could go here
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFFAFAFA);
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = const Color(0xFFD4AF37); // Gold

    return Scaffold(
      backgroundColor: bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: SafeArea(
                  child: Column(
                    children: [
                      // Top Bar
                      Stack(
                        children: [
                          // Close Button (Left) - Only for non-verify modes
                          if (widget.initialMode != PinMode.verify)
                            Align(
                              alignment: Alignment.topLeft,
                              child: IconButton(
                                icon: Icon(Icons.close, color: textColor),
                                onPressed: () {
                                  if (widget.onCancel != null)
                                    widget.onCancel!();
                                  Navigator.pop(context);
                                },
                              ),
                            ),

                          // Warning Icon (Right) - Only for Setup/Confirm modes
                          if (widget.initialMode == PinMode.setup ||
                              widget.initialMode == PinMode.confirm)
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.redAccent.withOpacity(0.8),
                                  size: 28,
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'หากลืมรหัสผ่าน จำเป็นต้องลบแอปฯ และติดตั้งใหม่เท่านั้น',
                                        textAlign: TextAlign.center,
                                      ),
                                      duration: const Duration(seconds: 5),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      backgroundColor: const Color(0xFF333333),
                                    ),
                                  );
                                },
                              ),
                            ),

                          // Spacer logic for Verify mode (if neither left nor right buttons are present) -> Actually SizedBox(height: 50) was used before
                          if (widget.initialMode == PinMode.verify)
                            const SizedBox(height: 20),
                        ],
                      ),

                      const Spacer(flex: 1),

                      // Icon
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 40,
                        color: primaryColor,
                      ),
                      const SizedBox(height: 16),

                      // Message
                      Text(
                        _message,
                        style: TextStyle(
                          fontSize: 18,
                          color: _isError ? Colors.redAccent : textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Dots Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final bool isFilled = index < _inputPin.length;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFilled
                                  ? primaryColor
                                  : Colors.transparent,
                              border: Border.all(
                                color: isFilled
                                    ? primaryColor
                                    : (isDark
                                          ? Colors.grey[700]!
                                          : Colors.grey[300]!),
                                width: 2,
                              ),
                            ),
                          );
                        }),
                      ),

                      const Spacer(flex: 2),

                      // Numpad
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            _buildRow(['1', '2', '3'], textColor, primaryColor),
                            _buildRow(['4', '5', '6'], textColor, primaryColor),
                            _buildRow(['7', '8', '9'], textColor, primaryColor),
                            _buildRow(
                              ['', '0', 'DEL'],
                              textColor,
                              primaryColor,
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 1),
                      // Version or Logo at bottom
                      if (widget.initialMode == PinMode.verify)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: TextButton(
                            onPressed: _showForgotPinDialog,
                            child: Text(
                              'ลืมรหัสผ่าน?',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showForgotPinDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'ลืมรหัสผ่าน?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'เพื่อความปลอดภัย รหัสผ่านจะถูกบันทึกไว้ในเครื่องของคุณเท่านั้น\n\nหากลืมรหัสผ่าน คุณจำเป็นต้อง "ลบแอปพลิเคชันและติดตั้งใหม่" เพื่อทำการรีเซ็ตรหัสผ่าน',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[800],
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'เข้าใจแล้ว',
                style: TextStyle(color: Color(0xFFD4AF37)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRow(List<String> keys, Color textColor, Color activeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment
            .center, // Changed to center for better compact fit if needed, or keep spaceEvenly
        children: keys.map((key) {
          if (key.isEmpty) return const SizedBox(width: 72, height: 72);
          if (key == 'DEL') {
            return SizedBox(
              width: 72,
              height: 72,
              child: InkWell(
                onTap: _onDelete,
                customBorder: const CircleBorder(),
                child: Icon(
                  Icons.backspace_outlined,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
            ), // Add horizontal spacing between keys
            child: _buildKey(key, textColor, activeColor),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKey(String key, Color textColor, Color activeColor) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        onTap: () => _onKeyPress(key),
        customBorder: const CircleBorder(),
        child: Center(
          child: Text(
            key,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
