import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assessment_project_fb_international_frontend/core/network/interceptors/auth_interceptor.dart';
import 'package:assessment_project_fb_international_frontend/core/network/request_access.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/token_refresh_coordinator.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/model/assistant_message_model.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/model/assistant_recommendation.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/model/assistant_request_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/assistant/service/assistant_service.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/service/service_catalog_service.dart';

import 'support/session_fakes.dart';

const serviceId = '11111111-1111-4111-8111-111111111111';
const categoryId = '22222222-2222-4222-8222-222222222222';
const messageId = '33333333-3333-4333-8333-333333333333';
Map<String, dynamic> answer() => {
  'id': messageId,
  'role': 'assistant',
  'text': 'Explore this package.',
  'actions': [
    {'type': 'serviceDetails', 'serviceId': serviceId},
    {'type': 'browseServices', 'categoryId': categoryId},
  ],
};

void main() {
  test(
    'strict assistant deserialization rejects routes, foreign action fields and invalid roles',
    () {
      expect(AssistantMessageModel.fromJson(answer()).actions.length, 2);
      for (final invalid in [
        {...answer(), 'role': 'system'},
        {...answer(), 'text': ''},
        {...answer(), 'url': '/admin'},
        {
          ...answer(),
          'actions': [
            {'type': 'serviceDetails', 'serviceId': 'invented'},
          ],
        },
        {
          ...answer(),
          'actions': [
            {
              'type': 'serviceDetails',
              'serviceId': serviceId,
              'categoryId': categoryId,
            },
          ],
        },
        {
          ...answer(),
          'actions': [
            {'type': 'browseServices', 'url': 'https://evil.invalid'},
          ],
        },
        {
          ...answer(),
          'actions': [
            {'type': 'navigate', 'serviceId': serviceId},
          ],
        },
      ]) {
        expect(
          () => AssistantMessageModel.fromJson(invalid),
          throwsFormatException,
        );
      }
    },
  );
  test('history sends bounded recent messages with the final user intact', () {
    final messages = List.generate(
      21,
      (i) => AssistantMessageModel(
        id: '$i',
        role: i.isEven ? AssistantRole.user : AssistantRole.assistant,
        text: 'x' * 2000,
      ),
    );
    final payload =
        AssistantRequestPayload(messages: messages).toJson()['messages']
            as List;
    expect(payload.length, lessThanOrEqualTo(12));
    expect(
      payload.fold<int>(0, (n, item) => n + (item['content'] as String).length),
      lessThanOrEqualTo(12000),
    );
    expect(payload.last['role'], 'user');
  });
  test(
    'live assistant and catalog resolve real UUID recommendations without demo data',
    () async {
      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://localhost:3000/api/v1',
          responseType: ResponseType.json,
        ),
      );
      final adapter = _Adapter();
      dio.httpClientAdapter = adapter;
      final catalog = await ServiceCatalogService(dio).getServices();
      expect(adapter.last!.path, '/services');
      expect(catalog.single.isPackage, true);
      expect(catalog.single.price, 1400);
      expect(catalog.single.originalPrice, 1600);
      final reply = await AssistantService(dio).send(
        const AssistantRequestPayload(
          messages: [
            AssistantMessageModel(
              id: 'user',
              role: AssistantRole.user,
              text: 'Suggest car care',
            ),
          ],
        ),
      );
      expect(adapter.last!.path, '/assistant/chat');
      expect(adapter.last!.extra[requestAccessKey], RequestAccess.optional);
      final sent = adapter.last!.data is String
          ? jsonDecode(adapter.last!.data as String)
          : adapter.last!.data;
      expect(sent, {
        'messages': [
          {'role': 'user', 'content': 'Suggest car care'},
        ],
      });
      expect(
        resolveRecommendations(reply.actions, {serviceId: catalog.single}),
        hasLength(2),
      );
      dio.close(force: true);
    },
  );
  test(
    'optional assistant transport supports guests and attaches a signed-in token',
    () async {
      for (final token in [null, 'saved-token']) {
        final storage = MemoryTokenStorage(token);
        final dio = Dio(
          BaseOptions(
            baseUrl: 'http://localhost:3000/api/v1',
            responseType: ResponseType.json,
          ),
        );
        final adapter = _Adapter();
        dio.httpClientAdapter = adapter;
        dio.interceptors.add(
          AuthInterceptor(
            tokenStorage: storage,
            coordinator: TokenRefreshCoordinator(
              storage,
              () async => 'renewed',
              () async {},
            ),
            apiBaseUri: Uri.parse('http://localhost:3000/api/v1'),
            dio: dio,
          ),
        );
        await AssistantService(dio).send(
          const AssistantRequestPayload(
            messages: [
              AssistantMessageModel(
                id: 'user',
                role: AssistantRole.user,
                text: 'Suggest car care',
              ),
            ],
          ),
        );
        expect(
          adapter.last!.headers['Authorization'],
          token == null ? null : 'Bearer saved-token',
        );
        dio.close(force: true);
      }
    },
  );
}

class _Adapter implements HttpClientAdapter {
  RequestOptions? last;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    final body = options.path == '/services'
        ? [
            {
              'id': serviceId,
              'name': 'Express Car Care',
              'description': 'Demo package',
              'categoryId': categoryId,
              'categoryName': 'Packages',
              'price': 1400,
              'originalPrice': 1600,
              'type': 'PACKAGE',
              'currency': 'BDT',
              'durationMinutes': 105,
              'available': true,
              'inclusions': <String>[],
            },
          ]
        : answer();
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
