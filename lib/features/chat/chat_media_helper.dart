import 'dart:convert';

const String imageMarkerPrefix = '<!--ollama_images:';
const String imageMarkerSuffix = '-->\n';

/// Result of parsing raw message content that may contain serialized images.
class ParsedMessageContent {
  const ParsedMessageContent({
    required this.text,
    this.images,
  });

  final String text;
  final List<String>? images;
}

/// Parses raw message content stored in database, extracting any embedded images.
ParsedMessageContent parseMessageContent(String rawContent) {
  if (rawContent.startsWith(imageMarkerPrefix)) {
    final endIndex = rawContent.indexOf(imageMarkerSuffix);
    if (endIndex != -1) {
      final jsonStr = rawContent.substring(imageMarkerPrefix.length, endIndex);
      final text = rawContent.substring(endIndex + imageMarkerSuffix.length);
      try {
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        final images = decoded.map((e) => e.toString()).toList();
        return ParsedMessageContent(text: text, images: images);
      } catch (_) {
        // In case of corrupt marker, fallback to full text
      }
    }
  }
  return ParsedMessageContent(text: rawContent);
}

/// Formats text and optional base64 image strings for storage in the database.
String formatMessageWithImages(String content, List<String>? images) {
  final trimmed = content.trim();
  if (images == null || images.isEmpty) {
    return trimmed;
  }
  return '$imageMarkerPrefix${jsonEncode(images)}$imageMarkerSuffix$trimmed';
}
