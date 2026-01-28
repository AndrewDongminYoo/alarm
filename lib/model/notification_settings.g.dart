// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationSettings _$NotificationSettingsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NotificationSettings', json, ($checkedConvert) {
  final val = NotificationSettings(
    title: $checkedConvert('title', (v) => v as String),
    body: $checkedConvert('body', (v) => v as String),
    stopButton: $checkedConvert('stopButton', (v) => v as String?),
    icon: $checkedConvert('icon', (v) => v as String?),
    iconColor: $checkedConvert(
      'iconColor',
      (v) => _$JsonConverterFromJson<String, Color>(
        v,
        const ColorConverter().fromJson,
      ),
    ),
  );
  return val;
});

Map<String, dynamic> _$NotificationSettingsToJson(
  NotificationSettings instance,
) => <String, dynamic>{
  'title': instance.title,
  'body': instance.body,
  'stopButton': ?instance.stopButton,
  'icon': ?instance.icon,
  'iconColor': ?_$JsonConverterToJson<String, Color>(
    instance.iconColor,
    const ColorConverter().toJson,
  ),
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
