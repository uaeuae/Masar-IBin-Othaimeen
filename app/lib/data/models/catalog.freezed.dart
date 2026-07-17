// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CatalogData {

 int get version; DateTime? get generatedAt; List<CatalogScience> get sciences; List<CatalogSeries> get series; List<CatalogJourney> get journeys;
/// Create a copy of CatalogData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogDataCopyWith<CatalogData> get copyWith => _$CatalogDataCopyWithImpl<CatalogData>(this as CatalogData, _$identity);

  /// Serializes this CatalogData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogData&&(identical(other.version, version) || other.version == version)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&const DeepCollectionEquality().equals(other.sciences, sciences)&&const DeepCollectionEquality().equals(other.series, series)&&const DeepCollectionEquality().equals(other.journeys, journeys));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,generatedAt,const DeepCollectionEquality().hash(sciences),const DeepCollectionEquality().hash(series),const DeepCollectionEquality().hash(journeys));

@override
String toString() {
  return 'CatalogData(version: $version, generatedAt: $generatedAt, sciences: $sciences, series: $series, journeys: $journeys)';
}


}

/// @nodoc
abstract mixin class $CatalogDataCopyWith<$Res>  {
  factory $CatalogDataCopyWith(CatalogData value, $Res Function(CatalogData) _then) = _$CatalogDataCopyWithImpl;
@useResult
$Res call({
 int version, DateTime? generatedAt, List<CatalogScience> sciences, List<CatalogSeries> series, List<CatalogJourney> journeys
});




}
/// @nodoc
class _$CatalogDataCopyWithImpl<$Res>
    implements $CatalogDataCopyWith<$Res> {
  _$CatalogDataCopyWithImpl(this._self, this._then);

  final CatalogData _self;
  final $Res Function(CatalogData) _then;

/// Create a copy of CatalogData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? generatedAt = freezed,Object? sciences = null,Object? series = null,Object? journeys = null,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,generatedAt: freezed == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,sciences: null == sciences ? _self.sciences : sciences // ignore: cast_nullable_to_non_nullable
as List<CatalogScience>,series: null == series ? _self.series : series // ignore: cast_nullable_to_non_nullable
as List<CatalogSeries>,journeys: null == journeys ? _self.journeys : journeys // ignore: cast_nullable_to_non_nullable
as List<CatalogJourney>,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogData].
extension CatalogDataPatterns on CatalogData {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogData() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogData value)  $default,){
final _that = this;
switch (_that) {
case _CatalogData():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogData value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogData() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int version,  DateTime? generatedAt,  List<CatalogScience> sciences,  List<CatalogSeries> series,  List<CatalogJourney> journeys)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogData() when $default != null:
return $default(_that.version,_that.generatedAt,_that.sciences,_that.series,_that.journeys);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int version,  DateTime? generatedAt,  List<CatalogScience> sciences,  List<CatalogSeries> series,  List<CatalogJourney> journeys)  $default,) {final _that = this;
switch (_that) {
case _CatalogData():
return $default(_that.version,_that.generatedAt,_that.sciences,_that.series,_that.journeys);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int version,  DateTime? generatedAt,  List<CatalogScience> sciences,  List<CatalogSeries> series,  List<CatalogJourney> journeys)?  $default,) {final _that = this;
switch (_that) {
case _CatalogData() when $default != null:
return $default(_that.version,_that.generatedAt,_that.sciences,_that.series,_that.journeys);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogData implements CatalogData {
  const _CatalogData({required this.version, this.generatedAt, final  List<CatalogScience> sciences = const [], final  List<CatalogSeries> series = const [], final  List<CatalogJourney> journeys = const []}): _sciences = sciences,_series = series,_journeys = journeys;
  factory _CatalogData.fromJson(Map<String, dynamic> json) => _$CatalogDataFromJson(json);

@override final  int version;
@override final  DateTime? generatedAt;
 final  List<CatalogScience> _sciences;
@override@JsonKey() List<CatalogScience> get sciences {
  if (_sciences is EqualUnmodifiableListView) return _sciences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sciences);
}

 final  List<CatalogSeries> _series;
@override@JsonKey() List<CatalogSeries> get series {
  if (_series is EqualUnmodifiableListView) return _series;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_series);
}

 final  List<CatalogJourney> _journeys;
@override@JsonKey() List<CatalogJourney> get journeys {
  if (_journeys is EqualUnmodifiableListView) return _journeys;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_journeys);
}


/// Create a copy of CatalogData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogDataCopyWith<_CatalogData> get copyWith => __$CatalogDataCopyWithImpl<_CatalogData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogData&&(identical(other.version, version) || other.version == version)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&const DeepCollectionEquality().equals(other._sciences, _sciences)&&const DeepCollectionEquality().equals(other._series, _series)&&const DeepCollectionEquality().equals(other._journeys, _journeys));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,generatedAt,const DeepCollectionEquality().hash(_sciences),const DeepCollectionEquality().hash(_series),const DeepCollectionEquality().hash(_journeys));

@override
String toString() {
  return 'CatalogData(version: $version, generatedAt: $generatedAt, sciences: $sciences, series: $series, journeys: $journeys)';
}


}

/// @nodoc
abstract mixin class _$CatalogDataCopyWith<$Res> implements $CatalogDataCopyWith<$Res> {
  factory _$CatalogDataCopyWith(_CatalogData value, $Res Function(_CatalogData) _then) = __$CatalogDataCopyWithImpl;
@override @useResult
$Res call({
 int version, DateTime? generatedAt, List<CatalogScience> sciences, List<CatalogSeries> series, List<CatalogJourney> journeys
});




}
/// @nodoc
class __$CatalogDataCopyWithImpl<$Res>
    implements _$CatalogDataCopyWith<$Res> {
  __$CatalogDataCopyWithImpl(this._self, this._then);

  final _CatalogData _self;
  final $Res Function(_CatalogData) _then;

/// Create a copy of CatalogData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? generatedAt = freezed,Object? sciences = null,Object? series = null,Object? journeys = null,}) {
  return _then(_CatalogData(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,generatedAt: freezed == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,sciences: null == sciences ? _self._sciences : sciences // ignore: cast_nullable_to_non_nullable
as List<CatalogScience>,series: null == series ? _self._series : series // ignore: cast_nullable_to_non_nullable
as List<CatalogSeries>,journeys: null == journeys ? _self._journeys : journeys // ignore: cast_nullable_to_non_nullable
as List<CatalogJourney>,
  ));
}


}


