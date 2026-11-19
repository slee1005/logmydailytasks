import 'dart:ui' show PointerDeviceKind;

import 'package:material_ui/material_ui.dart';

import '../../core/local_time.dart';
import '../../l10n/generated/app_localizations.dart';
import 'worklog_layout.dart';

class DateSwipeContainer extends StatefulWidget {
  const DateSwipeContainer({
    super.key,
    required this.date,
    required this.today,
    required this.onDateChanged,
    required this.builder,
  });

  static final firstDate = DateTime(1900);
  static final lastDate = DateTime(2200, 12, 31);

  final DateTime date;
  final DateTime today;
  final ValueChanged<DateTime> onDateChanged;
  final Widget Function(BuildContext context, DateTime date) builder;

  @override
  State<DateSwipeContainer> createState() => _DateSwipeContainerState();
}

class _DateSwipeContainerState extends State<DateSwipeContainer> {
  static final _pageCount = _pageOf(DateSwipeContainer.lastDate) + 1;
  late final _controller = PageController(initialPage: _pageOf(widget.date));

  static int _pageOf(DateTime day) => DateTime.utc(
    day.year,
    day.month,
    day.day,
  ).difference(DateTime.utc(DateSwipeContainer.firstDate.year)).inDays;

  @override
  void didUpdateWidget(covariant DateSwipeContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date == widget.date) return;
    final page = _pageOf(widget.date);
    if (_controller.hasClients && _controller.page?.round() != page) {
      _controller.jumpToPage(page);
    }
  }

  void _shift(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final date = widget.date;
    final currentPage = _pageOf(date);
    final theme = Theme.of(context);
    final scroll = ScrollConfiguration.of(context);
    return SectionCard(
      child: Column(
        children: [
          Row(
            children: [
              WorklogIconButton(
                icon: Icons.chevron_left,
                tooltip: strings.previousDay,
                onPressed: currentPage > 0
                    ? () => _shift(currentPage - 1)
                    : null,
              ),
              Expanded(
                child: Column(
                  children: [
                    if (date == widget.today)
                      Text(
                        strings.today,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text(
                        MaterialLocalizations.of(context).formatFullDate(date),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    if (date != widget.today)
                      TextButton(
                        onPressed: () => widget.onDateChanged(widget.today),
                        child: Text(strings.today),
                      ),
                  ],
                ),
              ),
              WorklogIconButton(
                icon: Icons.chevron_right,
                tooltip: strings.nextDay,
                onPressed: currentPage < _pageCount - 1
                    ? () => _shift(currentPage + 1)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: (MediaQuery.sizeOf(context).height * .32).clamp(
              184.0,
              300.0,
            ),
            child: ScrollConfiguration(
              behavior: scroll.copyWith(
                dragDevices: {...scroll.dragDevices, PointerDeviceKind.mouse},
              ),
              child: PageView.builder(
                controller: _controller,
                itemCount: _pageCount,
                onPageChanged: (page) => widget.onDateChanged(
                  dayAtOffset(DateSwipeContainer.firstDate, page),
                ),
                itemBuilder: (context, page) => widget.builder(
                  context,
                  dayAtOffset(DateSwipeContainer.firstDate, page),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
