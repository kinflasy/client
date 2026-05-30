class CalendarEventScaleRequestModel {
  const CalendarEventScaleRequestModel({required this.lineupId});

  final String lineupId;

  Map<String, dynamic> toJson() => {'lineupId': lineupId};
}
