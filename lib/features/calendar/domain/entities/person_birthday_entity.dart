import 'package:equatable/equatable.dart';

class PersonBirthdayEntity extends Equatable {
  const PersonBirthdayEntity({
    required this.id,
    required this.name,
    required this.birthdayMonth,
    required this.birthdayDay,
  });

  final String id;
  final String name;
  final int birthdayMonth;
  final int birthdayDay;

  @override
  List<Object?> get props => [id, name, birthdayMonth, birthdayDay];
}
