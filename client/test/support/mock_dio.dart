import 'dart:async';

import 'package:dio/dio.dart';

typedef MockDioHandler =
    FutureOr<Response<dynamic>> Function(RequestOptions requestOptions);

Dio createMockDio(MockDioHandler mockHandler) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:8000',
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final response = await mockHandler(options);
          handler.resolve(response);
        } on DioException catch (error) {
          handler.reject(error);
        }
      },
    ),
  );

  return dio;
}

Response<dynamic> mockResponse(
  RequestOptions requestOptions, {
  dynamic data,
  int statusCode = 200,
}) {
  return Response<dynamic>(
    requestOptions: requestOptions,
    data: data,
    statusCode: statusCode,
  );
}

DioException mockBadResponse(
  RequestOptions requestOptions, {
  dynamic data,
  int statusCode = 400,
}) {
  return DioException.badResponse(
    statusCode: statusCode,
    requestOptions: requestOptions,
    response: Response<dynamic>(
      requestOptions: requestOptions,
      data: data,
      statusCode: statusCode,
    ),
  );
}
