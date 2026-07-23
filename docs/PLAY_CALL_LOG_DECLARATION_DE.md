# Google-Play-Berechtigungserklärung: Anrufliste

## Kernfunktion

SpeedPhone Dialer ist eine Begleit-App für ein geschäftliches Unternehmens-CRM. Mitarbeiter koppeln die App über einen kurzlebigen QR-Code mit ihrem persönlichen, vom Unternehmen freigeschalteten CRM-Benutzer. Die App startet CRM-Anrufe und ordnet eingehende geschäftliche Rückrufe automatisch einem bereits vorhandenen CRM-Zielkontakt zu, damit dessen Informationen während des Telefonats im geöffneten Portal verfügbar sind.

## Angeforderte Berechtigungen

- `READ_PHONE_STATE`: Erkennen des Zustands „eingehender Anruf“.
- `READ_CALL_LOG`: Bereitstellung der eingehenden Telefonnummer durch Android für die CRM-Zuordnung.

Die App fordert weder `WRITE_CALL_LOG` noch SMS-, Kontakt- oder Mikrofonberechtigungen an.

## Verwendung der Daten

- Die Berechtigungen werden erst nach einer hervorgehobenen Einwilligung innerhalb der App angefragt.
- Beim Klingeln wird ausschließlich die aktuelle eingehende Nummer gelesen.
- Die Nummer wird per HTTPS ausschließlich an die zuvor gekoppelte Unternehmens-CRM-Instanz übertragen.
- Die CRM-API authentifiziert das Gerät mit einem zufälligen Gerätetoken und beschränkt die Suche auf Zielkontakte, für die der gekoppelte Mitarbeiter berechtigt ist.
- Es werden keine Gesprächsinhalte, keine vollständige Anrufhistorie und keine Nummern für Werbung oder Profilbildung verarbeitet.
- Nicht zuordenbare Nummern werden nicht als SpeedPhone-Ereignis gespeichert.

## Passender Google-Play-Ausnahmefall

„Enterprise archive, business & enterprise customer relationship management (CRM), and/or enterprise device management“ – geschäftliches CRM mit unternehmensseitig freigeschaltetem Benutzerzugang.
