import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/format.dart';

class Brand extends StatelessWidget {
  const Brand({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.blue,
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(
          Icons.fitness_center_rounded,
          color: Colors.white,
          size: 23,
        ),
      ),
      if (!compact) ...[
        const SizedBox(width: 11),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'FitGuide',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontSize: 23, letterSpacing: -.7),
            ),
          ),
        ),
        const SizedBox(width: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.blue.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(5),
          ),
          child: const Text(
            'PRO',
            style: TextStyle(
              color: AppTheme.blue,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
            ),
          ),
        ),
      ],
    ],
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'active' || 'completed' || 'good' || 'checked_in' => AppTheme.green,
      'expired' || 'failed' || 'poor' || 'suspended' => AppTheme.red,
      'pending' || 'fair' || 'maintenance' => AppTheme.amber,
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            titleCase(status),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class PersonAvatar extends StatelessWidget {
  const PersonAvatar(this.name, {super.key, this.size = 40});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) {
    const colors = [
      AppTheme.blue,
      Color(0xFF9334E6),
      AppTheme.green,
      Color(0xFFB06000),
      Color(0xFF00838F),
    ];
    final color =
        colors[name.codeUnits.fold(0, (a, b) => a + b) % colors.length];
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color.withValues(alpha: .12),
      child: Text(
        initials(name),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: size * .32,
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.action,
    this.padding = 22,
  });
  final Widget child;
  final String? title, subtitle;
  final Widget? action;
  final double padding;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Card(
      child: Padding(
        padding: EdgeInsets.all(
          constraints.maxWidth < 400
              ? padding.clamp(0, 18).toDouble()
              : padding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Flex(
                direction:
                    constraints.maxWidth < 400 ||
                        MediaQuery.textScalerOf(context).scale(14) >= 22
                    ? Axis.vertical
                    : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex:
                        constraints.maxWidth < 400 ||
                            MediaQuery.textScalerOf(context).scale(14) >= 22
                        ? 0
                        : 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  ?action,
                ],
              ),
              const SizedBox(height: 22),
            ],
            child,
          ],
        ),
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });
  final String title, message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.blue.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(icon, color: AppTheme.blue, size: 32),
          ),
          const SizedBox(height: 18),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });
  final String title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final text = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 7),
          Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      );
      if (constraints.maxWidth < 650) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            text,
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: text),
          if (action != null) ...[const SizedBox(width: 24), action!],
        ],
      );
    },
  );
}

void toast(BuildContext context, String message) {
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String message, {
  String label = 'Confirm',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(label),
          ),
        ],
      ),
    ) ??
    false;
String friendlyError(Object e) => e is StateError
    ? e.message
    : e is FormatException
    ? e.message
    : 'Could not save your changes. Please check the fields and try again.';
