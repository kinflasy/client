import 'package:client/features/calendar/domain/entities/person_birthday_entity.dart';
import 'package:client/features/calendar/domain/utils/month_day_utils.dart';

class PersonBirthdayReadModel {
  const PersonBirthdayReadModel({
    required this.id,
    required this.name,
    required this.birthdayMonth,
    required this.birthdayDay,
  });

  factory PersonBirthdayReadModel.fromJson(Map<String, dynamic> json) {
    final birthdayValue = json['birthday']?.toString();
    if (birthdayValue == null || birthdayValue.trim().isEmpty) {
      throw const FormatException('birthday ausente no aniversariante.');
    }

    final birthday = parseMonthDay(birthdayValue);
    return PersonBirthdayReadModel(
      id: json['id']?.toString() ?? '',
      name: _readName(json),
      birthdayMonth: birthday.month,
      birthdayDay: birthday.day,
    );
  }

  final String id;
  final String name;
  final int birthdayMonth;
  final int birthdayDay;

  PersonBirthdayEntity toEntity() {
    return PersonBirthdayEntity(
      id: id,
      name: name,
      birthdayMonth: birthdayMonth,
      birthdayDay: birthdayDay,
    );
  }

  static String _readName(Map<String, dynamic> json) {
    for (final key in const ['name', 'fullName', 'nickname']) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }

    return 'Pessoa sem nome';
  }
}
