import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/scale/domain/entities/calendar_event_scale_entity.dart';
import 'package:equatable/equatable.dart';

enum DepartmentScaleLineupLoadState { loaded, failed }

class DepartmentScaleWithLineupEntity extends Equatable {
  const DepartmentScaleWithLineupEntity({
    required this.scale,
    required this.lineupState,
    this.lineup,
  });

  final DepartmentCalendarEventScaleEntity scale;
  final DepartmentScaleLineupLoadState lineupState;
  final LineupEntity? lineup;

  bool get hasLineupFailure =>
      lineupState == DepartmentScaleLineupLoadState.failed;

  @override
  List<Object?> get props => [scale, lineupState, lineup];
}
