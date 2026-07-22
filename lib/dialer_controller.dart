import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'models/dialer_models.dart';
import 'services/dialer_api.dart';
import 'services/dialer_bridge.dart';
import 'services/secure_store.dart';

class DialerController extends ChangeNotifier {
  DialerController({
    DialerApi? api,
    SecureStore? store,
    DialerBridge? bridge,
  })  : _api = api ?? DialerApi(),
        _store = store ?? const SecureStore(),
        _bridge = bridge ?? DialerBridge();

  final DialerApi _api;
  final SecureStore _store;
  final DialerBridge _bridge;

  PairedDevice? device;
  DialCommand? lastCommand;
  String status = 'App wird vorbereitet …';
  String? error;
  bool busy = true;
  bool ready = false;
  Timer? _pollTimer;
  bool _polling = false;
  String? _lastHandledCommandId;

  Future<void> initialize() async {
    device = await _store.load();
    busy = false;
    if (device == null) {
      status = 'Noch nicht mit SpeedPhone gekoppelt';
    } else {
      status = 'Verbunden – warte auf Wählauftrag';
      await start();
    }
    notifyListeners();
  }

  Future<void> pair(String qrValue) async {
    busy = true;
    error = null;
    status = 'Gerät wird sicher gekoppelt …';
    notifyListeners();
    try {
      final payload = PairingPayload.parse(qrValue);
      final tokenBytes =
          List<int>.generate(32, (_) => Random.secure().nextInt(256));
      final token = base64UrlEncode(tokenBytes).replaceAll('=', '');
      final tokenHash = sha256.convert(utf8.encode(token)).toString();
      final platform = Platform.isIOS ? 'ios' : 'android';
      final deviceName = Platform.isIOS ? 'iPhone' : 'Android-Smartphone';
      device = await _api.claimPairing(
        payload: payload,
        deviceName: deviceName,
        platform: platform,
        deviceToken: token,
        tokenHash: tokenHash,
      );
      if (device!.deviceId.isEmpty) {
        throw const FormatException('Das CRM hat keine Geräte-ID geliefert.');
      }
      await _store.save(device!);
      status = 'Verbunden – warte auf Wählauftrag';
      await start();
    } catch (exception) {
      error = _friendlyError(exception);
      status = 'Kopplung fehlgeschlagen';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> start() async {
    if (device == null) return;
    ready = true;
    await WakelockPlus.enable();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => pollNow());
    await pollNow();
  }

  Future<void> pause() async {
    ready = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    await WakelockPlus.disable();
    notifyListeners();
  }

  Future<bool> ensurePhonePermission() async {
    final granted = await _bridge.ensurePermission();
    if (!granted) {
      error = 'Ohne Telefonberechtigung kann Android nicht direkt wählen.';
      notifyListeners();
    }
    return granted;
  }

  Future<void> pollNow() async {
    final paired = device;
    if (!ready || paired == null || _polling) return;
    _polling = true;
    try {
      final command = await _api.poll(paired);
      error = null;
      if (command != null && command.id != _lastHandledCommandId) {
        _lastHandledCommandId = command.id;
        lastCommand = command;
        status = 'Wähle ${command.displayName} …';
        notifyListeners();
        await _api.acknowledge(paired, command, 'received');
        try {
          await _bridge.startCall(command.phone);
          await _api.acknowledge(paired, command, 'dialed');
          status = Platform.isIOS
              ? 'Anruf an iOS übergeben – bitte am iPhone bestätigen'
              : 'Anruf wurde gestartet';
        } catch (exception) {
          final message = _friendlyError(exception);
          await _api.acknowledge(paired, command, 'failed', error: message);
          error = message;
          status = 'Anruf konnte nicht gestartet werden';
        }
        notifyListeners();
      }
    } catch (exception) {
      error = _friendlyError(exception);
      status = 'Verbindung zum CRM unterbrochen – neuer Versuch läuft';
      notifyListeners();
    } finally {
      _polling = false;
    }
  }

  Future<void> disconnect() async {
    final paired = device;
    await pause();
    if (paired != null) {
      try {
        await _api.disconnect(paired);
      } catch (_) {
        // Die lokale Kopplung muss auch bei einem vorübergehend unerreichbaren CRM löschbar bleiben.
      }
    }
    await _store.clear();
    device = null;
    lastCommand = null;
    error = null;
    status = 'Noch nicht mit SpeedPhone gekoppelt';
    notifyListeners();
  }

  String _friendlyError(Object exception) {
    final value = exception.toString().replaceFirst(
        RegExp(r'^(StateError|FormatException|PlatformException):\s*'), '');
    return value.length > 220 ? '${value.substring(0, 220)}…' : value;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
