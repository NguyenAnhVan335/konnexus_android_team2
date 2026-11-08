import 'package:flutter/material.dart';

import '../../../state/settings_controller.dart';
import '../../../theme/app_colors.dart';

/// Bộ chọn "Màu theme" trong Cài đặt.
class AccentPicker extends StatelessWidget {
  const AccentPicker({super.key, required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color muted =
        isDark ? AppColors.darkTextSecondary : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Màu theme',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              for (int index = 0;
                  index < AppColors.accentOptions.length;
                  index++)
                GestureDetector(
                  onTap: () => settings.setAccentIndex(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.accentOptions[index],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: settings.accentIndex == index
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: settings.accentIndex == index
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppColors.accentNames[index],
                        style: TextStyle(fontSize: 9.5, color: muted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
