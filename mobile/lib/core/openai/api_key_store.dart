import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Securely persists the user's OpenAI API key in the platform keystore
/// (Android Keystore / iOS Keychain). The app has no backend, so the key
/// lives only on-device and is sent directly to the OpenAI API.
class ApiKeyStore {
  static const _key = 'openai_api_key';

  final FlutterSecureStorage _storage;

  ApiKeyStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> read() => _storage.read(key: _key);

  Future<void> write(String value) => _storage.write(key: _key, value: value.trim());

  Future<void> delete() => _storage.delete(key: _key);

  Future<bool> hasKey() async {
    final v = await read();
    return v != null && v.trim().isNotEmpty;
  }
}

final apiKeyStoreProvider = Provider<ApiKeyStore>((ref) => ApiKeyStore());
