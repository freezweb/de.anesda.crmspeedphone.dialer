class PairingPayload {
  const PairingPayload({required this.server, required this.pairingToken});

  final Uri server;
  final String pairingToken;

  factory PairingPayload.parse(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.scheme != 'speedphone' || uri.host != 'pair') {
      throw const FormatException(
          'Dieser QR-Code gehört nicht zu CRM SpeedPhone.');
    }
    final serverValue = uri.queryParameters['server'] ?? '';
    final token = uri.queryParameters['token'] ?? '';
    final server = Uri.tryParse(serverValue);
    if (server == null || server.scheme != 'https' || server.host.isEmpty) {
      throw const FormatException(
          'Der QR-Code enthält keine sichere Serveradresse.');
    }
    if (!RegExp(r'^[A-Za-z0-9_-]{32,128}$').hasMatch(token)) {
      throw const FormatException(
          'Das Kopplungsgeheimnis ist ungültig oder unvollständig.');
    }
    return PairingPayload(server: server, pairingToken: token);
  }
}

class PairedDevice {
  const PairedDevice({
    required this.server,
    required this.deviceId,
    required this.deviceToken,
    required this.userName,
    required this.deviceName,
  });

  final Uri server;
  final String deviceId;
  final String deviceToken;
  final String userName;
  final String deviceName;
}

class DialCommand {
  const DialCommand({
    required this.id,
    required this.prospectId,
    required this.displayName,
    required this.phone,
  });

  final String id;
  final String prospectId;
  final String displayName;
  final String phone;

  factory DialCommand.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final prospectId = json['prospect_id']?.toString() ?? '';
    final displayName = json['display_name']?.toString() ?? '';
    final phone = json['phone']?.toString() ?? '';
    if (id.isEmpty ||
        prospectId.isEmpty ||
        !RegExp(r'^\+?[0-9]{5,20}$').hasMatch(phone)) {
      throw const FormatException('Der Wählauftrag vom CRM ist unvollständig.');
    }
    return DialCommand(
      id: id,
      prospectId: prospectId,
      displayName: displayName.isEmpty ? 'CRM-Kontakt' : displayName,
      phone: phone,
    );
  }
}
