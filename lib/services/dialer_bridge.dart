import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

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
}
