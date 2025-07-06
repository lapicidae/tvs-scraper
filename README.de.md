# TVSpielfilm.de EPG Scraper

Dieser Python-basierte Scraper ist darauf ausgelegt, EPG-Daten (Electronic Program Guide) von der mobilen Webseite von TVSpielfilm.de zu extrahieren und sie in einem XMLTV- oder JSON-Format auszugeben. Er ist optimiert für die Integration in Systeme wie VDR (Video Disk Recorder) mit dem `epgd`-Daemon, kann aber auch als eigenständiges Tool verwendet werden.

## Funktionen

* **Flexible Kanalauswahl:** Scrapt entweder alle verfügbaren Kanäle oder eine spezifische Liste von Kanälen, die über die Befehlszeile oder eine Datei angegeben werden.

* **Zeitbereichs-Scraping:** Unterstützt das Scraping für einen bestimmten Starttermin oder für eine konfigurierbare Anzahl von Tagen ab dem aktuellen Datum.

* **Erweitertes Caching:** Nutzt ein benutzerdefiniertes In-Memory-- und dateibasiertes Caching-System, um abgerufene HTML-Inhalte und verarbeitete JSON-Daten zu speichern, was die Anzahl der Live-Anfragen erheblich reduziert und die Scraping-Geschwindigkeit bei wiederholten Läufen erhöht. Unterstützt Cache-Revalidierung, proaktive Cache-Bereinigung und das Löschen des Caches.

* **Parallele Verarbeitung:** Verwendet einen Thread-Pool, um die Sendepläne für Kanäle und Tage gleichzeitig abzurufen, was die Gesamt-Scraping-Zeit erheblich verkürzt.

* **Robuster Retry-Mechanismus:** Implementiert Wiederholungsversuche für Netzwerkfehler (HTTP 429, 5xx, Verbindungsprobleme) sowie für Anwendungsfehler, die während des Parsens des Sendeplans auftreten können.

* **Ausgabeformate:** Generiert EPG-Daten im standardisierten XMLTV-Format (`.xml`) oder als JSON-Array (`.json`).

* **Bild-Validierung:** Optionale Überprüfung der Bild-URLs, um sicherzustellen, dass die Programm-Bilder tatsächlich verfügbar sind.

* **Umfassende Datenextraktion:** Extrahiert detaillierte Programminformationen wie Kurzbeschreibung, Langbeschreibung, Genre, Originaltitel, Land, Jahr, Dauer, FSK, Besetzung, Regisseur, Drehbuch, Kamera, numerische und textuelle Bewertungen sowie IMDb-Bewertungen.

* **XML-Sicherheitsfilter:** Bereinigt alle Textinhalte vor der XMLTV-Ausgabe von ungültigen XML-Zeichen, um die Kompatibilität zu gewährleisten.

* **Syslog-Integration:** Optionale Ausgabe von Log-Nachrichten an Syslog für eine zentrale Protokollierung.

## Installation

### Abhängigkeiten

Der Scraper verwendet hauptsächlich `lxml` für effizientes HTML-Parsing und `cssselect` für die Unterstützung von CSS-Selektoren. Für den Dateizugriff mit Locks wird `portalocker` verwendet. Die Zeitzoneninformationen werden über das standardmäßige `zoneinfo`-Modul (ab Python 3.9) gehandhabt. Er benötigt die folgenden Python-Bibliotheken:

* `requests`
* `lxml`
* `cssselect`
* `portalocker`

Sie können diese mit pip installieren:

```bash
pip install requests lxml cssselect portalocker
```

### Ausführbar machen

Stellen Sie sicher, dass das Skript ausführbar ist:

```bash
chmod +x tvs-scraper
```

Es wird empfohlen, das Skript in einem Verzeichnis zu platzieren, das in Ihrem `PATH` enthalten ist (z.B. `/usr/local/bin/`), oder den vollständigen Pfad zum Skript zu verwenden.

## Cache-Verhalten und Erster Lauf

