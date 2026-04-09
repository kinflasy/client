enum EntryMode {
  baptism,
  transfer,
  regress,
  acclaim;

  String toApiString() => name.toUpperCase();

  String toLabel() {
    return switch (this) {
      EntryMode.baptism => 'Batismo',
      EntryMode.transfer => 'Transferência',
      EntryMode.regress => 'Regresso',
      EntryMode.acclaim => 'Aclamação',
    };
  }
}
