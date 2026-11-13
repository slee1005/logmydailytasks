class ActivitySuggestion {
  ActivitySuggestion(this.title, this.uses, this.latest)
    : normalized = title.toLowerCase(),
      initials = koreanInitials(title);

  final String title;
  final int uses;
  final int latest;
  final String normalized;
  final String initials;
}

const _initials = 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ';

String koreanInitials(String text) => String.fromCharCodes(
  text.runes.map((unit) {
    if (unit >= 0xac00 && unit <= 0xd7a3) {
      return _initials.codeUnitAt((unit - 0xac00) ~/ 588);
    }
    if (unit >= 0x1100 && unit <= 0x1112) {
      return _initials.codeUnitAt(unit - 0x1100);
    }
    return unit;
  }),
);

List<ActivitySuggestion> rankActivities(
  Iterable<ActivitySuggestion> activities,
  String input,
) {
  final query = input.trim().toLowerCase();
  if (query.isEmpty) return [];
  final initials = koreanInitials(query).replaceAll(RegExp(r'\s'), '');
  final initialsOnly = query
      .replaceAll(RegExp(r'\s'), '')
      .runes
      .every(
        (unit) =>
            (unit >= 0x1100 && unit <= 0x1112) ||
            _initials.contains(String.fromCharCode(unit)),
      );
  final matches = <({int tier, ActivitySuggestion item})>[];
  for (final item in activities) {
    if (item.normalized
            .split(RegExp(r'\s+'))
            .any((word) => word.startsWith(query)) ||
        item.normalized.startsWith(query)) {
      matches.add((tier: 0, item: item));
    } else if (item.normalized.contains(query)) {
      matches.add((tier: 1, item: item));
    } else if (initialsOnly &&
        item.initials.replaceAll(RegExp(r'\s'), '').contains(initials)) {
      matches.add((tier: 2, item: item));
    }
  }
  matches.sort((a, b) {
    final tier = a.tier.compareTo(b.tier);
    if (tier != 0) return tier;
    final uses = b.item.uses.compareTo(a.item.uses);
    if (uses != 0) return uses;
    final latest = b.item.latest.compareTo(a.item.latest);
    return latest != 0 ? latest : a.item.title.compareTo(b.item.title);
  });
  return matches.take(6).map((match) => match.item).toList();
}
