bool hasText(String? value) => value != null && value.trim().isNotEmpty;

String? normalizeAddressField(String? value) {
  if (value == null) return null;
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

String? formatAddressParts({
  String? zip,
  String? country,
  String? state,
  String? city,
  String? neighborhood,
  String? street,
  String? number,
  String? complement,
  String? reference,
}) {
  final primaryParts = [
    if (hasText(street)) street!.trim(),
    if (hasText(number)) number!.trim(),
    if (hasText(neighborhood)) neighborhood!.trim(),
    if (hasText(city)) city!.trim(),
    if (hasText(state)) state!.trim(),
    if (hasText(country)) country!.trim(),
  ];

  final secondaryParts = [
    if (hasText(complement)) complement!.trim(),
    if (hasText(reference)) reference!.trim(),
    if (hasText(zip)) zip!.trim(),
  ];

  final formatted = [
    if (primaryParts.isNotEmpty) primaryParts.join(', '),
    if (secondaryParts.isNotEmpty) secondaryParts.join(' - '),
  ].join(' | ');

  return formatted.isEmpty ? null : formatted;
}
