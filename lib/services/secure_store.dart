import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/dialer_models.dart';

class SecureStore {
  const SecureStore(
      {FlutterSecureStorage storage = const FlutterSecureStorage()})
      : _storage = storage;

  final FlutterSecureStorage _storage;

  static const _server = 'server';
  static const _deviceId = 'device_id';
  static const _deviceToken = 'device_token';
  static const _userName = 'user_name';
  static const _deviceName = 'device_name';

  Future<PairedDevice?> load() async {
    final values = await _storage.readAll();
    final server = Uri.tryParse(values[_server] ?? '');
    if (server == null || server.scheme != 'https') return null;
    final id = values[_deviceId] ?? '';
    final token = values[_deviceToken] ?? '';
    if (id.isEmpty || token.isEmpty) return null;
    return PairedDevice(
      server: server,
      deviceId: id,
      deviceToken: token,
      userName: values[_userName] ?? 'CRM-Benutzer',
      deviceName: values[_deviceName] ?? 'Smartphone',
    );
  }

  Future<void> save(PairedDevice device) async {
    await _storage.write(key: _server, value: device.server.toString());
    await _storage.write(key: _deviceId, value: device.deviceId);
    await _storage.write(key: _deviceToken, value: device.deviceToken);
    await _storage.write(key: _userName, value: device.userName);
    await _storage.write(key: _deviceName, value: device.deviceName);
  }

  Future<void> clear() => _storage.deleteAll();
}
