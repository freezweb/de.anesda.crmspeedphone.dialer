import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/dialer_models.dart';

class DialerApi {
  DialerApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<PairedDevice> claimPairing({
    required PairingPayload payload,
    required String deviceName,
    required String platform,
    required String deviceToken,
    required String tokenHash,
  }) async {
    final data = await _post(payload.server, {
      'operation': 'claim_pairing',
      'pairing_token': payload.pairingToken,
      'device_name': deviceName,
      'platform': platform,
      'device_token_hash': tokenHash,
    });
    return PairedDevice(
      server: payload.server,
      deviceId: data['device_id']?.toString() ?? '',
      deviceToken: deviceToken,
      userName: data['user_name']?.toString() ?? 'CRM-Benutzer',
      deviceName: deviceName,
    );
  }

  Future<DialCommand?> poll(PairedDevice device) async {
    final data = await _post(device.server, {
      'operation': 'poll',
      'device_id': device.deviceId,
      'device_token': device.deviceToken,
    });
    final command = data['command'];
    return command is Map<String, dynamic>
        ? DialCommand.fromJson(command)
        : null;
  }

  Future<void> acknowledge(
    PairedDevice device,
    DialCommand command,
    String status, {
    String error = '',
  }) async {
    await _post(device.server, {
      'operation': 'ack',
      'device_id': device.deviceId,
      'device_token': device.deviceToken,
      'command_id': command.id,
      'status': status,
      'error': error,
    });
  }

  Future<void> disconnect(PairedDevice device) async {
    await _post(device.server, {
      'operation': 'disconnect',
      'device_id': device.deviceId,
      'device_token': device.deviceToken,
    });
  }

  Future<Map<String, dynamic>> _post(Uri uri, Map<String, String> body) async {
    final response = await _client
        .post(
          uri,
          headers: const {
            'Accept': 'application/json',
            'X-SpeedPhone-Dialer': '1'
          },
          body: body,
        )
        .timeout(const Duration(seconds: 15));
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          'Der CRM-Server hat eine ungültige Antwort gesendet.');
    }
    if (response.statusCode >= 400 || decoded['success'] != true) {
      throw StateError(decoded['error']?.toString() ??
          'Die CRM-Anfrage ist fehlgeschlagen.');
    }
    final data = decoded['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }
}
