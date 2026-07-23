# Datenschutzerklärung für SpeedPhone Dialer

Stand: 23.07.2026

Verantwortlich ist die Anesda UG (haftungsbeschränkt), St.-Josefs-Kirchplatz 4, 87700 Memmingen. Kontakt: info@anesda.de.

SpeedPhone Dialer verbindet sich ausschließlich mit der vom Nutzer per QR-Code gekoppelten CRM-SpeedPhone-Instanz. Die App verarbeitet dabei die Serveradresse, eine zufällige Gerätekennung, den Anzeigenamen des CRM-Benutzers sowie kurzfristig die für den Anruf benötigte Telefonnummer und den Namen des Zielkontakts.

Serveradresse, Gerätekennung und Gerätetoken werden verschlüsselt im sicheren Speicher des Betriebssystems abgelegt. Das dauerhafte Gerätetoken wird auf dem CRM-Server nur als SHA-256-Hash gespeichert. Kopplungscodes sind einmalig und zehn Minuten gültig; Anrufaufträge verfallen nach zwei Minuten.

Die Kamera wird nur zum Scannen des Kopplungs-QR-Codes verwendet. Android benötigt die Telefonberechtigung, um einen vom Nutzer im CRM ausgelösten Anruf direkt zu starten. iOS zeigt vor dem Anruf die systemeigene Bestätigung. Es findet keine Gesprächsaufzeichnung statt.

Optional kann der Nutzer unter Android die Erkennung eingehender geschäftlicher Rückrufe aktivieren. Erst nach einer hervorgehobenen Einwilligung fragt die App die Berechtigungen für Telefonstatus und Anrufliste ab. Beim Klingeln wird ausschließlich die eingehende Telefonnummer verarbeitet und verschlüsselt an die gekoppelte Unternehmens-CRM-Instanz übertragen. Dort wird sie mit den für den angemeldeten Mitarbeiter freigegebenen vorhandenen Zielkontakten verglichen. Bei einem Treffer speichert das CRM nur die UUIDs von Gerät, Benutzer und Zielkontakt sowie Eingangs- und Öffnungszeitpunkt; die eingehende Telefonnummer wird nicht in einer zusätzlichen SpeedPhone-Tabelle gespeichert. Nicht zuordenbare Nummern werden nicht als Ereignis gespeichert.

Kann die Nummer nicht sofort übertragen werden, hält Android den Übertragungsauftrag vorübergehend im privaten App-Speicher und löscht ihn nach erfolgreicher Verarbeitung beziehungsweise nach dem Ende der begrenzten Wiederholungsversuche. SpeedPhone Dialer liest keine Gesprächsinhalte, zeichnet keine Anrufe auf und überträgt keine vollständige Anrufhistorie.

Die App enthält keine Werbung, keine Analyse-, Tracking- oder Absturzberichtsdienste und gibt keine Daten an Werbenetzwerke weiter. Daten werden nur zwischen der App und der vom Nutzer gekoppelten CRM-Instanz übertragen.

Eine Kopplung kann jederzeit in der App oder in SpeedPhone getrennt werden. Dadurch wird das Gerätetoken lokal gelöscht beziehungsweise serverseitig deaktiviert. Weitergehende Betroffenenrechte richten sich nach der Datenschutzerklärung und dem Verantwortlichen der jeweiligen CRM-Instanz.
