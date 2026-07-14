import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'catalog.freezed.dart';
part 'catalog.g.dart';

/// The compiled content snapshot the app consumes. Produced by the ingestion
/// pipeline (`publish:catalog`); a copy is bundled in the app for offline
/// first-run. Only active series and published journeys are ever exported,
/// so those carry no status field — lessons do, because removed YouTube
/// videos ship as `unavailable` rather than disappearing.
@freezed
abstract class CatalogData with _$CatalogData {
  const factory CatalogData({
    required int version,
    DateTime? generatedAt,
    @Default([]) List<CatalogScience> sciences,
    @Default([]) List<CatalogSeries> series,
    @Default([]) List<CatalogJourney> journeys,
  }) = _CatalogData;

  factory CatalogData.fromJson(Map<String, dynamic> json) =>
      _$CatalogDataFromJson(json);
}

@freezed
abstract class CatalogScience with _$CatalogScience {
  const factory CatalogScience({
    required String slug,
    required String nameAr,
    String? descriptionAr,
    String? icon,
    @Default(0) int sortOrder,
  }) = _CatalogScience;

  factory CatalogScience.fromJson(Map<String, dynamic> json) =>
      _$CatalogScienceFromJson(json);
}

@freezed
abstract class CatalogSeries with _$CatalogSeries {
  const factory CatalogSeries({
    required String slug,
    required String science,
    required String titleAr,
    String? descriptionAr,
    String? thumbnailUrl,
    JourneyLevel? level,
    @Default([]) List<CatalogLesson> lessons,
  }) = _CatalogSeries;

  factory CatalogSeries.fromJson(Map<String, dynamic> json) =>
      _$CatalogSeriesFromJson(json);
}

@freezed
abstract class CatalogLesson with _$CatalogLesson {
  const factory CatalogLesson({
    required String youtubeVideoId,
    required int position,
    required String titleAr,
    int? durationSeconds,
    DateTime? publishedAt,
    @Default(LessonStatus.active) LessonStatus status,
  }) = _CatalogLesson;

  factory CatalogLesson.fromJson(Map<String, dynamic> json) =>
      _$CatalogLessonFromJson(json);
}

@freezed
abstract class CatalogJourney with _$CatalogJourney {
  const factory CatalogJourney({
    required String slug,
    required String titleAr,
    String? descriptionAr,
    required JourneyLevel level,
    String? science,
    String? coverUrl,
    @Default(0) int sortOrder,
    @Default([]) List<CatalogStage> stages,
  }) = _CatalogJourney;

  factory CatalogJourney.fromJson(Map<String, dynamic> json) =>
      _$CatalogJourneyFromJson(json);
}

@freezed
abstract class CatalogStage with _$CatalogStage {
  const factory CatalogStage({
    required String titleAr,
    String? descriptionAr,
    @Default([]) List<CatalogStageItem> items,
  }) = _CatalogStage;

  factory CatalogStage.fromJson(Map<String, dynamic> json) =>
      _$CatalogStageFromJson(json);
}

@freezed
abstract class CatalogStageItem with _$CatalogStageItem {
  const factory CatalogStageItem({
    @Default('series') String type,
    required String series,
  }) = _CatalogStageItem;

  factory CatalogStageItem.fromJson(Map<String, dynamic> json) =>
      _$CatalogStageItemFromJson(json);
}
