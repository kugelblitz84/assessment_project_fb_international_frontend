Map<String, dynamic> jsonObject(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected a JSON object.');
  }
  return value;
}

List<T> jsonList<T>(Object? value, T Function(Map<String, dynamic>) decode) {
  if (value is! List) throw const FormatException('Expected a JSON array.');
  return List.unmodifiable(value.map((row) => decodeJson(row, decode)));
}

/// Scope cast/enum failures to the response decoder. A TypeError elsewhere is
/// a programming failure and must not be mistaken for malformed server data.
T decodeJson<T>(Object? value, T Function(Map<String, dynamic>) decode) {
  final json = jsonObject(value);
  try {
    return decode(json);
  } on TypeError {
    throw const FormatException('Invalid response fields.');
  } on ArgumentError {
    throw const FormatException('Invalid response value.');
  }
}
