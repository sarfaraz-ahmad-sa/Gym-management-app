import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class WorkspaceLogo extends StatefulWidget {
  const WorkspaceLogo({super.key, required this.data, this.size = 42});
  final String data;
  final double size;
  @override
  State<WorkspaceLogo> createState() => _WorkspaceLogoState();
}

class _WorkspaceLogoState extends State<WorkspaceLogo> {
  Uint8List? _bytes;
  void _decode() {
    _bytes = null;
    if (widget.data.startsWith('data:image/')) {
      try {
        _bytes = base64Decode(widget.data.split(',').last);
      } catch (_) {
        _bytes = null;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(covariant WorkspaceLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) _decode();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final fallback = Icon(
      Icons.storefront_outlined,
      size: size * .55,
      color: Theme.of(context).colorScheme.primary,
    );
    final child = _bytes == null
        ? fallback
        : Image.memory(
            _bytes!,
            width: size,
            height: size,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            frameBuilder: (_, image, frame, loaded) =>
                frame == null ? fallback : image,
            errorBuilder: (_, _, _) => fallback,
          );
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
    );
  }
}
