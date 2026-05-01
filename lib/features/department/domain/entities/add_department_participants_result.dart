class AddDepartmentParticipantsResult {
  const AddDepartmentParticipantsResult({
    required this.successCount,
    required this.failureCount,
  });

  final int successCount;
  final int failureCount;

  bool get hasSuccess => successCount > 0;

  bool get hasFailures => failureCount > 0;
}
