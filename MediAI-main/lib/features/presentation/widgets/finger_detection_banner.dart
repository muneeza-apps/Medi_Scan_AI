import 'package:flutter/material.dart';

class FingerDetectionBanner extends StatelessWidget {
  final bool hasFinger;
  final String status;
  final int signalQuality;
  final bool isDarkMode;

  const FingerDetectionBanner({
    super.key,
    required this.hasFinger,
    required this.status,
    this.signalQuality = 95,
    this.isDarkMode = true,
  });

  @override
  Widget build(BuildContext context) {
    if (hasFinger) {
      final bannerBg = isDarkMode ? const Color(0xFF0F261D) : const Color(0xFFE8F5E9);
      final borderColor = isDarkMode ? const Color(0xFF1B5E20) : const Color(0xFFA5D6A7);
      final titleColor = isDarkMode ? const Color(0xFF69F0AE) : const Color(0xFF1B5E20);
      final badgeBg = isDarkMode ? const Color(0xFF1B5E20) : const Color(0xFFC8E6C9);
      final badgeTextColor = isDarkMode ? const Color(0xFFB9F6CA) : const Color(0xFF1B5E20);
      final subtitleColor = isDarkMode ? const Color(0xFF81C784) : Colors.green.shade800;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bannerBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E676).withValues(alpha: isDarkMode ? 0.08 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Sensor Contact Active',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Signal Quality: $signalQuality% • Steady photoplethysmogram acquired',
                    style: TextStyle(
                      fontSize: 11,
                      color: subtitleColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final bannerBg = isDarkMode ? const Color(0xFF261A0E) : const Color(0xFFFFF3E0);
    final borderColor = isDarkMode ? const Color(0xFFE65100) : const Color(0xFFFFCC80);
    final titleColor = isDarkMode ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
    final subtitleColor = isDarkMode ? const Color(0xFFFFCC80) : Colors.orange.shade900;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: isDarkMode ? 0.12 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade800,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pan_tool_outlined, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'No Finger Contact Detected',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade900.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade700, width: 0.8),
                      ),
                      child: const Text(
                        'NO SENSOR CONTACT',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD54F),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Place finger gently on the biometric scanner.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: subtitleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