/// @nodoc
mixin _$CatalogScience {

 String get slug; String get nameAr; String? get descriptionAr; String? get icon; int get sortOrder;
/// Create a copy of CatalogScience
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogScienceCopyWith<CatalogScience> get copyWith => _$CatalogScienceCopyWithImpl<CatalogScience>(this as CatalogScience, _$identity);

  /// Serializes this CatalogScience to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogScience&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.descriptionAr, descriptionAr) || other.descriptionAr == descriptionAr)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,nameAr,descriptionAr,icon,sortOrder);

@override
String toString() {
  return 'CatalogScience(slug: $slug, nameAr: $nameAr, descriptionAr: $descriptionAr, icon: $icon, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $CatalogScienceCopyWith<$Res>  {
  factory $CatalogScienceCopyWith(CatalogScience value, $Res Function(CatalogScience) _then) = _$CatalogScienceCopyWithImpl;
@useResult
$Res call({
 String slug, String nameAr, String? descriptionAr, String? icon, int sortOrder
});




}
/// @nodoc
class _$CatalogScienceCopyWithImpl<$Res>
    implements $CatalogScienceCopyWith<$Res> {
  _$CatalogScienceCopyWithImpl(this._self, this._then);

  final CatalogScience _self;
  final $Res Function(CatalogScience) _then;

/// Create a copy of CatalogScience
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = null,Object? nameAr = null,Object? descriptionAr = freezed,Object? icon = freezed,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,descriptionAr: freezed == descriptionAr ? _self.descriptionAr : descriptionAr // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogScience].
extension CatalogSciencePatterns on CatalogScience {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogScience value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogScience() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogScience value)  $default,){
final _that = this;
switch (_that) {
case _CatalogScience():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogScience value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogScience() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slug,  String nameAr,  String? descriptionAr,  String? icon,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogScience() when $default != null:
return $default(_that.slug,_that.nameAr,_that.descriptionAr,_that.icon,_that.sortOrder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slug,  String nameAr,  String? descriptionAr,  String? icon,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _CatalogScience():
return $default(_that.slug,_that.nameAr,_that.descriptionAr,_that.icon,_that.sortOrder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slug,  String nameAr,  String? descriptionAr,  String? icon,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _CatalogScience() when $default != null:
return $default(_that.slug,_that.nameAr,_that.descriptionAr,_that.icon,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogScience implements CatalogScience {
  const _CatalogScience({required this.slug, required this.nameAr, this.descriptionAr, this.icon, this.sortOrder = 0});
  factory _CatalogScience.fromJson(Map<String, dynamic> json) => _$CatalogScienceFromJson(json);

@override final  String slug;
@override final  String nameAr;
@override final  String? descriptionAr;
@override final  String? icon;
@override@JsonKey() final  int sortOrder;

/// Create a copy of CatalogScience
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogScienceCopyWith<_CatalogScience> get copyWith => __$CatalogScienceCopyWithImpl<_CatalogScience>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogScienceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogScience&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.descriptionAr, descriptionAr) || other.descriptionAr == descriptionAr)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,nameAr,descriptionAr,icon,sortOrder);

@override
String toString() {
  return 'CatalogScience(slug: $slug, nameAr: $nameAr, descriptionAr: $descriptionAr, icon: $icon, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$CatalogScienceCopyWith<$Res> implements $CatalogScienceCopyWith<$Res> {
  factory _$CatalogScienceCopyWith(_CatalogScience value, $Res Function(_CatalogScience) _then) = __$CatalogScienceCopyWithImpl;
@override @useResult
$Res call({
 String slug, String nameAr, String? descriptionAr, String? icon, int sortOrder
});




}
/// @nodoc
class __$CatalogScienceCopyWithImpl<$Res>
    implements _$CatalogScienceCopyWith<$Res> {
  __$CatalogScienceCopyWithImpl(this._self, this._then);

  final _CatalogScience _self;
  final $Res Function(_CatalogScience) _then;

/// Create a copy of CatalogScience
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = null,Object? nameAr = null,Object? descriptionAr = freezed,Object? icon = freezed,Object? sortOrder = null,}) {
  return _then(_CatalogScience(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,descriptionAr: freezed == descriptionAr ? _self.descriptionAr : descriptionAr // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CatalogSeries {

 String get slug; String get science; String get titleAr; String? get descriptionAr; String? get thumbnailUrl; JourneyLevel? get level; LessonMedia get media;/// Audio companions: set on the audio edition (slug of the video series
/// it mirrors) — such series are hidden from library browse. Video series
/// carry the reverse link in [companionSlug].
 String? get companionOf; String? get companionSlug; List<CatalogLesson> get lessons;
/// Create a copy of CatalogSeries
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogSeriesCopyWith<CatalogSeries> get copyWith => _$CatalogSeriesCopyWithImpl<CatalogSeries>(this as CatalogSeries, _$identity);

  /// Serializes this CatalogSeries to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogSeries&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.science, science) || other.science == science)&&(identical(other.titleAr, titleAr) || other.titleAr == titleAr)&&(identical(other.descriptionAr, descriptionAr) || other.descriptionAr == descriptionAr)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.level, level) || other.level == level)&&(identical(other.media, media) || other.media == media)&&(identical(other.companionOf, companionOf) || other.companionOf == companionOf)&&(identical(other.companionSlug, companionSlug) || other.companionSlug == companionSlug)&&const DeepCollectionEquality().equals(other.lessons, lessons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,science,titleAr,descriptionAr,thumbnailUrl,level,media,companionOf,companionSlug,const DeepCollectionEquality().hash(lessons));

@override
String toString() {
  return 'CatalogSeries(slug: $slug, science: $science, titleAr: $titleAr, descriptionAr: $descriptionAr, thumbnailUrl: $thumbnailUrl, level: $level, media: $media, companionOf: $companionOf, companionSlug: $companionSlug, lessons: $lessons)';
}


}

/// @nodoc
abstract mixin class $CatalogSeriesCopyWith<$Res>  {
  factory $CatalogSeriesCopyWith(CatalogSeries value, $Res Function(CatalogSeries) _then) = _$CatalogSeriesCopyWithImpl;
@useResult
$Res call({
 String slug, String science, String titleAr, String? descriptionAr, String? thumbnailUrl, JourneyLevel? level, LessonMedia media, String? companionOf, String? companionSlug, List<CatalogLesson> lessons
});




}
/// @nodoc
class _$CatalogSeriesCopyWithImpl<$Res>
    implements $CatalogSeriesCopyWith<$Res> {
  _$CatalogSeriesCopyWithImpl(this._self, this._then);

  final CatalogSeries _self;
  final $Res Function(CatalogSeries) _then;

/// Create a copy of CatalogSeries
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = null,Object? science = null,Object? titleAr = null,Object? descriptionAr = freezed,Object? thumbnailUrl = freezed,Object? level = freezed,Object? media = null,Object? companionOf = freezed,Object? companionSlug = freezed,Object? lessons = null,}) {
  return _then(_self.copyWith(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,science: null == science ? _self.science : science // ignore: cast_nullable_to_non_nullable
as String,titleAr: null == titleAr ? _self.titleAr : titleAr // ignore: cast_nullable_to_non_nullable
as String,descriptionAr: freezed == descriptionAr ? _self.descriptionAr : descriptionAr // ignore: cast_nullable_to_non_nullable
as String?,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as JourneyLevel?,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as LessonMedia,companionOf: freezed == companionOf ? _self.companionOf : companionOf // ignore: cast_nullable_to_non_nullable
as String?,companionSlug: freezed == companionSlug ? _self.companionSlug : companionSlug // ignore: cast_nullable_to_non_nullable
as String?,lessons: null == lessons ? _self.lessons : lessons // ignore: cast_nullable_to_non_nullable
as List<CatalogLesson>,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogSeries].
extension CatalogSeriesPatterns on CatalogSeries {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogSeries value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogSeries() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogSeries value)  $default,){
final _that = this;
switch (_that) {
case _CatalogSeries():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogSeries value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogSeries() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slug,  String science,  String titleAr,  String? descriptionAr,  String? thumbnailUrl,  JourneyLevel? level,  LessonMedia media,  String? companionOf,  String? companionSlug,  List<CatalogLesson> lessons)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogSeries() when $default != null:
return $default(_that.slug,_that.science,_that.titleAr,_that.descriptionAr,_that.thumbnailUrl,_that.level,_that.media,_that.companionOf,_that.companionSlug,_that.lessons);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slug,  String science,  String titleAr,  String? descriptionAr,  String? thumbnailUrl,  JourneyLevel? level,  LessonMedia media,  String? companionOf,  String? companionSlug,  List<CatalogLesson> lessons)  $default,) {final _that = this;
switch (_that) {
case _CatalogSeries():
return $default(_that.slug,_that.science,_that.titleAr,_that.descriptionAr,_that.thumbnailUrl,_that.level,_that.media,_that.companionOf,_that.companionSlug,_that.lessons);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slug,  String science,  String titleAr,  String? descriptionAr,  String? thumbnailUrl,  JourneyLevel? level,  LessonMedia media,  String? companionOf,  String? companionSlug,  List<CatalogLesson> lessons)?  $default,) {final _that = this;
switch (_that) {
case _CatalogSeries() when $default != null:
return $default(_that.slug,_that.science,_that.titleAr,_that.descriptionAr,_that.thumbnailUrl,_that.level,_that.media,_that.companionOf,_that.companionSlug,_that.lessons);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogSeries implements CatalogSeries {
  const _CatalogSeries({required this.slug, required this.science, required this.titleAr, this.descriptionAr, this.thumbnailUrl, this.level, this.media = LessonMedia.video, this.companionOf, this.companionSlug, final  List<CatalogLesson> lessons = const []}): _lessons = lessons;
  factory _CatalogSeries.fromJson(Map<String, dynamic> json) => _$CatalogSeriesFromJson(json);

@override final  String slug;
@override final  String science;
@override final  String titleAr;
@override final  String? descriptionAr;
@override final  String? thumbnailUrl;
@override final  JourneyLevel? level;
@override@JsonKey() final  LessonMedia media;
/// Audio companions: set on the audio edition (slug of the video series
/// it mirrors) — such series are hidden from library browse. Video series
/// carry the reverse link in [companionSlug].
@override final  String? companionOf;
@override final  String? companionSlug;
 final  List<CatalogLesson> _lessons;
@override@JsonKey() List<CatalogLesson> get lessons {
  if (_lessons is EqualUnmodifiableListView) return _lessons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lessons);
}


/// Create a copy of CatalogSeries
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogSeriesCopyWith<_CatalogSeries> get copyWith => __$CatalogSeriesCopyWithImpl<_CatalogSeries>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogSeriesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogSeries&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.science, science) || other.science == science)&&(identical(other.titleAr, titleAr) || other.titleAr == titleAr)&&(identical(other.descriptionAr, descriptionAr) || other.descriptionAr == descriptionAr)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.level, level) || other.level == level)&&(identical(other.media, media) || other.media == media)&&(identical(other.companionOf, companionOf) || other.companionOf == companionOf)&&(identical(other.companionSlug, companionSlug) || other.companionSlug == companionSlug)&&const DeepCollectionEquality().equals(other._lessons, _lessons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,science,titleAr,descriptionAr,thumbnailUrl,level,media,companionOf,companionSlug,const DeepCollectionEquality().hash(_lessons));

@override
String toString() {
  return 'CatalogSeries(slug: $slug, science: $science, titleAr: $titleAr, descriptionAr: $descriptionAr, thumbnailUrl: $thumbnailUrl, level: $level, media: $media, companionOf: $companionOf, companionSlug: $companionSlug, lessons: $lessons)';
}


}

/// @nodoc
abstract mixin class _$CatalogSeriesCopyWith<$Res> implements $CatalogSeriesCopyWith<$Res> {
  factory _$CatalogSeriesCopyWith(_CatalogSeries value, $Res Function(_CatalogSeries) _then) = __$CatalogSeriesCopyWithImpl;
@override @useResult
$Res call({
 String slug, String science, String titleAr, String? descriptionAr, String? thumbnailUrl, JourneyLevel? level, LessonMedia media, String? companionOf, String? companionSlug, List<CatalogLesson> lessons
});




}
/// @nodoc
class __$CatalogSeriesCopyWithImpl<$Res>
    implements _$CatalogSeriesCopyWith<$Res> {
  __$CatalogSeriesCopyWithImpl(this._self, this._then);

  final _CatalogSeries _self;
  final $Res Function(_CatalogSeries) _then;

/// Create a copy of CatalogSeries
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = null,Object? science = null,Object? titleAr = null,Object? descriptionAr = freezed,Object? thumbnailUrl = freezed,Object? level = freezed,Object? media = null,Object? companionOf = freezed,Object? companionSlug = freezed,Object? lessons = null,}) {
  return _then(_CatalogSeries(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,science: null == science ? _self.science : science // ignore: cast_nullable_to_non_nullable
as String,titleAr: null == titleAr ? _self.titleAr : titleAr // ignore: cast_nullable_to_non_nullable
as String,descriptionAr: freezed == descriptionAr ? _self.descriptionAr : descriptionAr // ignore: cast_nullable_to_non_nullable
as String?,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as JourneyLevel?,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as LessonMedia,companionOf: freezed == companionOf ? _self.companionOf : companionOf // ignore: cast_nullable_to_non_nullable
as String?,companionSlug: freezed == companionSlug ? _self.companionSlug : companionSlug // ignore: cast_nullable_to_non_nullable
as String?,lessons: null == lessons ? _self._lessons : lessons // ignore: cast_nullable_to_non_nullable
as List<CatalogLesson>,
  ));
}


}


