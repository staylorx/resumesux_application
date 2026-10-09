import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/services/ai_service.dart';

/// An [AiService] that calls an OpenAI-compatible `/v1/chat/completions`
/// endpoint over HTTP.
///
/// Works for any bring-your-own provider that speaks the OpenAI protocol —
/// LM Studio, Ollama, a hosted gateway, etc. The base URL, model and API key
/// are supplied explicitly (the key typically resolved from the environment by
/// [ConfigRepositoryImpl]).
class HttpAiService implements AiService {
  /// The provider's base URL, e.g. `http://127.0.0.1:1234`.
  final String baseUrl;

  /// The API key sent as a `Bearer` token. May be empty for local providers.
  final String apiKey;

  /// The model identifier to request, e.g. `qwen2.5-7b-instruct`.
  final String model;

  /// Extra per-model request options (e.g. `temperature`).
  final Map<String, dynamic> settings;

  /// The [http.Client] used for requests. Overridable for tests.
  final http.Client _client;

  /// Creates an [HttpAiService] for [model] on the given [baseUrl].
  HttpAiService({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.settings = const {},
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  TaskEither<Failure, String> generateContent({required String prompt}) {
    return TaskEither.tryCatch(() async {
      final uri = Uri.parse(
        '${baseUrl.replaceAll(RegExp(r'/$'), '')}'
        '/v1/chat/completions',
      );
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
      };
      final body = jsonEncode({
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        if (settings['temperature'] is num)
          'temperature': settings['temperature'],
      });

      final response = await _client.post(uri, headers: headers, body: body);
      if (response.statusCode != 200) {
        throw ServiceFailure(
          'Provider returned ${response.statusCode}: ${response.body}',
        );
      }
      return _extractContent(response.body);
    }, _toFailure);
  }

  /// Parses the `choices[0].message.content` field out of an OpenAI-style JSON
  /// response, or throws a [ParsingFailure] if it is missing.
  String _extractContent(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw const ParsingFailure('Provider response was not a JSON object');
    }
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const ParsingFailure('Provider response had no choices');
    }
    final first = choices.first;
    if (first is! Map) {
      throw const ParsingFailure('Provider response choice was not an object');
    }
    final message = first['message'];
    if (message is! Map || message['content'] is! String) {
      throw const ParsingFailure('Provider response had no message content');
    }
    return message['content'] as String;
  }

  Failure _toFailure(Object error, StackTrace stackTrace) {
    if (error is Failure) return error;
    if (error is http.ClientException) {
      return NetworkFailure('AI network error: ${error.message}');
    }
    return ServiceFailure('AI inference failed: $error');
  }
}
