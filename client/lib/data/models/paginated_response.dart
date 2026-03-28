class PaginatedResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  const PaginatedResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromItemJson,
  ) {
    final rawResults = (json['results'] as List<dynamic>? ?? const <dynamic>[]);

    return PaginatedResponse<T>(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: rawResults
          .map((item) => fromItemJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson(
    Map<String, dynamic> Function(T item) toItemJson,
  ) {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results.map(toItemJson).toList(),
    };
  }
}