Der Scraper bietet ein benutzerdefiniertes Caching-System, um die Anzahl der Live-Anfragen an den Server zu minimieren und die Ausführungszeit bei wiederholten Läufen zu beschleunigen. Das Caching von verarbeiteten JSON-Daten ist **standardmäßig aktiviert**.

**Erster Lauf:**
Beim **ersten Durchlauf** des Scrapers, insbesondere wenn viele Kanäle und Tage gescrapt werden, kann die Ausführung **sehr lange dauern**. Dies liegt daran, dass der Cache noch leer ist und alle Daten live aus dem Internet abgerufen werden müssen. Die Standard-Cache-Verzögerung (`--cache-ttl`) beträgt 6 Stunden, und der Cache wird standardmäßig im System-Temp-Verzeichnis in einem Unterverzeichnis namens `tvs-cache` (`--cache-dir`) abgelegt.

**Nachfolgende Läufe:**
**Nach dem ersten Durchlauf** werden nachfolgende Scraper-Läufe in der Regel **deutlich** schneller sein. Der Scraper speichert abgerufene HTML-Antworten und verarbeitete JSON-Daten auf der Festplatte. Bei erneuten Anfragen für dieselben URLs oder Daten werden Informationen aus dem Cache geladen, anstatt sie erneut vom Server herunterzuladen oder neu zu verarbeiten, was die Zeit erheblich verkürzt.

**Cache-Konsistenzprüfung:**
Standardmäßig verwendet der Scraper eine robuste Cache-Konsistenzprüfung, die auf `Content-Length` (bei fehlendem 304-Status) und ETag/Last-Modified-Headern basiert. Dies stellt sicher, dass zwischengespeicherte Daten nur verwendet werden, wenn der Remote-Inhalt sich nicht wesentlich geändert hat.

**Proaktive Cache-Bereinigung:**
Der Scraper führt eine proaktive Bereinigung des Caches durch, um veraltete oder nicht mehr relevante Cache-Dateien (z.B. für vergangene Tage oder zu weit in der Zukunft liegende Daten) automatisch zu entfernen. Dies hilft, die Cache-Größe zu verwalten und die Leistung zu optimieren. Standardmäßig werden Cache-Dateien für vergangene Tage gelöscht, dieses Verhalten kann mit `--cache-keep` deaktiviert werden.

**Potenzielle Verlangsamungen durch Cache:**
In bestimmten Szenarien kann die Nutzung des Caches jedoch auch zu **erheblichen Verlangsamungen** führen. Dies kann passieren, wenn:

* Der Speicherort des Caches (z.B. ein langsames Netzlaufwerk) nicht optimal ist.

* Viele Cache-Einträge abgelaufen sind und eine Revalidierung mit dem Server stattfindet, was trotz Cache zu vielen Live-Anfragen führen kann.

Stellen Sie sicher, dass auf dem Laufwerk, auf dem der Cache gespeichert wird, ausreichend Speicherplatz vorhanden ist. Sie können den Cache jederzeit mit der Option `--cache-clear` leeren.

## Verwendung

Der Scraper wird über die Kommandozeile mit verschiedenen Argumenten gesteuert.

### Allgemeine Syntax

```bash
./tvs-scraper [OPTIONEN]
```

### Wichtige Optionen

* `--list-channels`: Listet alle verfügbaren Kanal-IDs und deren Namen auf und beendet das Skript. Nützlich, um die `channelmap.conf` zu konfigurieren.

* `--channel-ids <IDS>`: Eine kommagetrennte Liste von Kanal-IDs (z.B. `"ARD,ZDF"`). Wenn nicht angegeben, werden alle gefundenen Kanäle gescrapt.

* `--channel-ids-file <DATEI>`: Pfad zu einer Datei, die eine kommagetrennte Liste von Kanal-IDs enthält. Überschreibt `--channel-ids`, falls angegeben.

* `--date <DATUM>`: Spezifisches Startdatum für das Scraping im Format `JJJJMMTT` (z.B. `20250523`). Wenn angegeben, wird nur dieser eine Tag gescrapt und `--days` ignoriert.

