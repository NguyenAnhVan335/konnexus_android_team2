import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Thanh điều hướng dưới cùng: Home / Khám phá / Tin nhắn / Bạn bè / Cá nhân.
class KonexusBottomNav extends StatelessWidget {
  const KonexusBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const List<_NavItem> _items = <_NavItem>[
    _NavItem(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home),
    _NavItem(
        label: 'Khám phá',
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore),
    _NavItem(
        label: 'Tin nhắn',
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble),
    _NavItem(
        label: 'Bạn bè', icon: Icons.people_outline, activeIcon: Icons.people),
    _NavItem(
        label: 'Cá nhân', icon: Icons.person_outline, activeIcon: Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    final Color background = Theme.of(context).colorScheme.primary;
    return Material(
      color: background,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: <Widget>[
              for (int index = 0; index < _items.length; index++)
                Expanded(
                  child: InkWell(
                    onTap: () => onSelected(index),
                    child: _NavButton(
                      item: _items[index],
                      isActive: currentIndex == index,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.isActive});

  final _NavItem item;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final Color color = isActive ? Colors.white : Colors.white70;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(isActive ? item.activeIcon : item.icon, size: 22, color: color),
        const SizedBox(height: 3),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Nhãn nhỏ hiển thị số đếm (thông báo/tin nhắn chưa đọc).
class CountBadge extends StatelessWidget {
  const CountBadge(
      {super.key, required this.value, this.color = AppColors.danger});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (value <= 0) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(9)),
      constraints: const BoxConstraints(minWidth: 16),
      alignment: Alignment.center,
      child: Text(
        value > 99 ? '99+' : '$value',
        style: const TextStyle(
            color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
