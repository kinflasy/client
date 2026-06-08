import 'package:equatable/equatable.dart';

enum UserAgendaItemType { event, birthday, personalScale }

sealed class UserAgendaItemEntity extends Equatable {
  const UserAgendaItemEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
  });

  final String id;
  final UserAgendaItemType type;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;

  bool get isUserEvent => type == UserAgendaItemType.personalScale;
}

class UserAgendaEventItemEntity extends UserAgendaItemEntity {
  const UserAgendaEventItemEntity({
    required super.id,
    required super.title,
    required super.startDateTime,
    required super.endDateTime,
    required this.origin,
    this.personalScales = const [],
  }) : super(type: UserAgendaItemType.event);

  final String origin;
  final List<UserAgendaPersonalScaleSummaryEntity> personalScales;

  @override
  bool get isUserEvent => personalScales.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    startDateTime,
    endDateTime,
    origin,
    personalScales,
  ];
}

class UserAgendaBirthdayItemEntity extends UserAgendaItemEntity {
  const UserAgendaBirthdayItemEntity({
    required super.id,
    required DateTime date,
    required this.name,
    this.personId,
  }) : super(
         type: UserAgendaItemType.birthday,
         title: name,
         startDateTime: date,
         endDateTime: date,
       );

  final String name;
  final String? personId;

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    startDateTime,
    endDateTime,
    name,
    personId,
  ];
}

class UserAgendaPersonalScaleItemEntity extends UserAgendaItemEntity {
  const UserAgendaPersonalScaleItemEntity({
    required super.id,
    required super.title,
    required super.startDateTime,
    required super.endDateTime,
    required this.eventId,
    required this.scaleId,
    required this.department,
    required this.roles,
  }) : super(type: UserAgendaItemType.personalScale);

  final String eventId;
  final String scaleId;
  final String department;
  final List<String> roles;

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    startDateTime,
    endDateTime,
    eventId,
    scaleId,
    department,
    roles,
  ];
}

class UserAgendaPersonalScaleSummaryEntity extends Equatable {
  const UserAgendaPersonalScaleSummaryEntity({
    required this.scaleId,
    required this.department,
    required this.roles,
  });

  final String scaleId;
  final String department;
  final List<String> roles;

  @override
  List<Object?> get props => [scaleId, department, roles];
}
