import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/services.dart' show AssetBundle, ByteData, rootBundle;

import '../../data/models/enums.dart';

/// The read-along script for one lesson, compiled by `npm run build:texts`
/// and bundled under `assets/texts/<lessonId>.json.gz`.
///
/// Deliberately not in the catalog or drift: ~10 MB of prose has no business in
/// a snapshot that gets re-imported on every version bump, and the player only
/// ever needs the lesson in front of it.
class LessonText {
  LessonText({
    required this.lessonId,
    required this.kind,
    required this.sections,
    this.measured = 0,
  }) : sentences = [for (final section in sections) ...section.sentences];

  final String lessonId;
  final LessonTextKind kind;
  final List<TextSection> sections;

  /// How many sentence times were measured by forced alignment rather than
  /// interpolated between markers.
  final int measured;

  /// True when the highlight is tracking measured times, so the UI can drop
  /// the «تقريبية» hedge.
  bool get isMeasured => measured > 0 && measured >= sentences.length ~/ 2;

  /// Every sentence in playback order — what the highlight indexes into.
  final List<TextSentence> sentences;

  /// Index of the sentence being spoken at [position], or -1 before the first.
  ///
  /// Transcript sentences carry an estimated time each; matn sentences carry
  /// none (the speech isn't in that text) and fall back to their section's
  /// real marker timestamp, so the highlight spans the whole passage.
  int indexAt(Duration position) {
    final seconds = position.inSeconds;
    var found = -1;
    // A few hundred entries, already ordered: a scan is simpler than a binary
    // search over two different time sources, and costs nothing at this size.
    for (var i = 0; i < sentences.length; i++) {
      final t = sentences[i].t ?? sentences[i].sectionStart;
      if (t == null || t > seconds) break;
      found = i;
    }
    return found;
  }

  /// The section [index] belongs to, for the matn case where the highlight
  /// spans a whole passage rather than one sentence.
  int sectionOf(int index) {
    if (index < 0) return -1;
    var seen = 0;
    for (var s = 0; s < sections.length; s++) {
      seen += sections[s].sentences.length;
      if (index < seen) return s;
    }
    return sections.length - 1;
  }

  static LessonText fromJson(Map<String, dynamic> json) {
    final kind = LessonTextKind.fromJson(json['kind'] as String?);
    final sections = <TextSection>[];
    for (final raw in (json['sections'] as List<dynamic>? ?? const [])) {
      final map = raw as Map<String, dynamic>;
      final start = (map['start'] as num?)?.toInt();
      sections.add(
        TextSection(
          start: start,
          title: map['title'] as String? ?? '',
          sentences: [
            for (final s in (map['sentences'] as List<dynamic>? ?? const []))
              TextSentence(
                t: ((s as Map<String, dynamic>)['t'] as num?)?.toInt(),
                text: s['s'] as String? ?? '',
                sectionStart: start,
              ),
          ],
        ),
      );
    }
    return LessonText(
      lessonId: json['lesson'] as String? ?? '',
      kind: kind ?? LessonTextKind.matn,
      sections: sections,
      measured: (json['measured'] as num?)?.toInt() ?? 0,
    );
  }
}

class TextSection {
  const TextSection({
    required this.start,
    required this.title,
    required this.sentences,
  });

  /// Real marker timestamp in seconds — the point the highlight snaps to.
  final int? start;
  final String title;
  final List<TextSentence> sentences;
}

class TextSentence {
  const TextSentence({
    required this.t,
    required this.text,
    required this.sectionStart,
  });

  /// Estimated start in seconds; null on matn text.
  final int? t;
  final String text;
  final int? sectionStart;
}

/// Loads and caches read-along scripts from the asset bundle.
class LessonTextRepository {
  LessonTextRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final Map<String, LessonText> _cache = {};

  static String assetPath(String lessonId) => 'assets/texts/$lessonId.json.gz';

  Future<LessonText?> load(String lessonId) async {
    final cached = _cache[lessonId];
    if (cached != null) return cached;

    final ByteData data;
    try {
      data = await _bundle.load(assetPath(lessonId));
    } catch (_) {
      // The catalog's text_kind should keep us from asking for a script that
      // isn't bundled, but a stale catalog shouldn't crash the player.
      return null;
    }

    final json = jsonDecode(
      utf8.decode(gzip.decode(data.buffer.asUint8List())),
    );
    final text = LessonText.fromJson(json as Map<String, dynamic>);
    // A handful of lessons at a time — the player only walks a series.
    if (_cache.length >= 8) _cache.remove(_cache.keys.first);
    _cache[lessonId] = text;
    return text;
  }
}