/// @nodoc
mixin _$CatalogLesson {

/// External id: YouTube video id, or the site lesson uuid for audio.
 String get youtubeVideoId; int get position; String get titleAr; int? get durationSeconds; DateTime? get publishedAt; LessonStatus get status; LessonMedia get media; String? get audioUrl; List<CatalogChapter> get chapters;
/// Create a copy of CatalogLesson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogLessonCopyWith<CatalogLesson> get copyWith => _$CatalogLessonCopyWithImpl<CatalogLesson>(this as CatalogLesson, _$identity);

  /// Serializes this CatalogLesson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogLesson&&(identical(other.youtubeVideoId, youtubeVideoId) || other.youtubeVideoId == youtubeVideoId)&&(identical(other.position, position) || other.position == position)&&(identical(other.titleAr, titleAr) || other.titleAr == titleAr)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.media, media) || other.media == media)&&(identical(other.audioUrl, audioUrl) || other.audioUrl == audioUrl)&&const DeepCollectionEquality().equals(other.chapters, chapters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,youtubeVideoId,position,titleAr,durationSeconds,publishedAt,status,media,audioUrl,const DeepCollectionEquality().hash(chapters));

@override
String toString() {
  return 'CatalogLesson(youtubeVideoId: $youtubeVideoId, position: $position, titleAr: $titleAr, durationSeconds: $durationSeconds, publishedAt: $publishedAt, status: $status, media: $media, audioUrl: $audioUrl, chapters: $chapters)';
}


}

