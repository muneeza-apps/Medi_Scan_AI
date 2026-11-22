import 'package:flutter/material.dart';

class VitalsMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String status;
  final IconData icon;
  final Color themeColor;
  final Color bgTint;
  final bool isAlert;
  final bool isNoSignal;
  final Widget? trailingBadge;
  final String? normalRange;
  final bool isDarkMode;

  const VitalsMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.status,
    required this.icon,
    required this.themeColor,
    required this.bgTint,
    this.isAlert = false,
    this.isNoSignal = false,
    this.trailingBadge,
    this.normalRange,
    this.isDarkMode = true,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDarkMode ? const Color(0xFF111C1E) : Colors.white;
    final borderColor = isAlert
        ? Colors.red.shade400
        : isNoSignal
            ? (isDarkMode ? const Color(0xFF1E3532) : Colors.grey.shade300)
            : (isDarkMode ? themeColor.withValues(alpha: 0.35) : bgTint.withValues(alpha: 0.8));

    final iconBg = isDarkMode ? bgTint.withValues(alpha: 0.15) : bgTint;
    final titleColor = isDarkMode ? const Color(0xFFB2DFDB) : Colors.grey.shade800;
    final valueColor = isNoSignal
        ? (isDarkMode ? const Color(0xFF546E7A) : Colors.grey.shade400)
        : isAlert
            ? (isDarkMode ? const Color(0xFFFF5252) : Colors.red.shade700)
            : (isDarkMode ? Colors.white : const Color(0xFF1B2E2B));

    final unitColor = isDarkMode ? const Color(0xFF80CBC4) : Colors.grey.shade600;

    final statusBg = isNoSignal
        ? (isDarkMode ? const Color(0xFF162325) : Colors.grey.shade100)
        : isAlert
            ? (isDarkMode ? Colors.red.withValues(alpha: 0.2) : Colors.red.shade50)
            : (isDarkMode ? bgTint.withValues(alpha: 0.18) : bgTint.withValues(alpha: 0.5));

    final statusTextColor = isNoSignal
        ? (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)
        : isAlert
            ? (isDarkMode ? const Color(0xFFFF8A80) : Colors.red.shade700)
            : (isDarkMode ? themeColor : themeColor);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isAlert ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isAlert ? Colors.red : themeColor).withValues(alpha: isDarkMode ? 0.08 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: themeColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ?trailingBadge,
            ],
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                isNoSignal ? '--' : value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: valueColor,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: unitColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isNoSignal ? 'Awaiting Contact' : status,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: statusTextColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (normalRange != null)
                Text(
                  normalRange!,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDarkMode ? const Color(0xFF80CBC4).withValues(alpha: 0.6) : Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

