class ChurchLinkReadModel {
  const ChurchLinkReadModel({
    required this.id,
    required this.label,
    required this.url,
  });

  factory ChurchLinkReadModel.fromJson(Map<String, dynamic> json) {
    return ChurchLinkReadModel(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
    );
  }

  final String id;
  final String label;
  final String url;
}

class ChurchLinkRequestModel {
  const ChurchLinkRequestModel({required this.label, required this.url});

  final String label;
  final String url;

  Map<String, dynamic> toJson() => {'label': label, 'url': url};
}
