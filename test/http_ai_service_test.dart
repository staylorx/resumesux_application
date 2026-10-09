import 'dart:convert';
import 'dart:io';

import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/infrastructure/http_ai_service.dart';
import 'package:test/test.dart';

void main() {
  test(
    'generateContent POSTs /v1/chat/completions and returns the content',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final requests = <HttpRequest>[];
      server.listen((req) async {
        requests.add(req);
        final body =
            jsonDecode(await utf8.decoder.bind(req).join())
                as Map<String, dynamic>;
        expect(body['model'], 'qwen2.5-7b-instruct');
        expect((body['messages'] as List).first['content'], 'Hello');
        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType.json;
        req.response.write(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'Hi there!'},
              },
            ],
          }),
        );
        await req.response.close();
      });

      final service = HttpAiService(
        baseUrl: 'http://127.0.0.1:${server.port}',
        apiKey: 'sk-test',
        model: 'qwen2.5-7b-instruct',
      );

      final result = await service.generateContent(prompt: 'Hello').run();
      expect(result.getRight().toNullable(), 'Hi there!');

      final req = requests.single;
      expect(req.uri.path, '/v1/chat/completions');
      expect(req.method, 'POST');
      expect(req.headers.value('Authorization'), 'Bearer sk-test');

      await server.close(force: true);
    },
  );

  test('surfaces a ServiceFailure on a non-200 response', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      req.response.statusCode = 503;
      req.response.write('unavailable');
      await req.response.close();
    });

    final service = HttpAiService(
      baseUrl: 'http://127.0.0.1:${server.port}',
      apiKey: 'sk-test',
      model: 'm',
    );
    final result = await service.generateContent(prompt: 'x').run();
    expect(result.getLeft().toNullable(), isA<ServiceFailure>());
    await server.close(force: true);
  });

  test('surfaces a ParsingFailure when content is missing', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      req.response.statusCode = 200;
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({'choices': <Object>[]}));
      await req.response.close();
    });

    final service = HttpAiService(
      baseUrl: 'http://127.0.0.1:${server.port}',
      apiKey: 'sk-test',
      model: 'm',
    );
    final result = await service.generateContent(prompt: 'x').run();
    expect(result.getLeft().toNullable(), isA<ParsingFailure>());
    await server.close(force: true);
  });
}
