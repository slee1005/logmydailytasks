import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

ThemeData worklogTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colors =
      ColorScheme.fromSeed(
        seedColor: const Color(0xffa33b58),
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xfff4acc1) : const Color(0xffa23855),
        onPrimary: dark ? const Color(0xff491128) : Colors.white,
        surface: dark ? const Color(0xff24282d) : Colors.white,
        surfaceContainerLow: dark
            ? const Color(0xff191d21)
            : const Color(0xffeff2f2),
        surfaceContainerHigh: dark
            ? const Color(0xff30363c)
            : const Color(0xffedf1f2),
        onSurface: dark ? const Color(0xffedf1f3) : const Color(0xff18242a),
        onSurfaceVariant: dark
            ? const Color(0xffc7ced3)
            : const Color(0xff44545d),
        tertiary: dark ? const Color(0xff9ac7d1) : const Color(0xff356171),
      );
  final base = ThemeData(
    colorScheme: colors,
    scaffoldBackgroundColor: colors.surfaceContainerLow,
    dividerColor: colors.outlineVariant.withAlpha(100),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceContainerHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -.5,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -.35,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class AppContainer extends StatelessWidget {
  const AppContainer({
    super.key,
    required this.title,
    required this.body,
    this.leadingIcon,
    this.actions = const [],
  });

  final String title;
  final Widget body;
  final IconData? leadingIcon;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 640;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppContentFrame(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 10),
                child: TopNavigationCard(
                  title: title,
                  leadingIcon: leadingIcon,
                  actions: actions,
                  inlineActions: wide,
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class AppContentFrame extends StatelessWidget {
  const AppContentFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width >= 640 ? 24 : 16,
        ),
        child: child,
      ),
    ),
  );
}

class AppContent extends StatelessWidget {
  const AppContent({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    primary: true,
    padding: const EdgeInsets.only(top: 6, bottom: 24),
    children: [
      AppContentFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, section) in children.indexed) ...[
              if (index > 0) const SizedBox(height: 16),
              section,
            ],
          ],
        ),
      ),
    ],
  );
}

class TopNavigationCard extends StatelessWidget {
  const TopNavigationCard({
    super.key,
    required this.title,
    required this.leadingIcon,
    required this.actions,
    required this.inlineActions,
  });

  final String title;
  final IconData? leadingIcon;
  final List<Widget> actions;
  final bool inlineActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionRow = Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: actions,
    );
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (leadingIcon case final icon?)
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  foregroundColor: theme.colorScheme.tertiary,
                  child: Icon(icon, size: 22),
                )
              else
                WorklogIconButton(
                  icon: Icons.arrow_back,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.headlineSmall),
                ),
              ),
              if (inlineActions && actions.isNotEmpty)
                Flexible(
                  flex: 2,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: actionRow,
                  ),
                ),
            ],
          ),
          if (!inlineActions && actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(alignment: AlignmentDirectional.centerEnd, child: actionRow),
          ],
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final String? title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 1,
    shadowColor: Theme.of(context).colorScheme.shadow.withAlpha(40),
    surfaceTintColor: Colors.transparent,
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: padding,
      child: title == null
          ? child
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title!,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 12),
                child,
              ],
            ),
    ),
  );
}

class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    if (icon == null) {
      return FilledButton(onPressed: onPressed, child: Text(label));
    }
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      label: Text(label),
    );
  }
}

class WorklogIconButton extends StatelessWidget {
  const WorklogIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    icon: Icon(icon, size: 22),
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      foregroundColor: Theme.of(context).colorScheme.tertiary,
      minimumSize: const Size.square(44),
    ),
  );
}
