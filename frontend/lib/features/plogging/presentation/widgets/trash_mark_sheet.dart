import 'package:flutter/material.dart';
import 'package:meta_plogging/core/theme/app_theme.dart';
import 'package:meta_plogging/features/plogging/domain/entities/tracking_session_entity.dart';

class TrashMarkSheet extends StatefulWidget {
  final void Function(TrashCategory category) onConfirm;

  const TrashMarkSheet({super.key, required this.onConfirm});

  @override
  State<TrashMarkSheet> createState() => _TrashMarkSheetState();
}

class _TrashMarkSheetState extends State<TrashMarkSheet> {
  TrashCategory? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('쓰레기 종류 선택', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TrashCategory.values.map((cat) {
              final isSelected = _selected == cat;
              return GestureDetector(
                onTap: () => setState(() => _selected = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : (isDark
                            ? const Color(0xFF1A3028)
                            : const Color(0xFFF5F9F6)),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : theme.colorScheme.outlineVariant,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    cat.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selected == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      widget.onConfirm(_selected!);
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.3),
              ),
              child: const Text('마킹하기'),
            ),
          ),
        ],
      ),
    );
  }
}
