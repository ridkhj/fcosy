class ApiErrorFormatter {
  ApiErrorFormatter._();

  static String format(
    dynamic data, {
    required String fallbackMessage,
  }) {
    if (data == null) return fallbackMessage;

    final normalized = _normalize(data);
    if (normalized == null || normalized.isEmpty) {
      return fallbackMessage;
    }

    return normalized;
  }

  static String? _normalize(dynamic value, {String? parentKey}) {
    if (value == null) return null;

    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    if (value is List) {
      final parts = value
          .map((item) => _normalize(item, parentKey: parentKey))
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toList();

      if (parts.isEmpty) return null;
      return parts.join('\n');
    }

    if (value is Map) {
      final parts = <String>[];

      for (final entry in value.entries) {
        final key = entry.key.toString();
        final normalizedValue = _normalize(entry.value, parentKey: key);

        if (normalizedValue == null || normalizedValue.isEmpty) {
          continue;
        }

        if (_shouldPrefixKey(key, entry.value)) {
          parts.add('$key: $normalizedValue');
        } else {
          parts.add(normalizedValue);
        }
      }

      if (parts.isEmpty) return null;
      return parts.join('\n');
    }

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static bool _shouldPrefixKey(String key, dynamic value) {
    if (key == 'detail' || key == 'message' || key == 'non_field_errors') {
      return false;
    }

    return value is! Map;
  }
}
