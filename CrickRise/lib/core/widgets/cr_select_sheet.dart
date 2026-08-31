import 'package:flutter/material.dart';

import '../models/community.dart';
import '../theme/app_theme.dart';
import '../theme/cr_matchday.dart';

/// Tappable select field that opens a searchable bottom sheet list.
class CRSelectField extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final String? leading;
  final VoidCallback onTap;

  const CRSelectField({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.leading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CRPaper(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (leading != null) ...[
              Text(leading!, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(), style: CRType.overline(size: 8, color: CR.fog)),
                  const SizedBox(height: 4),
                  Text(value, style: CRType.body(weight: FontWeight.w600)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: CRType.caption(size: 12)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.unfold_more, color: CR.brass, size: 20),
          ],
        ),
      ),
    );
  }
}

Future<T?> showCRSelectSheet<T>({
  required BuildContext context,
  required String title,
  required List<CRSelectItem<T>> items,
  T? selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: CR.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) {
          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: CR.chalk.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(title, style: CRType.headline(size: 22)),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final isSelected = selected == item.value;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: item.leading != null
                          ? Text(item.leading!, style: const TextStyle(fontSize: 24))
                          : null,
                      title: Text(
                        item.label,
                        style: CRType.body(
                          weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? CR.brass : CR.chalk,
                        ),
                      ),
                      subtitle: item.subtitle != null
                          ? Text(item.subtitle!, style: CRType.caption(size: 12))
                          : null,
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: CR.brass, size: 20)
                          : null,
                      onTap: () => Navigator.pop(ctx, item.value),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class CRSelectItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final String? leading;

  const CRSelectItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.leading,
  });
}