* `--days <ANZAHL>`: Anzahl der Tage, die gescrapt werden sollen (1-13). Standard: `0` (bedeutet nur heute). Dieses Argument wird ignoriert, wenn `--date` angegeben ist.

* `--output-file <DATEI>`: Pfad zur Ausgabedatei. Die Dateierweiterung (`.json` oder `.xml`) wird automatisch hinzugefügt, falls nicht vorhanden. Standard: `tvspielfilm`.

* `--output-format <FORMAT>`: Ausgabeformat: `"xmltv"` oder `"json"`. Standard: `xmltv`.

* `--xmltv-timezone <ZEITZONE>`: Spezifiziert die Zeitzone, die für die XMLTV-Ausgabe verwendet werden soll (z.B. `"Europe/Berlin"`, `"America/New_York"`). Dies beeinflusst die Zeitstempel in der XMLTV-Datei. Standard: `"Europe/Berlin"`.

* `--img-size <GRÖSSE>`: Bildgröße für die extrahierten URLs (`"150"`, `"300"` oder `"600"`). Standard: `600`.

* `--img-check`: Führt eine zusätzliche HEAD-Anfrage durch, um die Gültigkeit der Bild-URLs zu überprüfen. Erhöht die Scraping-Zeit.

* `--img-crop-disable`: Wenn gesetzt, deaktiviert dies das standardmäßige 16:9-Bild-Cropping für Bilder ohne vorhandene Crop-Anweisungen.

* `--log-level <LEVEL>`: Setzt das Logging-Level (`DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`). Standard: `WARNING`.

* `--verbose`: Aktiviert DEBUG-Logging-Ausgabe (überschreibt `--log-level` auf `DEBUG`).

* `--use-syslog`: Sendet Log-Ausgabe an Syslog.

* `--syslog-tag <TAG>`: Bezeichner (Tag) für Syslog-Nachrichten. Standard: `tvs-scraper`.

* `--cache-dir <PFAD>`: Benutzerdefiniertes Verzeichnis für die Cache-Dateien. Standard ist ein Unterverzeichnis `"tvs-cache"` im System-Temp-Verzeichnis.

* `--cache-clear`: Löscht das gesamte Cache-Verzeichnis (einschließlich des Caches für verarbeitete Daten) vor dem Start des Scrapers. Dies löscht alle zwischengespeicherten Antworten.

* `--cache-disable`: Deaktiviert das Caching von verarbeiteten JSON-Daten auf der Festplatte. Standard: `False` (Cache ist aktiviert).

* `--cache-ttl <SEKUNDEN>`: Cache Time To Live in Sekunden. Dies definiert, wie lange eine verarbeitete JSON-Datei als "frisch" gilt und direkt ohne erneutes Scraping des HTMLs verwendet wird. Standard: `6` Stunden (`21600` Sekunden).

* `--cache-validation-tolerance <BYTES>`: Toleranz in Bytes für den `Content-Length`-Vergleich, wenn ETag/Last-Modified keine 304-Antwort liefert. Standard: `5` Bytes.

* `--cache-keep`: Wenn gesetzt, werden Cache-Dateien für vergangene Tage NICHT automatisch gelöscht. Standardmäßig werden Cache-Dateien vergangener Tage gelöscht.

* `--max-workers <ANZAHL>`: Maximale Anzahl gleichzeitiger Worker für das Abrufen von Daten. Standard: `[Anzahl der CPU-Kerne] * 5` (z.B. 40 bei 8 Kernen).

* `--max-retries <ANZAHL>`: Maximale Anzahl von Wiederholungsversuchen für fehlgeschlagene HTTP-Anfragen (z.B. 429, 5xx, Verbindungsprobleme). Standard: `5`.

* `--min-request-delay <SEKUNDEN>`: Minimale Verzögerung in Sekunden zwischen HTTP-Anfragen (nur für Live-Abrufe). Standard: `0.05`s.

* `--max-schedule-retries <ANZAHL>`: Maximale Anzahl von Wiederholungsversuchen für Anwendungsfehler während des Parsens/der Generierung des Sendeplans. Standard: `3`.

