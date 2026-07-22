import 'package:flutter_test/flutter_test.dart';
import 'package:speedphone_dialer/models/dialer_models.dart';

void main() {
  group('PairingPayload', () {
    test('übernimmt HTTPS-Server und Einmal-Token aus dem SpeedPhone-QR-Code',
        () {
      final payload = PairingPayload.parse(
        'speedphone://pair?v=1&server=https%3A%2F%2Fcrm.example.org%2Flegacy%2Findex.php%3FentryPoint%3Ddialer&token=abcdefghijklmnopqrstuvwxyzABCDEFG_1234567890',
      );
      expect(payload.server.host, 'crm.example.org');
      expect(payload.server.queryParameters['entryPoint'], 'dialer');
      expect(payload.pairingToken, startsWith('abcdefghijklmnopqrstuvwxyz'));
    });

    test('lehnt unsichere Serveradressen ab', () {
      expect(
        () => PairingPayload.parse(
          'speedphone://pair?server=http%3A%2F%2Fcrm.example.org%2Fapi&token=abcdefghijklmnopqrstuvwxyzABCDEFG_1234567890',
        ),
        throwsFormatException,
      );
    });
  });

  group('DialCommand', () {
    test('akzeptiert eine normalisierte Telefonnummer', () {
      final command = DialCommand.fromJson({
        'id': 'command-id',
        'prospect_id': 'prospect-id',
        'display_name': 'Beispielbetrieb',
        'phone': '+49381234567',
      });
      expect(command.phone, '+49381234567');
    });

    test('lehnt Steuerzeichen und Wählcodes ab', () {
      expect(
        () => DialCommand.fromJson({
          'id': 'command-id',
          'prospect_id': 'prospect-id',
          'display_name': 'Beispielbetrieb',
          'phone': '*21*123#',
        }),
        throwsFormatException,
      );
    });
  });
}
