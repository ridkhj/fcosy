import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef MockAdapterHandler =
    FutureOr<ResponseBody> Function(RequestOptions requestOptions);

class MockHttpClientAdapter implements HttpClientAdapter {
  MockHttpClientAdapter(this.handler);

  final MockAdapterHandler handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponseBody(
  dynamic data, {
  int statusCode = 200,
  Map<String, List<String>> headers = const {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: headers,
  );
}
