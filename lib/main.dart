import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dialer_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpeedPhoneDialerApp());
}

class SpeedPhoneDialerApp extends StatefulWidget {
  const SpeedPhoneDialerApp({super.key});

  @override
  State<SpeedPhoneDialerApp> createState() => _SpeedPhoneDialerAppState();
}

class _SpeedPhoneDialerAppState extends State<SpeedPhoneDialerApp>
    with WidgetsBindingObserver {
  late final DialerController controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = DialerController()..initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.start();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      controller.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF052F68);
    const cyan = Color(0xFF05BBDD);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SpeedPhone Dialer',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: navy, primary: navy, secondary: cyan),
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
        inputDecorationTheme:
            const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => controller.device == null
            ? PairingScreen(controller: controller)
            : ReadyScreen(controller: controller),
      ),
    );
  }
}

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key, required this.controller});

  final DialerController controller;

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  bool scanning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/icon/app_icon.png',
                      width: 116, height: 116),
                  const SizedBox(height: 24),
                  Text('SpeedPhone Dialer',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Text(
                      'Telefonnummern aus CRM SpeedPhone direkt auf diesem Smartphone wählen.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 28),
                  _InfoCard(
                    icon: Icons.qr_code_2,
                    title: 'Ohne Zugangsdaten koppeln',
                    body:
                        'Öffnen Sie im CRM „Handy koppeln“ und scannen Sie den kurzlebigen QR-Code. Serveradresse und sicheres Einmal-Geheimnis werden automatisch übernommen.',
                  ),
                  const SizedBox(height: 16),
                  if (widget.controller.error != null)
                    _ErrorBanner(widget.controller.error!),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: widget.controller.busy
                        ? null
                        : () => setState(() => scanning = true),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(widget.controller.busy
                        ? widget.controller.status
                        : 'QR-Code im SpeedPhone scannen'),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54)),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                      onPressed: _openPrivacy,
                      child: const Text('Datenschutzinformationen')),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomSheet: scanning
          ? _ScannerSheet(
              onClose: () => setState(() => scanning = false), onCode: _onCode)
          : null,
    );
  }

  Future<void> _onCode(String value) async {
    setState(() => scanning = false);
    await widget.controller.pair(value);
  }
}

class _ScannerSheet extends StatefulWidget {
  const _ScannerSheet({required this.onClose, required this.onCode});

  final VoidCallback onClose;
  final ValueChanged<String> onCode;

  @override
  State<_ScannerSheet> createState() => _ScannerSheetState();
}

class _ScannerSheetState extends State<_ScannerSheet> {
  bool handled = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .72,
      child: Material(
        color: Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            MobileScanner(
              onDetect: (capture) {
                if (handled) return;
                String? value;
                for (final code in capture.barcodes) {
                  if (code.rawValue?.isNotEmpty == true) {
                    value = code.rawValue;
                    break;
                  }
                }
                if (value == null) return;
                handled = true;
                widget.onCode(value);
              },
            ),
            const Positioned(
                left: 24,
                right: 24,
                top: 28,
                child: Text('SpeedPhone-QR-Code in den Rahmen halten',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700))),
            Positioned(
                right: 16,
                top: 16,
                child: IconButton.filled(
                    onPressed: widget.onClose, icon: const Icon(Icons.close))),
          ],
        ),
      ),
    );
  }
}

class ReadyScreen extends StatelessWidget {
  const ReadyScreen({super.key, required this.controller});

  final DialerController controller;

  @override
  Widget build(BuildContext context) {
    final command = controller.lastCommand;
    return Scaffold(
      appBar:
          AppBar(title: const Text('SpeedPhone Dialer'), centerTitle: false),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: controller.error == null
                        ? const Color(0xFFE4F8EF)
                        : const Color(0xFFFFEEEE),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          Icon(
                              controller.error == null
                                  ? Icons.phone_in_talk
                                  : Icons.cloud_off,
                              size: 56,
                              color: controller.error == null
                                  ? const Color(0xFF08784B)
                                  : Colors.red.shade800),
                          const SizedBox(height: 12),
                          Text(controller.status,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          if (controller.error != null) ...[
                            const SizedBox(height: 8),
                            Text(controller.error!, textAlign: TextAlign.center)
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _InfoCard(
                      icon: Icons.verified_user_outlined,
                      title: 'Gekoppelt mit ${controller.device!.userName}',
                      body:
                          '${controller.device!.deviceName}\n${controller.device!.server.host}'),
                  const SizedBox(height: 18),
                  _InfoCard(
                    icon: Platform.isIOS ? Icons.touch_app : Icons.headset_mic,
                    title: Platform.isIOS
                        ? 'iPhone-Bestätigung erforderlich'
                        : 'Bereit für direktes Wählen',
                    body: Platform.isIOS
                        ? 'Apple verlangt vor jedem Telefonat eine Bestätigung auf dem iPhone. Lassen Sie diese App geöffnet und bestätigen Sie den eingeblendeten Anruf.'
                        : 'Lassen Sie diese App geöffnet. Das Display bleibt aktiv; ein Klick im CRM startet den Anruf direkt über das verbundene Headset.',
                  ),
                  if (Platform.isAndroid) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                        onPressed: controller.ensurePhonePermission,
                        icon: const Icon(Icons.admin_panel_settings_outlined),
                        label: const Text('Telefonberechtigung prüfen')),
                  ],
                  if (command != null) ...[
                    const SizedBox(height: 22),
                    Text('Letzter Wählauftrag',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        leading: const Icon(Icons.phone_forwarded),
                        title: Text(command.displayName),
                        subtitle: Text(command.phone)),
                  ],
                  const SizedBox(height: 28),
                  TextButton.icon(
                      onPressed: () => _confirmDisconnect(context),
                      icon: const Icon(Icons.link_off),
                      label: const Text('Kopplung dieses Geräts aufheben')),
                  TextButton(
                      onPressed: _openPrivacy,
                      child: const Text('Datenschutzinformationen')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDisconnect(BuildContext context) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Kopplung aufheben?'),
                content: const Text(
                    'Das CRM kann danach keine Wählaufträge mehr an dieses Smartphone senden.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Abbrechen')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Aufheben'))
                ]));
    if (confirmed == true) await controller.disconnect();
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text(body)
                ]))
          ])));
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Material(
      color: const Color(0xFFFFE8E8),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(text,
              style: TextStyle(
                  color: Colors.red.shade900, fontWeight: FontWeight.w600))));
}

Future<void> _openPrivacy() =>
    launchUrl(Uri.parse('https://anesda.de/datenschutz'),
        mode: LaunchMode.externalApplication);
