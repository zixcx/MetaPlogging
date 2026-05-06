import 'package:flutter/material.dart';
import 'package:meta_plogging/core/theme/app_theme.dart';
import 'package:meta_plogging/features/plogging/domain/entities/tracking_session_entity.dart';

class EndSessionSheet extends StatefulWidget {
  final String distanceKm;
  final String duration;
  final void Function({
    required List<TrashItem> trashItems,
    required String? locationDescription,
  }) onConfirm;

  const EndSessionSheet({
    super.key,
    required this.distanceKm,
    required this.duration,
    required this.onConfirm,
  });

  @override
  State<EndSessionSheet> createState() => _EndSessionSheetState();
}

class _EndSessionSheetState extends State<EndSessionSheet> {
  final Map<TrashCategory, _TrashInput> _inputs = {};
  final _descController = TextEditingController();

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
            Text('플로깅 종료', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${widget.distanceKm}km · ${widget.duration}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Text('수거한 쓰레기 (선택)',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            ...TrashCategory.values.map((cat) => _TrashRow(
                  category: cat,
                  input: _inputs[cat],
                  onChanged: (input) => setState(() {
                    if (input == null) {
                      _inputs.remove(cat);
                    } else {
                      _inputs[cat] = input;
                    }
                  }),
                )),
            const SizedBox(height: 16),
            Text('활동 메모 (선택)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                hintText: '예: 한강 반포지구 산책로',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final items = _inputs.entries.map((e) {
                    final inp = e.value;
                    return TrashItem(
                      category: e.key,
                      level: inp.useCount ? null : inp.level,
                      count: inp.useCount ? inp.count : null,
                    );
                  }).toList();
                  Navigator.pop(context);
                  widget.onConfirm(
                    trashItems: items,
                    locationDescription: _descController.text.isEmpty
                        ? null
                        : _descController.text,
                  );
                },
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: const Text('기록 저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrashInput {
  final TrashAmountLevel level;
  final bool useCount;
  final int count;

  const _TrashInput({
    this.level = TrashAmountLevel.little,
    this.useCount = false,
    this.count = 0,
  });

  _TrashInput copyWith({
    TrashAmountLevel? level,
    bool? useCount,
    int? count,
  }) =>
      _TrashInput(
        level: level ?? this.level,
        useCount: useCount ?? this.useCount,
        count: count ?? this.count,
      );
}

class _TrashRow extends StatefulWidget {
  final TrashCategory category;
  final _TrashInput? input;
  final void Function(_TrashInput? input) onChanged;

  const _TrashRow({
    required this.category,
    required this.input,
    required this.onChanged,
  });

  @override
  State<_TrashRow> createState() => _TrashRowState();
}

class _TrashRowState extends State<_TrashRow> {
  bool _enabled = false;
  _TrashInput _input = const _TrashInput();
  final _countController = TextEditingController();

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _enabled,
                activeColor: AppColors.primary,
                onChanged: (v) {
                  setState(() => _enabled = v ?? false);
                  widget.onChanged(_enabled ? _input : null);
                },
              ),
              Text(widget.category.label,
                  style: theme.textTheme.bodyMedium),
            ],
          ),
          if (_enabled) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: _input.useCount
                  ? Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _countController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '개수',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                            onChanged: (v) {
                              final n = int.tryParse(v) ?? 0;
                              _input = _input.copyWith(count: n);
                              widget.onChanged(_input);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => setState(() {
                            _input = _input.copyWith(useCount: false);
                            widget.onChanged(_input);
                          }),
                          child: const Text('정도로 변경'),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        ...TrashAmountLevel.values.map((lvl) {
                          final selected = _input.level == lvl;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () {
                                setState(
                                    () => _input = _input.copyWith(level: lvl));
                                widget.onChanged(_input);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary
                                          .withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primary
                                        : theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Text(
                                  lvl.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? AppColors.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        TextButton(
                          onPressed: () => setState(() {
                            _input = _input.copyWith(useCount: true);
                            widget.onChanged(_input);
                          }),
                          child: const Text('개수 입력'),
                        ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
