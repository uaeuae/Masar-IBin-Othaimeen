import 'package:flutter/foundation.dart';

/// Where reports go. A dedicated address on the owner's own domain rather than
/// a personal mailbox: this string ships inside every installed build and sits
/// in a public repo, so it needs to be one that can be filtered, forwarded, or
/// retired without cutting anyone off.
const kFeedbackEmail = 'm@pixeldrive.ae';

/// The app's own version, in one place. Settings used to print «Masar v1.0.0»
/// while pubspec said 0.1.0+1 — a report carrying the wrong version is worse
/// than one carrying none, since it sends you looking at the wrong build.
const kAppVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0');

/// What the reader is telling us.
enum ReportKind {
  /// Content that is wrong — a mis-attributed lesson, a bad title, a text that
  /// does not match the audio. First in the list on purpose: in a da'wah app
  /// this is the category that matters most and the one a listener is most
  /// likely to notice.
  wrongInfo,

  /// The app misbehaving.
  bug,

  /// Something they wish it did.
  idea;

  String get labelAr => switch (this) {
    ReportKind.wrongInfo => 'خطأ في المعلومات',
    ReportKind.bug => 'مشكلة تقنية',
    ReportKind.idea => 'اقتراح',
  };

  /// Shown under the field, so the reader knows what is useful to write.
  String get hintAr => switch (this) {
    ReportKind.wrongInfo =>
      'ما الخطأ، وما الصواب إن عرفته؟ اذكر الموضع إن أمكن.',
    ReportKind.bug => 'ماذا فعلت، وماذا حدث بدل المتوقع؟',
    ReportKind.idea => 'ما الذي تتمنى أن يضيفه التطبيق؟',
  };
}

/// Everything the app knows about where the reader was. Assembled explicitly
/// rather than collected: the app promises «بلا جمع بيانات», so this is shown
/// on screen before it is sent, and it goes out through the reader's own mail
/// app — nothing leaves the device unless they press send in it.
@immutable
class ReportContext {
  const ReportContext({
    required this.appVersion,
    required this.catalogVersion,
    required this.platform,
    this.lessonId,
    this.lessonTitle,
    this.seriesTitle,
    this.scholarName,
    this.positionSeconds,
  });

  final String appVersion;
  final int catalogVersion;
  final String platform;

  /// Set when the report was opened from a lesson. «خطأ في المعلومات» is
  /// almost useless without it — «هناك خطأ» with no lesson names nothing.
  final String? lessonId;
  final String? lessonTitle;
  final String? seriesTitle;
  final String? scholarName;
  final int? positionSeconds;

  bool get hasLesson => lessonId != null;

  /// The lines shown to the reader and appended to the mail, in that order.
  List<(String, String)> get lines => [
    if (lessonTitle != null) ('الدرس', lessonTitle!),
    if (seriesTitle != null) ('السلسلة', seriesTitle!),
    if (scholarName != null) ('الشيخ', scholarName!),
    if (positionSeconds != null) ('الموضع', _clock(positionSeconds!)),
    if (lessonId != null) ('المعرّف', lessonId!),
    ('إصدار التطبيق', appVersion),
    ('إصدار الفهرس', '$catalogVersion'),
    ('النظام', platform),
  ];

  static String _clock(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }
}

/// Subject line: the kind, plus the lesson when there is one, so reports sort
/// themselves in an inbox.
String reportSubject(ReportKind kind, ReportContext context) {
  final where = context.lessonTitle;
  return where == null
      ? '[مسار] ${kind.labelAr}'
      : '[مسار] ${kind.labelAr} — $where';
}

String reportBody(ReportKind kind, ReportContext context, String message) {
  final buffer = StringBuffer()
    ..writeln(message.trim())
    ..writeln()
    ..writeln('—————')
    ..writeln('نوع البلاغ: ${kind.labelAr}');
  for (final (label, value) in context.lines) {
    buffer.writeln('$label: $value');
  }
  return buffer.toString();
}

/// A `mailto:` link, because the app has no backend and collects nothing.
/// Handing the report to the reader's own mail client keeps that promise
/// literally true: the app never transmits anything, and they see and control
/// exactly what is sent.
Uri reportMailto(ReportKind kind, ReportContext context, String message) {
  final subject = Uri.encodeComponent(reportSubject(kind, context));
  final body = Uri.encodeComponent(reportBody(kind, context, message));
  return Uri.parse('mailto:$kFeedbackEmail?subject=$subject&body=$body');
}