* `--timeout-http <SEKUNDEN>`: Timeout in Sekunden für alle HTTP-Anfragen (GET, HEAD). Standard: `10`s.

### Beispiele

**Alle Kanäle für heute scrapen und XMLTV ausgeben:**

```bash
./tvs-scraper --output-format xmltv --output-file tvspielfilm.xml --log-level INFO
```

**Spezifische Kanäle (ARD, ZDF) für die nächsten 3 Tage scrapen und JSON ausgeben, mit detailliertem Logging:**

```bash
./tvs-scraper --channel-ids "ARD,ZDF" --days 3 --output-format json --output-file my_epg_data.json --verbose
```

**Sendeplan für einen bestimmten Tag für einen Kanal scrapen und Cache leeren:**

```bash
./tvs-scraper --channel-ids "PRO7" --date 20250601 --cache-clear --output-format xmltv
```

**Scraper in Verbindung mit `run-scraper` und Syslog verwenden:**

Standardmäßig protokolliert das `run-scraper`-Skript seine Ausgaben an Syslog. Um dies zu deaktivieren, verwenden Sie `--disable-syslog`.

```bash
/usr/local/bin/run-scraper --syslog-ident my-epg-script
```

(Beachten Sie, dass `--use-syslog` und `--syslog-ident` für den Python-Scraper selbst sind, während `--disable-syslog` und `--syslog-ident` für das `run-scraper`-Skript sind, wobei das Bash-Skript standardmäßig an Syslog protokolliert.)

## Serverlast und Fair Use (max-workers)

Die Einstellung der `max-workers` hat einen direkten Einfluss auf die Serverlast der Webseite `m.tvspielfilm.de`. Eine verantwortungsvolle Nutzung ist entscheidend, um die Verfügbarkeit der Webseite nicht zu beeinträchtigen und nicht als missbräuchliche Aktivität (z.B. Denial-of-Service-Angriff) interpretiert zu werden.

* **`max-workers`:** Dieser Parameter steuert die Anzahl der gleichzeitigen Anfragen, die Ihr Scraper an den Server sendet.
    * **Niedrige Werte (z.B. 1-5):** Sehr schonend für den Server, aber der Scraping-Vorgang dauert länger.
    * **Hohe Werte (z.B. 10+):** Beschleunigt den Scraping-Vorgang, kann den Server aber stark belasten, insbesondere wenn er nicht für viele gleichzeitige Anfragen ausgelegt ist.

* **`--min-request-delay`:** Dieser Parameter (Standard: `0.05` Sekunden) ist oft wichtiger als `max-workers` allein. Er definiert eine minimale Verzögerung zwischen den einzelnen HTTP-Anfragen. Eine Verzögerung von 0.5 bis 1.0 Sekunden oder mehr ist entscheidend, um den Server nicht zu überfordern.

**Empfehlung für faires Scraping:**

1.  **Beginnen Sie konservativ:** Starten Sie immer mit einer niedrigen Anzahl von Workern (z.B. 5) und einer angemessenen `min-request-delay` (z.B. 0.5 Sekunden).
2.  **Beobachten Sie das Serververhalten:** Achten Sie auf Fehlermeldungen wie `HTTP Error 429 (Too Many Requests)` oder ungewöhnlich lange Antwortzeiten. Diese sind Indikatoren für eine Überlastung.
3.  **Anpassen der Parameter:**
    * Wenn Sie Fehler wie 429 erhalten, erhöhen Sie die `min-request-delay` oder reduzieren Sie die `max-workers`.
    * Wenn der Scraper stabil läuft und keine Probleme auftreten, können Sie die `max-workers` schrittweise erhöhen oder die `min-request-delay` leicht verringern, aber immer mit Vorsicht.
4.  **`robots.txt` beachten:** Obwohl `m.tvspielfilm.de/robots.txt` keine spezifische `Crawl-delay`-Anweisung enthält, gibt sie verbotene Pfade an und schließt bestimmte Bots explizit aus. Halten Sie sich an diese Regeln.
5.  **Caching nutzen:** Der aktivierte Cache reduziert die Anzahl der Live-Anfragen erheblich, was die Serverlast minimiert.

