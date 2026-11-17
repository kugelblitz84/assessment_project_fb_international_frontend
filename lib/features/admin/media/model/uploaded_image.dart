class UploadedImage {
  UploadedImage.fromJson(Map<String, dynamic> json) {
    final imageUrl = json['imageUrl'];
    if (imageUrl is! String) throw const FormatException('Missing image URL.');
    final uri = Uri.tryParse(imageUrl);
    if (uri == null ||
        !{'https', 'http'}.contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw const FormatException('Invalid image URL.');
    }
    url = imageUrl;
  }
  late final String url;
}
