import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/theme.dart';

/// Sumber sudah tercermin di teks label, jadi badge ini monokrom: warna tidak
/// menambah informasi apa pun dan hanya memecah palet.
class SourceBadge extends StatelessWidget {
  const SourceBadge({super.key, required this.source});

  final TrackSource source;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        source.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