Für `m.tvspielfilm.de`, eine größere Medienseite, ist ein Wert von **5 bis 10 `max-workers` in Kombination mit einer `--min-request-delay` von mindestens 0.5 Sekunden** ein fairer und angemessener Startpunkt. Der Standardwert von `max-workers` ist dynamisch basierend auf der CPU-Anzahl und kann höher sein als 10, aber die allgemeine Empfehlung bleibt gültig.

## Integration mit `epgd` (oder ähnlichen Systemen)

Der Scraper ist darauf ausgelegt, mit dem `epgd`-Daemon zu funktionieren, der typischerweise eine `channelmap.conf` und eine `epgd.conf` verwendet. **Beachten Sie, dass für die Integration mit `epgd` das [xmltv-Plugin](https://github.com/Zabrimus/epgd-plugin-xmltv) auf Ihrem System installiert und aktiviert sein muss.**

**Wichtiger Hinweis zum XMLTV-Plugin und XSLT:**
Die standardmäßige `xmltv.xsl` (bereitgestellt vom [xmltv-Plugin](https://github.com/Zabrimus/epgd-plugin-xmltv/tree/master/configs)) ist möglicherweise nicht darauf ausgelegt, alle vom Scraper extrahierten Felder (z.B. Untertitel, detaillierte Besetzung/Crew, spezielle Bewertungen wie IMDB oder TVSpielfilm-Tipp, Bild-URLs) korrekt zu verarbeiten.
Es kann notwendig sein, eine **[modifizierte xmltv.xsl Datei](contrib/vdr-epg-daemon/configs/xmltv.xsl)** zu verwenden oder eine eigene anzupassen, um diese zusätzlichen Informationen vollständig zu visualisieren und darzustellen. Eine Anpassung der XSLT ist auch erforderlich, um die verschiedenen Bildgrößen (`size="1"`, `size="2"`, `size="3"`) korrekt zu verarbeiten, die der Scraper bereitstellt.

### `channelmap.conf`

Die `channelmap.conf` definiert, welche Kanäle von welchem EPG-Anbieter gescrapt werden sollen. Für diesen Scraper verwenden Sie das Präfix `xmltv:` gefolgt von der Kanal-ID von [TVSpielfilm.de](https://m.tvspielfilm.de/sender/) und der `.tvs`-Endung.

**Beispiel-Eintrag in `channelmap.conf`:**

```
xmltv:ARD.tvs:1 = S19.2E-1-1019-10301 // Das Erste HD
xmltv:ZDF.tvs:1 = S19.2E-1-1011-11110 // ZDF HD
```

* `xmltv`: Der Quellenname, der vom `run-scraper`-Skript erkannt wird.

* `ARD.tvs`: Die Kanal-ID von TVSpielfilm.de (`ARD`) mit der Endung `.tvs`.

* `:1`: Optionale `merge`- und `vps`-Parameter für `epgd`.

### `epgd.conf`

Die `epgd.conf` konfiguriert den `epgd`-Daemon selbst, einschließlich des Pfads zur Ausgabedatei des Scrapers und der Anzahl der Tage, die gescrapt werden sollen.

**Beispiel-Einträge in `epgd.conf`:**

```
xmltv.input = /epgd/cache/tvs_xmltv.xml
DaysInAdvance = 7
UpdateTime = 24
```

* `xmltv.input`: Der Pfad, unter dem der Scraper die XMLTV-Datei ablegt.

* `DaysInAdvance`: Die Anzahl der Tage, die der Scraper im Voraus scrapen soll.

* `UpdateTime`: Die Zeit in Stunden, nach der die EPG-Daten als veraltet gelten und neu gescrapt werden sollten.

### `run-scraper` Skript

Das bereitgestellte `run-scraper`-Skript automatisiert den Aufruf des Python-Scrapers basierend auf den Einstellungen in `epgd.conf` und `channelmap.conf`. Es prüft, ob ein Update der EPG-Daten notwendig ist (z.B. wenn die Ausgabedatei nicht existiert, zu alt ist oder die `channelmap.conf` neuer ist).

**Wichtige Parameter für `run-scraper`:**

* `--disable-syslog`: Deaktiviert die Syslog-Ausgabe des Bash-Skripts.

* `--syslog-ident <TAG>`: Bezeichner (Tag) für Syslog-Nachrichten.

## Fehlerbehebung

* **Keine Daten extrahiert / Leere Ausgabedatei:**

  * Überprüfen Sie Ihr `--log-level` (verwenden Sie `INFO` oder `DEBUG` für detailliertere Ausgaben).

  * Stellen Sie sicher, dass die angegebenen `--channel-ids` korrekt sind (verwenden Sie `--list-channels` zur Überprüfung).

  * Überprüfen Sie die Internetverbindung und ob TVSpielfilm.de erreichbar ist.

  * Möglicherweise hat sich die HTML-Struktur der Webseite geändert. In diesem Fall müsste der Scraper-Code angepasst werden.

* **`HTTP Error 403 (Forbidden)` oder `429 (Too Many Requests)`:** Dies deutet darauf hin, dass die Webseite Ihre Anfragen blockiert. Der Scraper hat eingebaute Retries und Verzögerungen, aber bei aggressiver Nutzung kann dies weiterhin passieren. Erhöhen Sie den `--min-request-delay` oder reduzieren Sie `--max-workers`.

* **Falsche XMLTV-Ausgabe:** Stellen Sie sicher, dass die `channelmap.conf` korrekt ist und die Kanal-IDs den von TVSpielfilm.de verwendeten IDs entsprechen.

* **Berechtigungsprobleme:** Stellen Sie sicher, dass das Skript und die Ausgabeverzeichnisse die richtigen Lese- und Schreibberechtigungen haben.

## Entwicklung

Der Scraper ist in Python geschrieben und verwendet `requests` für HTTP-Anfragen und `lxml.html` mit `cssselect` für das Parsen von HTML.

* **`TvsLeanScraper` Klasse:** Kapselt die gesamte Scraping-Logik.

* **`fetch_url` Methode:** Verantwortlich für das Abrufen von URLs und die Fehlerbehandlung auf HTTP-Ebene. Sie nutzt `functools.lru_cache` für das In-Memory-Caching von HTTP-Antworten und implementiert einen benutzerdefinierten dateibasierten Caching-Mechanismus mit Inhaltskonsistenzprüfungen, einschließlich `Content-Length` (bei fehlendem 304-Status), sowie ETag/Last-Modified.

* **`_get_channel_list` Methode:** Extrahiert die Liste der Kanäle und integriert sich mit dem dateibasierten Cache für Kanallistendaten.

* **`_get_schedule_for_channel_and_date` Methode:** Extrahiert Programminformationen für einen bestimmten Kanal und Tag und integriert sich mit dem dateibasierten Cache für tägliche Sendeplandaten.

* **`parse_program_details` Methode:** Extrahiert zusätzliche Details von den Programm-Detailseiten. Die HTML-Inhalte für Detailseiten profitieren vom In-Memory-Caching der HTTP-Antworten.

* **`_process_channel_day_schedule` Methode:** Eine Hilfsmethode, die den Abruf und das Parsen für einen Tag und Kanal orchestriert, einschließlich der anwendungsspezifischen Retry-Logik und der Interaktion mit dem dateibasierten Cache.

* **`_proactive_cache_cleanup` Methode:** Eine Methode zur proaktiven Bereinigung veralteter oder nicht mehr relevanter Cache-Dateien für alle Kanäle und Daten, einschließlich des Entfernens leerer Kanal-Unterverzeichnisse.

* **`generate_xmltv` Funktion:** Erstellt die XMLTV-Ausgabedatei.

Bei Änderungen an der TVSpielfilm.de-Webseite müssen möglicherweise die CSS-Selektoren in der `TvsHtmlParser`-Klasse aktualisiert werden, um die korrekten Elemente zu finden.
