/// Normalized exception thrown by the API layer.
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final Object? details;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
