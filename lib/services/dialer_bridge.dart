import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/dialer_models.dart';

class DialerBridge {
  static const _channel = MethodChannel('de.anesda.crmspeedphone.dialer/call');

  Future<bool> ensurePermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  Future<void> startCall(String phone) async {
    if (Platform.isAndroid && !await ensurePermission()) {
      throw StateError('Die Telefonberechtigung wurde nicht erteilt.');
    }
    await _channel.invokeMethod<void>('startCall', {'phone': phone});
  }

  Future<void> configureIncomingCalls(PairedDevice device) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('configureIncomingCalls', {
      'server': device.server.toString(),
      'device_id': device.deviceId,
      'device_token': device.deviceToken,
    });
  }

  Future<void> clearIncomingCalls() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('clearIncomingCalls');
  }

  Future<bool> hasIncomingCallPermission() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('incomingCallPermission') ?? false;
  }

  Future<bool> ensureIncomingCallPermission() async {
    if (!Platform.isAndroid) return false;
    final status = await Permission.phone.request();
    return status.isGranted && await hasIncomingCallPermission();
  }
}
