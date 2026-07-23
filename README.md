# SpeedPhone Dialer

SpeedPhone Dialer ist die mobile Begleit-App für das offene SuiteCRM-Modul [CRM SpeedPhone](https://github.com/freezweb/de.anesda.crmspeedphone). Ein Klick im CRM startet die dort hinterlegte Telefonnummer auf dem gekoppelten Smartphone, ohne Nummern abzutippen.

## Funktionsweise

- Die App wird über einen zehn Minuten gültigen Einmal-QR-Code mit dem angemeldeten SpeedPhone-Benutzer gekoppelt.
- Der QR-Code überträgt Serveradresse und Einmalcode, jedoch keine CRM-Anmeldedaten.
- Ein dauerhaftes 256-Bit-Gerätetoken wird auf dem Smartphone erzeugt, dort sicher gespeichert und auf dem Server nur als SHA-256-Hash abgelegt.
- Anrufaufträge verfallen nach zwei Minuten und referenzieren den vorhandenen CRM-Zielkontakt über dessen UUID.
- Android startet nach erteilter Telefonberechtigung direkt den Anruf.
- Android erkennt nach ausdrücklicher Freigabe eingehende Rückrufe und meldet die Nummer ausschließlich an das gekoppelte Unternehmens-CRM. Das geöffnete SpeedPhone-Portal zeigt daraufhin automatisch den vorhandenen Zielkontakt.
- iOS öffnet die Telefonfunktion; die von Apple vorgeschriebene Bestätigung muss am Gerät erfolgen.
- Die App muss geöffnet bleiben. Sie hält dafür den Bildschirm aktiv und fragt alle zwei Sekunden nach einem Auftrag.

## Voraussetzungen

- CRM SpeedPhone ab Version 1.5.0
- Android 7.0 oder neuer beziehungsweise iOS 15 oder neuer
- HTTPS-Zugriff auf die SuiteCRM-Instanz

## Entwicklung

```text
flutter pub get
dart run flutter_launcher_icons
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug
```

Paketname und Bundle-ID: `de.anesda.crmspeedphone.dialer`

## Datenschutz

Die App besitzt kein eigenes Benutzerkonto, kein Tracking und keine Werbung. Details stehen in [docs/DATENSCHUTZ.md](docs/DATENSCHUTZ.md).

Die optionale Android-Rückruf-Erkennung benötigt `READ_PHONE_STATE` und `READ_CALL_LOG`. Die Berechtigungen werden erst nach einer hervorgehobenen Einwilligung angefragt und ausschließlich für die Zuordnung eingehender geschäftlicher Anrufe im gekoppelten CRM verwendet.

## Lizenz

MIT-Lizenz. Copyright © 2026 Anesda UG (haftungsbeschränkt), Memmingen.
