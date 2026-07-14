import 'package:intl/intl.dart';

/// Converts Western digits to Arabic-Indic digits (١٢٣).
String arabicDigits(Object value) {
  const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  var text = value.toString();
  for (var i = 0; i < western.length; i++) {
    text = text.replaceAll(western[i], eastern[i]);
  }
  return text;
}

/// "لا دروس" / "درس واحد" / "درسان" / "٥ دروس" / "١٥ درسًا" / "١٠٠ درس"
String lessonCountLabel(int count) {
  final n = arabicDigits(count);
  return Intl.pluralLogic(
    count,
    locale: 'ar',
    zero: 'لا دروس',
    one: 'درس واحد',
    two: 'درسان',
    few: '$n دروس',
    many: '$n درسًا',
    other: '$n درس',
  );
}

/// "مرحلة واحدة" / "مرحلتان" / "٣ مراحل" / "١١ مرحلة"
String stageCountLabel(int count) {
  final n = arabicDigits(count);
  return Intl.pluralLogic(
    count,
    locale: 'ar',
    zero: 'لا مراحل',
    one: 'مرحلة واحدة',
    two: 'مرحلتان',
    few: '$n مراحل',
    many: '$n مرحلة',
    other: '$n مرحلة',
  );
}

/// "حلقة واحدة" / "حلقتان" / "٣ حلقات" / "٣٤٨ حلقة" — the design's series-card counts.
String episodeCountLabel(int count) {
  final n = arabicDigits(count);
  return Intl.pluralLogic(
    count,
    locale: 'ar',
    zero: 'لا حلقات',
    one: 'حلقة واحدة',
    two: 'حلقتان',
    few: '$n حلقات',
    many: '$n حلقة',
    other: '$n حلقة',
  );
}

/// "سلسلة واحدة" / "سلسلتان" / "٣ سلاسل" / "١١ سلسلة"
String seriesCountLabel(int count) {
  final n = arabicDigits(count);
  return Intl.pluralLogic(
    count,
    locale: 'ar',
    zero: 'لا سلاسل بعد',
    one: 'سلسلة واحدة',
    two: 'سلسلتان',
    few: '$n سلاسل',
    many: '$n سلسلة',
    other: '$n سلسلة',
  );
}

/// Human duration for lesson/series lengths: "٤٥ دقيقة", "ساعة و١٠ دقائق", "٣ ساعات".
String durationLabel(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  String hoursPart() => Intl.pluralLogic(
    hours,
    locale: 'ar',
    one: 'ساعة',
    two: 'ساعتان',
    few: '${arabicDigits(hours)} ساعات',
    many: '${arabicDigits(hours)} ساعة',
    other: '${arabicDigits(hours)} ساعة',
  );

  String minutesPart() => Intl.pluralLogic(
    minutes,
    locale: 'ar',
    one: 'دقيقة',
    two: 'دقيقتان',
    few: '${arabicDigits(minutes)} دقائق',
    many: '${arabicDigits(minutes)} دقيقة',
    other: '${arabicDigits(minutes)} دقيقة',
  );

  if (hours == 0 && minutes == 0) return 'أقل من دقيقة';
  if (hours == 0) return minutesPart();
  if (minutes == 0) return hoursPart();
  return '${hoursPart()} و${minutesPart()}';
}

/// Clock-style position, e.g. "٤٥:٠٧" or "١:٠٢:٣٠" for the player.
String clockLabel(Duration position) {
  final h = position.inHours;
  final m = position.inMinutes.remainder(60);
  final s = position.inSeconds.remainder(60);
  String two(int v) => v.toString().padLeft(2, '0');
  final text = h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
  return arabicDigits(text);
}

/// "٪٦٥" style percent for progress labels.
String percentLabel(double progress) {
  final pct = (progress.clamp(0.0, 1.0) * 100).round();
  return '٪${arabicDigits(pct)}';
}
