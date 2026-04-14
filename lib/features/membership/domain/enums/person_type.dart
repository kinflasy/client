enum PersonType {
  user,
  inactive;

  static PersonType fromApi(String value) {
    return switch (value.toUpperCase()) {
      'USER' => PersonType.user,
      'INACTIVE' => PersonType.inactive,
      _ => throw FormatException('Tipo de pessoa invalido: $value'),
    };
  }
}