/// @nodoc
abstract mixin class $CatalogLessonCopyWith<$Res>  {
  factory $CatalogLessonCopyWith(CatalogLesson value, $Res Function(CatalogLesson) _then) = _$CatalogLessonCopyWithImpl;
@useResult
$Res call({
 String youtubeVideoId, int position, String titleAr, int? durationSeconds, DateTime? publishedAt, LessonStatus status, LessonMedia media, String? audioUrl, List<CatalogChapter> chapters
});




}
/// @nodoc
class _$CatalogLessonCopyWithImpl<$Res>
    implements $CatalogLessonCopyWith<$Res> {
  _$CatalogLessonCopyWithImpl(this._self, this._then);

  final CatalogLesson _self;
  final $Res Function(CatalogLesson) _then;

/// Create a copy of CatalogLesson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? youtubeVideoId = null,Object? position = null,Object? titleAr = null,Object? durationSeconds = freezed,Object? publishedAt = freezed,Object? status = null,Object? media = null,Object? audioUrl = freezed,Object? chapters = null,}) {
  return _then(_self.copyWith(
youtubeVideoId: null == youtubeVideoId ? _self.youtubeVideoId : youtubeVideoId // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,titleAr: null == titleAr ? _self.titleAr : titleAr // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LessonStatus,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as LessonMedia,audioUrl: freezed == audioUrl ? _self.audioUrl : audioUrl // ignore: cast_nullable_to_non_nullable
as String?,chapters: null == chapters ? _self.chapters : chapters // ignore: cast_nullable_to_non_nullable
as List<CatalogChapter>,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogLesson].
extension CatalogLessonPatterns on CatalogLesson {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogLesson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogLesson() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogLesson value)  $default,){
final _that = this;
switch (_that) {
case _CatalogLesson():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogLesson value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogLesson() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String youtubeVideoId,  int position,  String titleAr,  int? durationSeconds,  DateTime? publishedAt,  LessonStatus status,  LessonMedia media,  String? audioUrl,  List<CatalogChapter> chapters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogLesson() when $default != null:
return $default(_that.youtubeVideoId,_that.position,_that.titleAr,_that.durationSeconds,_that.publishedAt,_that.status,_that.media,_that.audioUrl,_that.chapters);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String youtubeVideoId,  int position,  String titleAr,  int? durationSeconds,  DateTime? publishedAt,  LessonStatus status,  LessonMedia media,  String? audioUrl,  List<CatalogChapter> chapters)  $default,) {final _that = this;
switch (_that) {
case _CatalogLesson():
return $default(_that.youtubeVideoId,_that.position,_that.titleAr,_that.durationSeconds,_that.publishedAt,_that.status,_that.media,_that.audioUrl,_that.chapters);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String youtubeVideoId,  int position,  String titleAr,  int? durationSeconds,  DateTime? publishedAt,  LessonStatus status,  LessonMedia media,  String? audioUrl,  List<CatalogChapter> chapters)?  $default,) {final _that = this;
switch (_that) {
case _CatalogLesson() when $default != null:
return $default(_that.youtubeVideoId,_that.position,_that.titleAr,_that.durationSeconds,_that.publishedAt,_that.status,_that.media,_that.audioUrl,_that.chapters);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogLesson implements CatalogLesson {
  const _CatalogLesson({required this.youtubeVideoId, required this.position, required this.titleAr, this.durationSeconds, this.publishedAt, this.status = LessonStatus.active, this.media = LessonMedia.video, this.audioUrl, final  List<CatalogChapter> chapters = const []}): _chapters = chapters;
  factory _CatalogLesson.fromJson(Map<String, dynamic> json) => _$CatalogLessonFromJson(json);

/// External id: YouTube video id, or the site lesson uuid for audio.
@override final  String youtubeVideoId;
@override final  int position;
@override final  String titleAr;
@override final  int? durationSeconds;
@override final  DateTime? publishedAt;
@override@JsonKey() final  LessonStatus status;
@override@JsonKey() final  LessonMedia media;
@override final  String? audioUrl;
 final  List<CatalogChapter> _chapters;
@override@JsonKey() List<CatalogChapter> get chapters {
  if (_chapters is EqualUnmodifiableListView) return _chapters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_chapters);
}


/// Create a copy of CatalogLesson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogLessonCopyWith<_CatalogLesson> get copyWith => __$CatalogLessonCopyWithImpl<_CatalogLesson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogLessonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogLesson&&(identical(other.youtubeVideoId, youtubeVideoId) || other.youtubeVideoId == youtubeVideoId)&&(identical(other.position, position) || other.position == position)&&(identical(other.titleAr, titleAr) || other.titleAr == titleAr)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.media, media) || other.media == media)&&(identical(other.audioUrl, audioUrl) || other.audioUrl == audioUrl)&&const DeepCollectionEquality().equals(other._chapters, _chapters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,youtubeVideoId,position,titleAr,durationSeconds,publishedAt,status,media,audioUrl,const DeepCollectionEquality().hash(_chapters));

@override
String toString() {
  return 'CatalogLesson(youtubeVideoId: $youtubeVideoId, position: $position, titleAr: $titleAr, durationSeconds: $durationSeconds, publishedAt: $publishedAt, status: $status, media: $media, audioUrl: $audioUrl, chapters: $chapters)';
}


}

/// @nodoc
abstract mixin class _$CatalogLessonCopyWith<$Res> implements $CatalogLessonCopyWith<$Res> {
  factory _$CatalogLessonCopyWith(_CatalogLesson value, $Res Function(_CatalogLesson) _then) = __$CatalogLessonCopyWithImpl;
@override @useResult
$Res call({
 String youtubeVideoId, int position, String titleAr, int? durationSeconds, DateTime? publishedAt, LessonStatus status, LessonMedia media, String? audioUrl, List<CatalogChapter> chapters
});




}
/// @nodoc
class __$CatalogLessonCopyWithImpl<$Res>
    implements _$CatalogLessonCopyWith<$Res> {
  __$CatalogLessonCopyWithImpl(this._self, this._then);

  final _CatalogLesson _self;
  final $Res Function(_CatalogLesson) _then;

/// Create a copy of CatalogLesson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? youtubeVideoId = null,Object? position = null,Object? titleAr = null,Object? durationSeconds = freezed,Object? publishedAt = freezed,Object? status = null,Object? media = null,Object? audioUrl = freezed,Object? chapters = null,}) {
  return _then(_CatalogLesson(
youtubeVideoId: null == youtubeVideoId ? _self.youtubeVideoId : youtubeVideoId // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,titleAr: null == titleAr ? _self.titleAr : titleAr // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LessonStatus,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as LessonMedia,audioUrl: freezed == audioUrl ? _self.audioUrl : audioUrl // ignore: cast_nullable_to_non_nullable
as String?,chapters: null == chapters ? _self._chapters : chapters // ignore: cast_nullable_to_non_nullable
as List<CatalogChapter>,
  ));
}


}


/// @nodoc
mixin _$CatalogChapter {

 int? get startSeconds; String get title; String get body;
/// Create a copy of CatalogChapter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogChapterCopyWith<CatalogChapter> get copyWith => _$CatalogChapterCopyWithImpl<CatalogChapter>(this as CatalogChapter, _$identity);

  /// Serializes this CatalogChapter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogChapter&&(identical(other.startSeconds, startSeconds) || other.startSeconds == startSeconds)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startSeconds,title,body);

@override
String toString() {
  return 'CatalogChapter(startSeconds: $startSeconds, title: $title, body: $body)';
}


}

/// @nodoc
abstract mixin class $CatalogChapterCopyWith<$Res>  {
  factory $CatalogChapterCopyWith(CatalogChapter value, $Res Function(CatalogChapter) _then) = _$CatalogChapterCopyWithImpl;
@useResult
$Res call({
 int? startSeconds, String title, String body
});




}
/// @nodoc
class _$CatalogChapterCopyWithImpl<$Res>
    implements $CatalogChapterCopyWith<$Res> {
  _$CatalogChapterCopyWithImpl(this._self, this._then);

  final CatalogChapter _self;
  final $Res Function(CatalogChapter) _then;

/// Create a copy of CatalogChapter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startSeconds = freezed,Object? title = null,Object? body = null,}) {
  return _then(_self.copyWith(
startSeconds: freezed == startSeconds ? _self.startSeconds : startSeconds // ignore: cast_nullable_to_non_nullable
as int?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogChapter].
extension CatalogChapterPatterns on CatalogChapter {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogChapter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogChapter() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogChapter value)  $default,){
final _that = this;
switch (_that) {
case _CatalogChapter():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogChapter value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogChapter() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? startSeconds,  String title,  String body)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogChapter() when $default != null:
return $default(_that.startSeconds,_that.title,_that.body);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? startSeconds,  String title,  String body)  $default,) {final _that = this;
switch (_that) {
case _CatalogChapter():
return $default(_that.startSeconds,_that.title,_that.body);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? startSeconds,  String title,  String body)?  $default,) {final _that = this;
switch (_that) {
case _CatalogChapter() when $default != null:
return $default(_that.startSeconds,_that.title,_that.body);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogChapter implements CatalogChapter {
  const _CatalogChapter({this.startSeconds, required this.title, this.body = ''});
  factory _CatalogChapter.fromJson(Map<String, dynamic> json) => _$CatalogChapterFromJson(json);

@override final  int? startSeconds;
@override final  String title;
@override@JsonKey() final  String body;

/// Create a copy of CatalogChapter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogChapterCopyWith<_CatalogChapter> get copyWith => __$CatalogChapterCopyWithImpl<_CatalogChapter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogChapterToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogChapter&&(identical(other.startSeconds, startSeconds) || other.startSeconds == startSeconds)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startSeconds,title,body);

@override
String toString() {
  return 'CatalogChapter(startSeconds: $startSeconds, title: $title, body: $body)';
}


}

/// @nodoc
abstract mixin class _$CatalogChapterCopyWith<$Res> implements $CatalogChapterCopyWith<$Res> {
  factory _$CatalogChapterCopyWith(_CatalogChapter value, $Res Function(_CatalogChapter) _then) = __$CatalogChapterCopyWithImpl;
@override @useResult
$Res call({
 int? startSeconds, String title, String body
});




}
/// @nodoc
class __$CatalogChapterCopyWithImpl<$Res>
    implements _$CatalogChapterCopyWith<$Res> {
  __$CatalogChapterCopyWithImpl(this._self, this._then);

  final _CatalogChapter _self;
  final $Res Function(_CatalogChapter) _then;

/// Create a copy of CatalogChapter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startSeconds = freezed,Object? title = null,Object? body = null,}) {
  return _then(_CatalogChapter(
startSeconds: freezed == startSeconds ? _self.startSeconds : startSeconds // ignore: cast_nullable_to_non_nullable
as int?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CatalogJourney {

 String get slug; String get titleAr; String? get descriptionAr; JourneyLevel get level; String? get science; String? get coverUrl; int get sortOrder; List<CatalogStage> get stages;
/// Create a copy of CatalogJourney
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogJourneyCopyWith<CatalogJourney> get copyWith => _$CatalogJourneyCopyWithImpl<CatalogJourney>(this as CatalogJourney, _$identity);

  /// Serializes this CatalogJourney to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogJourney&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.titleAr, titleAr) || other.titleAr == titleAr)&&(identical(other.descriptionAr, descriptionAr) || other.descriptionAr == descriptionAr)&&(identical(other.level, level) || other.level == level)&&(identical(other.science, science) || other.science == science)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&const DeepCollectionEquality().equals(other.stages, stages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,titleAr,descriptionAr,level,science,coverUrl,sortOrder,const DeepCollectionEquality().hash(stages));

@override
String toString() {
  return 'CatalogJourney(slug: $slug, titleAr: $titleAr, descriptionAr: $descriptionAr, level: $level, science: $science, coverUrl: $coverUrl, sortOrder: $sortOrder, stages: $stages)';
}


}

/// @nodoc
abstract mixin class $CatalogJourneyCopyWith<$Res>  {
  factory $CatalogJourneyCopyWith(CatalogJourney value, $Res Function(CatalogJourney) _then) = _$CatalogJourneyCopyWithImpl;
@useResult
$Res call({
 String slug, String titleAr, String? descriptionAr, JourneyLevel level, String? science, String? coverUrl, int sortOrder, List<CatalogStage> stages
});




}
/// @nodoc
class _$CatalogJourneyCopyWithImpl<$Res>
    implements $CatalogJourneyCopyWith<$Res> {
  _$CatalogJourneyCopyWithImpl(this._self, this._then);

  final CatalogJourney _self;
  final $Res Function(CatalogJourney) _then;

/// Create a copy of CatalogJourney
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = null,Object? titleAr = null,Object? descriptionAr = freezed,Object? level = null,Object? science = freezed,Object? coverUrl = freezed,Object? sortOrder = null,Object? stages = null,}) {
  return _then(_self.copyWith(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,titleAr: null == titleAr ? _self.titleAr : titleAr // ignore: cast_nullable_to_non_nullable
as String,descriptionAr: freezed == descriptionAr ? _self.descriptionAr : descriptionAr // ignore: cast_nullable_to_non_nullable
as String?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as JourneyLevel,science: freezed == science ? _self.science : science // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,stages: null == stages ? _self.stages : stages // ignore: cast_nullable_to_non_nullable
as List<CatalogStage>,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogJourney].
extension CatalogJourneyPatterns on CatalogJourney {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogJourney value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogJourney() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogJourney value)  $default,){
final _that = this;
switch (_that) {
case _CatalogJourney():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogJourney value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogJourney() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slug,  String titleAr,  String? descriptionAr,  JourneyLevel level,  String? science,  String? coverUrl,  int sortOrder,  List<CatalogStage> stages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogJourney() when $default != null:
return $default(_that.slug,_that.titleAr,_that.descriptionAr,_that.level,_that.science,_that.coverUrl,_that.sortOrder,_that.stages);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slug,  String titleAr,  String? descriptionAr,  JourneyLevel level,  String? science,  String? coverUrl,  int sortOrder,  List<CatalogStage> stages)  $default,) {final _that = this;
switch (_that) {
case _CatalogJourney():
return $default(_that.slug,_that.titleAr,_that.descriptionAr,_that.level,_that.science,_that.coverUrl,_that.sortOrder,_that.stages);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slug,  String titleAr,  String? descriptionAr,  JourneyLevel level,  String? science,  String? coverUrl,  int sortOrder,  List<CatalogStage> stages)?  $default,) {final _that = this;
switch (_that) {
case _CatalogJourney() when $default != null:
return $default(_that.slug,_that.titleAr,_that.descriptionAr,_that.level,_that.science,_that.coverUrl,_that.sortOrder,_that.stages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogJourney implements CatalogJourney {
  const _CatalogJourney({required this.slug, required this.titleAr, this.descriptionAr, required this.level, this.science, this.coverUrl, this.sortOrder = 0, final  List<CatalogStage> stages = const []}): _stages = stages;
  factory _CatalogJourney.fromJson(Map<String, dynamic> json) => _$CatalogJourneyFromJson(json);

@override final  String slug;
@override final  String titleAr;
@override final  String? descriptionAr;
@override final  JourneyLevel level;
@override final  String? science;
@override final  String? coverUrl;
@override@JsonKey() final  int sortOrder;
 final  List<CatalogStage> _stages;
@override@JsonKey() List<CatalogStage> get stages {
  if (_stages is EqualUnmodifiableListView) return _stages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stages);
}


/// Create a copy of CatalogJourney
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogJourneyCopyWith<_CatalogJourney> get copyWith => __$CatalogJourneyCopyWithImpl<_CatalogJourney>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogJourneyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogJourney&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.titleAr, titleAr) || other.titleAr == titleAr)&&(identical(other.descriptionAr, descriptionAr) || other.descriptionAr == descriptionAr)&&(identical(other.level, level) || other.level == level)&&(identical(other.science, science) || other.science == science)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&const DeepCollectionEquality().equals(other._stages, _stages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,titleAr,descriptionAr,level,science,coverUrl,sortOrder,const DeepCollectionEquality().hash(_stages));

@override
String toString() {
  return 'CatalogJourney(slug: $slug, titleAr: $titleAr, descriptionAr: $descriptionAr, level: $level, science: $science, coverUrl: $coverUrl, sortOrder: $sortOrder, stages: $stages)';
}


}

/// @nodoc
abstract mixin class _$CatalogJourneyCopyWith<$Res> implements $CatalogJourneyCopyWith<$Res> {
  factory _$CatalogJourneyCopyWith(_CatalogJourney value, $Res Function(_CatalogJourney) _then) = __$CatalogJourneyCopyWithImpl;
@override @useResult
$Res call({
 String slug, String titleAr, String? descriptionAr, JourneyLevel level, String? science, String? coverUrl, int sortOrder, List<CatalogStage> stages
});




}
/// @nodoc
class __$CatalogJourneyCopyWithImpl<$Res>
    implements _$CatalogJourneyCopyWith<$Res> {
  __$CatalogJourneyCopyWithImpl(this._self, this._then);

  final _CatalogJourney _self;
  final $Res Function(_CatalogJourney) _then;

/// Create a copy of CatalogJourney
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = null,Object? titleAr = null,Object? descriptionAr = freezed,Object? level = null,Object? science = freezed,Object? coverUrl = freezed,Object? sortOrder = null,Object? stages = null,}) {
  return _then(_CatalogJourney(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,titleAr: null == titleAr ? _self.titleAr : titleAr // ignore: cast_nullable_to_non_nullable
as String,descriptionAr: freezed == descriptionAr ? _self.descriptionAr : descriptionAr // ignore: cast_nullable_to_non_nullable
as String?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as JourneyLevel,science: freezed == science ? _self.science : science // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,stages: null == stages ? _self._stages : stages // ignore: cast_nullable_to_non_nullable
as List<CatalogStage>,
  ));
}


}


/// @nodoc
mixin _$CatalogStage {

 String get titleAr; String? get descriptionAr; List<CatalogStageItem> get items;
/// Create a copy of CatalogStage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogStageCopyWith<CatalogStage> get copyWith => _$CatalogStageCopyWithImpl<CatalogStage>(this as CatalogStage, _$identity);

  /// Serializes this CatalogStage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogStage&&(identical(other.titleAr, titleAr) || other.titleAr == titleAr)&&(identical(other.descriptionAr, descriptionAr) || other.descriptionAr == descriptionAr)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,titleAr,descriptionAr,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'CatalogStage(titleAr: $titleAr, descriptionAr: $descriptionAr, items: $items)';
}


}

/// @nodoc
abstract mixin class $CatalogStageCopyWith<$Res>  {
  factory $CatalogStageCopyWith(CatalogStage value, $Res Function(CatalogStage) _then) = _$CatalogStageCopyWithImpl;
@useResult
$Res call({
 String titleAr, String? descriptionAr, List<CatalogStageItem> items
});




}
/// @nodoc
class _$CatalogStageCopyWithImpl<$Res>
    implements $CatalogStageCopyWith<$Res> {
  _$CatalogStageCopyWithImpl(this._self, this._then);

  final CatalogStage _self;
  final $Res Function(CatalogStage) _then;

/// Create a copy of CatalogStage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? titleAr = null,Object? descriptionAr = freezed,Object? items = null,}) {
  return _then(_self.copyWith(
titleAr: null == titleAr ? _self.titleAr : titleAr // ignore: cast_nullable_to_non_nullable
as String,descriptionAr: freezed == descriptionAr ? _self.descriptionAr : descriptionAr // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CatalogStageItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogStage].
extension CatalogStagePatterns on CatalogStage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogStage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogStage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogStage value)  $default,){
final _that = this;
switch (_that) {
case _CatalogStage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogStage value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogStage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String titleAr,  String? descriptionAr,  List<CatalogStageItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogStage() when $default != null:
return $default(_that.titleAr,_that.descriptionAr,_that.items);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String titleAr,  String? descriptionAr,  List<CatalogStageItem> items)  $default,) {final _that = this;
switch (_that) {
case _CatalogStage():
return $default(_that.titleAr,_that.descriptionAr,_that.items);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String titleAr,  String? descriptionAr,  List<CatalogStageItem> items)?  $default,) {final _that = this;
switch (_that) {
case _CatalogStage() when $default != null:
return $default(_that.titleAr,_that.descriptionAr,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogStage implements CatalogStage {
  const _CatalogStage({required this.titleAr, this.descriptionAr, final  List<CatalogStageItem> items = const []}): _items = items;
  factory _CatalogStage.fromJson(Map<String, dynamic> json) => _$CatalogStageFromJson(json);

@override final  String titleAr;
@override final  String? descriptionAr;
 final  List<CatalogStageItem> _items;
@override@JsonKey() List<CatalogStageItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of CatalogStage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogStageCopyWith<_CatalogStage> get copyWith => __$CatalogStageCopyWithImpl<_CatalogStage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogStageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogStage&&(identical(other.titleAr, titleAr) || other.titleAr == titleAr)&&(identical(other.descriptionAr, descriptionAr) || other.descriptionAr == descriptionAr)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,titleAr,descriptionAr,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'CatalogStage(titleAr: $titleAr, descriptionAr: $descriptionAr, items: $items)';
}


}

/// @nodoc
abstract mixin class _$CatalogStageCopyWith<$Res> implements $CatalogStageCopyWith<$Res> {
  factory _$CatalogStageCopyWith(_CatalogStage value, $Res Function(_CatalogStage) _then) = __$CatalogStageCopyWithImpl;
@override @useResult
$Res call({
 String titleAr, String? descriptionAr, List<CatalogStageItem> items
});




}
/// @nodoc
class __$CatalogStageCopyWithImpl<$Res>
    implements _$CatalogStageCopyWith<$Res> {
  __$CatalogStageCopyWithImpl(this._self, this._then);

  final _CatalogStage _self;
  final $Res Function(_CatalogStage) _then;

/// Create a copy of CatalogStage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? titleAr = null,Object? descriptionAr = freezed,Object? items = null,}) {
  return _then(_CatalogStage(
titleAr: null == titleAr ? _self.titleAr : titleAr // ignore: cast_nullable_to_non_nullable
as String,descriptionAr: freezed == descriptionAr ? _self.descriptionAr : descriptionAr // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CatalogStageItem>,
  ));
}


}


/// @nodoc
mixin _$CatalogStageItem {

 String get type; String get series;
/// Create a copy of CatalogStageItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogStageItemCopyWith<CatalogStageItem> get copyWith => _$CatalogStageItemCopyWithImpl<CatalogStageItem>(this as CatalogStageItem, _$identity);

  /// Serializes this CatalogStageItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogStageItem&&(identical(other.type, type) || other.type == type)&&(identical(other.series, series) || other.series == series));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,series);

@override
String toString() {
  return 'CatalogStageItem(type: $type, series: $series)';
}


}

/// @nodoc
abstract mixin class $CatalogStageItemCopyWith<$Res>  {
  factory $CatalogStageItemCopyWith(CatalogStageItem value, $Res Function(CatalogStageItem) _then) = _$CatalogStageItemCopyWithImpl;
@useResult
$Res call({
 String type, String series
});




}
/// @nodoc
class _$CatalogStageItemCopyWithImpl<$Res>
    implements $CatalogStageItemCopyWith<$Res> {
  _$CatalogStageItemCopyWithImpl(this._self, this._then);

  final CatalogStageItem _self;
  final $Res Function(CatalogStageItem) _then;

/// Create a copy of CatalogStageItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? series = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,series: null == series ? _self.series : series // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogStageItem].
extension CatalogStageItemPatterns on CatalogStageItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogStageItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogStageItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogStageItem value)  $default,){
final _that = this;
switch (_that) {
case _CatalogStageItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogStageItem value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogStageItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String series)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogStageItem() when $default != null:
return $default(_that.type,_that.series);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String series)  $default,) {final _that = this;
switch (_that) {
case _CatalogStageItem():
return $default(_that.type,_that.series);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String series)?  $default,) {final _that = this;
switch (_that) {
case _CatalogStageItem() when $default != null:
return $default(_that.type,_that.series);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogStageItem implements CatalogStageItem {
  const _CatalogStageItem({this.type = 'series', required this.series});
  factory _CatalogStageItem.fromJson(Map<String, dynamic> json) => _$CatalogStageItemFromJson(json);

@override@JsonKey() final  String type;
@override final  String series;

/// Create a copy of CatalogStageItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogStageItemCopyWith<_CatalogStageItem> get copyWith => __$CatalogStageItemCopyWithImpl<_CatalogStageItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogStageItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogStageItem&&(identical(other.type, type) || other.type == type)&&(identical(other.series, series) || other.series == series));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,series);

@override
String toString() {
  return 'CatalogStageItem(type: $type, series: $series)';
}


}

/// @nodoc
abstract mixin class _$CatalogStageItemCopyWith<$Res> implements $CatalogStageItemCopyWith<$Res> {
  factory _$CatalogStageItemCopyWith(_CatalogStageItem value, $Res Function(_CatalogStageItem) _then) = __$CatalogStageItemCopyWithImpl;
@override @useResult
$Res call({
 String type, String series
});




}
/// @nodoc
class __$CatalogStageItemCopyWithImpl<$Res>
    implements _$CatalogStageItemCopyWith<$Res> {
  __$CatalogStageItemCopyWithImpl(this._self, this._then);

  final _CatalogStageItem _self;
  final $Res Function(_CatalogStageItem) _then;

/// Create a copy of CatalogStageItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? series = null,}) {
  return _then(_CatalogStageItem(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,series: null == series ? _self.series : series // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
