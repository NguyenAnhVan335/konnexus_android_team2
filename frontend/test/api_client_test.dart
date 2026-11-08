import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:konnexus/core/api/api_client.dart';
import 'package:konnexus/core/api/api_exception.dart';

void main() {
  const Map<String, String> jsonHeaders = <String, String>{
    'content-type': 'application/json; charset=utf-8',
  };

  // `http.Response` mặc định mã hoá Latin-1; đặt charset UTF-8 để giữ tiếng Việt.
  http.Response jsonResponse(String body, int statusCode) {
    return http.Response(body, statusCode, headers: jsonHeaders);
  }

  ApiClient buildApi(
    MockClient client, {
    Map<String, String> headers = const <String, String>{},
    void Function()? onUnauthorized,
  }) {
    return ApiClient(
      headersProvider: () => headers,
      httpClient: client,
      baseUrl: 'https://api.test',
      onUnauthorized: onUnauthorized,
    );
  }

  group('ApiClient xử lý 401', () {
    test('gọi onUnauthorized khi request cần xác thực trả 401', () async {
      int calls = 0;
      final ApiClient api = buildApi(
        MockClient((http.Request request) async {
          return jsonResponse('{"message":"Token hết hạn"}', 401);
        }),
        headers: const <String, String>{'Authorization': 'Bearer expired'},
        onUnauthorized: () => calls++,
      );

      await expectLater(
        api.get('/api/users'),
        throwsA(
          isA<ApiException>().having(
              (ApiException error) => error.statusCode, 'statusCode', 401),
        ),
      );
      expect(calls, 1);
    });

    test('không gọi onUnauthorized cho endpoint công khai', () async {
      int calls = 0;
      final ApiClient api = buildApi(
        MockClient((http.Request request) async {
          return jsonResponse('{"message":"Sai tài khoản hoặc mật khẩu"}', 401);
        }),
        onUnauthorized: () => calls++,
      );

      await expectLater(
        api.post(
          '/api/auth/login',
          body: <String, dynamic>{'username': 'user', 'password': 'wrong'},
          authenticated: false,
        ),
        throwsA(isA<ApiException>()),
      );
      expect(calls, 0);
    });

    test('không gọi onUnauthorized với lỗi không phải 401', () async {
      int calls = 0;
      final ApiClient api = buildApi(
        MockClient((http.Request request) async {
          return jsonResponse('{"message":"Lỗi máy chủ"}', 500);
        }),
        onUnauthorized: () => calls++,
      );

      await expectLater(api.get('/api/users'), throwsA(isA<ApiException>()));
      expect(calls, 0);
    });
  });

  group('ApiClient gửi request', () {
    test('gắn header xác thực và bóc lớp data', () async {
      late http.Request captured;
      final ApiClient api = buildApi(
        MockClient((http.Request request) async {
          captured = request;
          return jsonResponse(
            jsonEncode(<String, dynamic>{
              'data': <String, dynamic>{'id': 'user-1'},
            }),
            200,
          );
        }),
        headers: const <String, String>{
          'Authorization': 'Bearer token',
          'X-User-Id': 'user-1',
        },
      );

      final dynamic response = await api.get('/api/users');

      expect(captured.method, 'GET');
      expect(captured.url.toString(), 'https://api.test/api/users');
      expect(captured.headers['Authorization'], 'Bearer token');
      expect(captured.headers['X-User-Id'], 'user-1');
      expect(captured.headers['Accept'], 'application/json');
      expect(
        ApiClient.unwrap(response),
        <String, dynamic>{'id': 'user-1'},
      );
    });

    test('ghép query string và giữ nguyên query có sẵn', () async {
      late Uri captured;
      final ApiClient api = buildApi(
        MockClient((http.Request request) async {
          captured = request.url;
          return http.Response('[]', 200);
        }),
      );

      await api.get(
        '/api/v1/posts',
        query: <String, String>{'page': '0', 'size': '20'},
      );

      expect(captured.queryParameters['page'], '0');
      expect(captured.queryParameters['size'], '20');
    });

    test('lỗi mạng được chuẩn hoá thành ApiException', () async {
      final ApiClient api = buildApi(
        MockClient((http.Request request) async {
          throw http.ClientException('connection refused');
        }),
      );

      await expectLater(
        api.get('/api/users'),
        throwsA(
          isA<ApiException>().having(
              (ApiException error) => error.statusCode, 'statusCode', isNull),
        ),
      );
    });
  });
}
