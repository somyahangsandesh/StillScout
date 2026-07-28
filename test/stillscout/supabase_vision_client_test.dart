import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stillscout/stillscout/services/vision/providers/supabase_vision_client.dart';
import 'package:stillscout/stillscout/services/vision/vision_scoring_client.dart';

/// Captures the last request Dio attempted to send instead of hitting the
/// network, so we can assert on the JSON payload built by
/// [SupabaseVisionClient] without a real Supabase project.
class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    final body = utf8.encode(
      '{"blur_score":80,"lighting_score":80,'
      '"open_eyes_score":80,"composition_score":80,"summary":"ok"}',
    );
    return ResponseBody.fromBytes(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _CapturingAdapter adapter;
  late HttpClientAdapter originalAdapter;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    _setupSecureStorageMock();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    adapter = _CapturingAdapter();
    originalAdapter = sharedVisionDio.httpClientAdapter;
    sharedVisionDio.httpClientAdapter = adapter;
  });

  tearDown(() {
    sharedVisionDio.httpClientAdapter = originalAdapter;
  });

  group('SupabaseVisionClient payload', () {
    test(
      'scoreFrame always sends device_id and omits app_user_id when '
      'RevenueCat has never been configured',
      () async {
        final client = SupabaseVisionClient();
        await client.scoreFrame(base64Jpeg: 'AAAA');

        final data = adapter.lastOptions?.data as Map<String, dynamic>?;
        expect(data, isNotNull);
        expect(data!['device_id'], isA<String>());
        expect(data['device_id'], isNotEmpty);
        // RevenueCat.getAppUserId() returns null before Purchases.configure()
        // is ever called — the client must not send a bogus/empty claim.
        expect(data.containsKey('app_user_id'), isFalse);
      },
    );

    test(
      'batchScoreFrames always sends device_id and omits app_user_id when '
      'RevenueCat has never been configured',
      () async {
        final client = SupabaseVisionClient();
        await client.batchScoreFrames(
          base64Jpegs: const ['AAAA', 'BBBB'],
          pickCount: 1,
        );

        final data = adapter.lastOptions?.data as Map<String, dynamic>?;
        expect(data, isNotNull);
        expect(data!['device_id'], isA<String>());
        expect(data['images'], hasLength(2));
        expect(data.containsKey('app_user_id'), isFalse);
      },
    );
  });
}

void _setupSecureStorageMock() {
  final store = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async {
      switch (call.method) {
        case 'write':
          store[call.arguments['key'] as String] =
              call.arguments['value'] as String? ?? '';
          return null;
        case 'read':
          return store[call.arguments['key'] as String];
        case 'delete':
          store.remove(call.arguments['key'] as String);
          return null;
        case 'readAll':
          return Map<String, String>.from(store);
        case 'deleteAll':
          store.clear();
          return null;
        case 'containsKey':
          return store.containsKey(call.arguments['key'] as String);
        default:
          return null;
      }
    },
  );
}
