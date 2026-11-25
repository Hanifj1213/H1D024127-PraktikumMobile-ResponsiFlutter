// Tetap memakai facade Flutter agar proyek juga bisa dibuka di SDK sebelum 3.47.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

const ink = Color(0xFF0E2634);
const muted = Color(0xFF476273);
const teal = Color(0xFF086B70);
const mint = Color(0xFFD8F3EB);
const paper = Color(0xFFF3F8F8);
const line = Color(0xFFDCE8E9);

ThemeData langitTheme() {
  final colors = ColorScheme.fromSeed(seedColor: teal).copyWith(
    primary: teal,
    onPrimary: Colors.white,
    primaryContainer: mint,
    onPrimaryContainer: ink,
    surface: Colors.white,
    onSurface: ink,
    onSurfaceVariant: muted,
    outlineVariant: line,
  );
  final theme = ThemeData(useMaterial3: true, colorScheme: colors);
  return theme.copyWith(
    scaffoldBackgroundColor: paper,
    textTheme: theme.textTheme
        .copyWith(
          headlineLarge: const TextStyle(
            fontSize: 36,
            height: 1.09,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.6,
          ),
          headlineSmall: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            letterSpacing: -.6,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: const TextStyle(fontSize: 14, height: 1.45),
          labelSmall: const TextStyle(
            fontSize: 10,
            letterSpacing: 1.45,
            fontWeight: FontWeight.w800,
          ),
        )
        .apply(bodyColor: ink, displayColor: ink),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 17, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: teal, width: 1.6),
      ),
    ),
  );
}

class Overline extends StatelessWidget {
  const Overline(this.text, {super.key, this.color = teal});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
  );
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(21),
      side: const BorderSide(color: line),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

class StatusPanel extends StatelessWidget {
  const StatusPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
    this.loading = false,
  });
  final IconData icon;
  final String title, message;
  final VoidCallback? onRetry;
  final bool loading;
  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
    child: SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
          else
            CircleAvatar(
              backgroundColor: mint,
              foregroundColor: teal,
              radius: 25,
              child: Icon(icon),
            ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, height: 1.45),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
            ),
          ],
        ],
      ),
    ),
  );
}

class BrandBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandBar({super.key, required this.actions, this.back});
  final List<Widget> actions;
  final VoidCallback? back;
  @override
  Size get preferredSize => const Size.fromHeight(68);
  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    toolbarHeight: 68,
    centerTitle: false,
    titleSpacing: 18,
    backgroundColor: paper,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    leading: back == null
        ? null
        : IconButton(
            tooltip: 'Kembali',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: back,
          ),
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: teal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.cloud_queue_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 9),
        const Flexible(
          child: Text(
            'LangitKota',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: -.7,
              fontSize: 22,
            ),
          ),
        ),
      ],
    ),
    actions: [...actions, const SizedBox(width: 12)],
  );
}
