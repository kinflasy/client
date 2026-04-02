enum IntegrationType {
  observer,
  consultant,
  integrant,
  assistant,
  leader;

  static IntegrationType fromString(String value) {
    return switch (value.toUpperCase()) {
      'OBSERVER' => IntegrationType.observer,
      'CONSULTANT' => IntegrationType.consultant,
      'INTEGRANT' => IntegrationType.integrant,
      'ASSISTANT' => IntegrationType.assistant,
      'LEADER' => IntegrationType.leader,
      _ => IntegrationType.observer,
    };
  }
}
