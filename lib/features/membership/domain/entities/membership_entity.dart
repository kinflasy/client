import 'package:equatable/equatable.dart';

class MembershipEntity extends Equatable {
  const MembershipEntity({
    required this.id,
    required this.unitId,
  });

  final String id;
  final String unitId;

  @override
  List<Object?> get props => [id, unitId];
}