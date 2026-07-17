// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CatalogData _$CatalogDataFromJson(Map<String, dynamic> json) => _CatalogData(
  version: (json['version'] as num).toInt(),
  generatedAt: json['generated_at'] == null
      ? null
      : DateTime.parse(json['generated_at'] as String),
  scholars:
      (json['scholars'] as List<dynamic>?)
          ?.map((e) => CatalogScholar.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  sciences:
      (json['sciences'] as List<dynamic>?)
          ?.map((e) => CatalogScience.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  series:
      (json['series'] as List<dynamic>?)
          ?.map((e) => CatalogSeries.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  journeys:
      (json['journeys'] as List<dynamic>?)
          ?.map((e) => CatalogJourney.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$CatalogDataToJson(_CatalogData instance) =>
    <String, dynamic>{
      'version': instance.version,
      'generated_at': instance.generatedAt?.toIso8601String(),
      'scholars': instance.scholars.map((e) => e.toJson()).toList(),
      'sciences': instance.sciences.map((e) => e.toJson()).toList(),
      'series': instance.series.map((e) => e.toJson()).toList(),
      'journeys': instance.journeys.map((e) => e.toJson()).toList(),
    };

_CatalogScholar _$CatalogScholarFromJson(Map<String, dynamic> json) =>
    _CatalogScholar(
      slug: json['slug'] as String,
      nameAr: json['name_ar'] as String,
      foundationAr: json['foundation_ar'] as String,
      website: json['website'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CatalogScholarToJson(_CatalogScholar instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'name_ar': instance.nameAr,
      'foundation_ar': instance.foundationAr,
      'website': instance.website,
      'sort_order': instance.sortOrder,
    };

_CatalogScience _$CatalogScienceFromJson(Map<String, dynamic> json) =>
    _CatalogScience(
      slug: json['slug'] as String,
      nameAr: json['name_ar'] as String,
      descriptionAr: json['description_ar'] as String?,
      icon: json['icon'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CatalogScienceToJson(_CatalogScience instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'name_ar': instance.nameAr,
      'description_ar': instance.descriptionAr,
      'icon': instance.icon,
      'sort_order': instance.sortOrder,
    };

_CatalogSeries _$CatalogSeriesFromJson(Map<String, dynamic> json) =>
    _CatalogSeries(
      slug: json['slug'] as String,
      science: json['science'] as String,
      scholar: json['scholar'] as String? ?? 'ibn-uthaymeen',
      titleAr: json['title_ar'] as String,
      descriptionAr: json['description_ar'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      level: $enumDecodeNullable(_$JourneyLevelEnumMap, json['level']),
      media:
          $enumDecodeNullable(_$LessonMediaEnumMap, json['media']) ??
          LessonMedia.video,
      companionOf: json['companion_of'] as String?,
      companionSlug: json['companion_slug'] as String?,
      lessons:
          (json['lessons'] as List<dynamic>?)
              ?.map((e) => CatalogLesson.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CatalogSeriesToJson(_CatalogSeries instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'science': instance.science,
      'scholar': instance.scholar,
      'title_ar': instance.titleAr,
      'description_ar': instance.descriptionAr,
      'thumbnail_url': instance.thumbnailUrl,
      'level': _$JourneyLevelEnumMap[instance.level],
      'media': _$LessonMediaEnumMap[instance.media]!,
      'companion_of': instance.companionOf,
      'companion_slug': instance.companionSlug,
      'lessons': instance.lessons.map((e) => e.toJson()).toList(),
    };

const _$JourneyLevelEnumMap = {
  JourneyLevel.beginner: 'beginner',
  JourneyLevel.intermediate: 'intermediate',
  JourneyLevel.advanced: 'advanced',
};

const _$LessonMediaEnumMap = {
  LessonMedia.video: 'video',
  LessonMedia.audio: 'audio',
};

_CatalogLesson _$CatalogLessonFromJson(Map<String, dynamic> json) =>
    _CatalogLesson(
      youtubeVideoId: json['youtube_video_id'] as String,
      position: (json['position'] as num).toInt(),
      titleAr: json['title_ar'] as String,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.parse(json['published_at'] as String),
      status:
          $enumDecodeNullable(_$LessonStatusEnumMap, json['status']) ??
          LessonStatus.active,
      media:
          $enumDecodeNullable(_$LessonMediaEnumMap, json['media']) ??
          LessonMedia.video,
      audioUrl: json['audio_url'] as String?,
      chapters:
          (json['chapters'] as List<dynamic>?)
              ?.map((e) => CatalogChapter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CatalogLessonToJson(_CatalogLesson instance) =>
    <String, dynamic>{
      'youtube_video_id': instance.youtubeVideoId,
      'position': instance.position,
      'title_ar': instance.titleAr,
      'duration_seconds': instance.durationSeconds,
      'published_at': instance.publishedAt?.toIso8601String(),
      'status': _$LessonStatusEnumMap[instance.status]!,
      'media': _$LessonMediaEnumMap[instance.media]!,
      'audio_url': instance.audioUrl,
      'chapters': instance.chapters.map((e) => e.toJson()).toList(),
    };

const _$LessonStatusEnumMap = {
  LessonStatus.active: 'active',
  LessonStatus.hidden: 'hidden',
  LessonStatus.unavailable: 'unavailable',
};

_CatalogChapter _$CatalogChapterFromJson(Map<String, dynamic> json) =>
    _CatalogChapter(
      startSeconds: (json['start_seconds'] as num?)?.toInt(),
      title: json['title'] as String,
      body: json['body'] as String? ?? '',
    );

Map<String, dynamic> _$CatalogChapterToJson(_CatalogChapter instance) =>
    <String, dynamic>{
      'start_seconds': instance.startSeconds,
      'title': instance.title,
      'body': instance.body,
    };

_CatalogJourney _$CatalogJourneyFromJson(Map<String, dynamic> json) =>
    _CatalogJourney(
      slug: json['slug'] as String,
      titleAr: json['title_ar'] as String,
      descriptionAr: json['description_ar'] as String?,
      level: $enumDecode(_$JourneyLevelEnumMap, json['level']),
      science: json['science'] as String?,
      coverUrl: json['cover_url'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      stages:
          (json['stages'] as List<dynamic>?)
              ?.map((e) => CatalogStage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CatalogJourneyToJson(_CatalogJourney instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'title_ar': instance.titleAr,
      'description_ar': instance.descriptionAr,
      'level': _$JourneyLevelEnumMap[instance.level]!,
      'science': instance.science,
      'cover_url': instance.coverUrl,
      'sort_order': instance.sortOrder,
      'stages': instance.stages.map((e) => e.toJson()).toList(),
    };

_CatalogStage _$CatalogStageFromJson(Map<String, dynamic> json) =>
    _CatalogStage(
      titleAr: json['title_ar'] as String,
      descriptionAr: json['description_ar'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => CatalogStageItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CatalogStageToJson(_CatalogStage instance) =>
    <String, dynamic>{
      'title_ar': instance.titleAr,
      'description_ar': instance.descriptionAr,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

_CatalogStageItem _$CatalogStageItemFromJson(Map<String, dynamic> json) =>
    _CatalogStageItem(
      type: json['type'] as String? ?? 'series',
      series: json['series'] as String,
    );

Map<String, dynamic> _$CatalogStageItemToJson(_CatalogStageItem instance) =>
    <String, dynamic>{'type': instance.type, 'series': instance.series};
