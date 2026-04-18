import 'package:slugify/slugify.dart' as slugify_package;

String slugifyValue(String value) {
  final slug = slugify_package.slugify(value).trim().toLowerCase();
  return slug.replaceAll(RegExp(r'-{2,}'), '-');
}
