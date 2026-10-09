import 'dart:io';

import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/infrastructure/config_repository_impl.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String configPath;
  late Map<String, String> env;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('rsx_cfg_');
    configPath = '${tempDir.path}/config.yaml';
    env = <String, String>{};
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  void writeConfig(String content) =>
      File(configPath).writeAsStringSync(content);

  ConfigRepositoryImpl repo() => ConfigRepositoryImpl(
    defaultConfigPath: configPath,
    lookup: (n) => env[n] ?? '',
  );

  final sampleConfig = '''
config:
  outputDir: out
  includeCover: true
  includeFeedback: true
  digestPath: digest
  providers:
    lmstudio:
      url: "http://127.0.0.1:1234"
      default: true
      models:
        - name: "qwen2.5-7b-instruct"
          default: true
        - name: "qwen/qwen2.5-coder-14b"
          settings:
            temperature: 0.8
    openai:
      url: "https://api.openai.com"
      models:
        - name: "gpt-4o-mini"
''';

  test(
    'parses providers and resolves each API key from the environment',
    () async {
      writeConfig(sampleConfig);
      env['RESUMESUX_LMSTUDIO_KEY'] = 'local-key';
      env['RESUMESUX_OPENAI_KEY'] = 'sk-openai';

      final result = await repo().loadConfig().run();
      final config = result.getRight().toNullable();
      expect(config, isNotNull);

      expect(config!.providers.length, 2);
      final lm = config.providers.first;
      expect(lm.name, 'lmstudio');
      expect(lm.url, 'http://127.0.0.1:1234');
      expect(lm.key, 'local-key');
      expect(lm.isDefault, isTrue);
      expect(lm.models.map((m) => m.name), contains('qwen2.5-7b-instruct'));
      expect(lm.models.length, 2);

      final oa = config.providers[1];
      expect(oa.name, 'openai');
      expect(oa.key, 'sk-openai');
      expect(oa.isDefault, isFalse);
    },
  );

  test('resolves an empty key when the env variable is unset', () async {
    writeConfig(sampleConfig);
    final config = (await repo().loadConfig().run()).getRight().toNullable()!;
    expect(config.providers.first.key, isEmpty);
  });

  test('getDefaultProvider honors the isDefault flag', () async {
    writeConfig(sampleConfig);
    final provider = (await repo().getDefaultProvider().run())
        .getRight()
        .toNullable();
    expect(provider?.name, 'lmstudio');
  });

  test('getProvider returns the named provider', () async {
    writeConfig(sampleConfig);
    final provider = (await repo().getProvider(providerName: 'openai').run())
        .getRight()
        .toNullable();
    expect(provider?.name, 'openai');
  });

  test('getDefaultModel returns the model flagged isDefault', () async {
    writeConfig(sampleConfig);
    final model = (await repo().getDefaultModel().run())
        .getRight()
        .toNullable();
    expect(model?.name, 'qwen2.5-7b-instruct');
  });

  test('missing config file returns a ConfigPathFailure', () async {
    final missing = ConfigRepositoryImpl(
      defaultConfigPath: '${tempDir.path}/does-not-exist.yaml',
      lookup: (n) => env[n] ?? '',
    );
    final result = await missing.loadConfig().run();
    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<ConfigPathFailure>());
  });
}
