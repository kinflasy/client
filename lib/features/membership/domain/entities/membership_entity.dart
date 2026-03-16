import 'package:equatable/equatable.dart';

class MembershipEntity extends Equatable {
  const MembershipEntity({
    required this.id,
    required this.unitId,
    required this.affiliation,
  });

  final String id;
  final String unitId;
  final String affiliation;

  @override
  List<Object?> get props => [id, unitId, affiliation];
}