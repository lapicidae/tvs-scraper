# TVSpielfilm.de EPG Scraper

Dieser Python-basierte Scraper ist darauf ausgelegt, EPG-Daten (Electronic Program Guide) von der mobilen Webseite von TVSpielfilm.de zu extrahieren und sie in einem XMLTV- oder JSON-Format auszugeben. Er ist optimiert für die Integration in Systeme wie VDR (Video Disk Recorder) mit dem `epgd`-Daemon, kann aber auch als eigenständiges Tool verwendet werden.

## Funktionen

* **Flexible Kanalauswahl:** Scrapt entweder alle verfügbaren Kanäle oder eine spezifische Liste von Kanälen, die über die Befehlszeile oder eine Datei angegeben werden.

* **Zeitbereichs-Scraping:** Unterstützt das Scraping für einen bestimmten Starttermin oder für eine konfigurierbare Anzahl von Tagen ab dem aktuellen Datum.

* **Erweitertes Caching:** Nutzt ein benutzerdefiniertes In-Memory- und dateibasiertes Caching-System, um abgerufene HTML-Inhalte und verarbeitete JSON-Daten zu speichern, was die Anzahl der Live-Anfragen erheblich reduziert und die Scraping-Geschwindigkeit bei wiederholten Läufen erhöht. Unterstützt Cache-Revalidierung, proaktive Cache-Bereinigung und das Löschen des Caches.

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
Beim **ersten Durchlauf** des Scrapers, insbesondere wenn viele Kanäle und Tage gescrapt werden, kann die Ausführung **sehr lange dauern**. Dies liegt daran, dass der Cache noch leer ist und alle Daten live aus dem Internet abgerufen werden müssen. Die Standard-Cache-Verzögerung (`--cache-ttl`) beträgt 24 Stunden, und der Cache wird standardmäßig im System-Temp-Verzeichnis in einem Unterverzeichnis namens `tvs-cache` (`--cache-dir`) abgelegt.

**Nachfolgende Läufe:**
**Nach dem ersten Durchlauf** werden nachfolgende Scraper-Läufe in der Regel **deutlich** schneller sein. Der Scraper speichert abgerufene HTML-Antworten und verarbeitete JSON-Daten auf der Festplatte. Bei erneuten Anfragen für dieselben URLs oder Daten werden Informationen aus dem Cache geladen, anstatt sie erneut vom Server herunterzuladen oder neu zu verarbeiten, was die Zeit erheblich verkürzt.

**Cache-Konsistenzprüfung:**
Standardmäßig verwendet der Scraper eine robuste Cache-Konsistenzprüfung, die auf `Content-Length` (bei fehlendem 304-Status) und ETag/Last-Modified-Headern basiert. Dies stellt sicher, dass zwischengespeicherte Daten nur verwendet werden, wenn der Remote-Inhalt sich nicht wesentlich geändert hat.

**Proaktive Cache-Bereinigung:**
Der Scraper führt eine proaktive Bereinigung des Caches durch, um veraltete oder nicht mehr relevante Cache-Dateien automatisch zu entfernen. Dies umfasst das Löschen leerer Kanal-Unterverzeichnisse, von Cache-Dateien für Kanäle, die nicht mehr gezielt gescrapt werden, und von Tages-Cache-Dateien, die außerhalb des relevanten Zeitraums liegen. Standardmäßig werden Cache-Dateien für vergangene Tage gelöscht, dieses Verhalten kann mit `--cache-keep` deaktiviert werden.

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

* `--date <DATUM>`: Spezifisches Startdatum für das Scraping im Format `JJJJMMTT` (z.B. `20250523`). Wenn angegeben, wird nur dieser eine Tag gescrapt und `--days` ignoriert. Es sind nur Daten von 'gestern' bis 'heute + 12 Tage' erlaubt.

* `--days <ANZAHL>`: Anzahl der Tage, die gescrapt werden sollen (1-14). Standard: `1`. Dieses Argument wird ignoriert, wenn `--date` angegeben ist.

* `--output-file <DATEI>`: Pfad zur Ausgabedatei. Die Dateierweiterung (`.json` oder `.xml`) wird automatisch hinzugefügt, falls nicht vorhanden. Standard: `tvspielfilm`.

* `--output-format <FORMAT>`: Ausgabeformat: `"xmltv"` oder `"json"`. Standard: `xmltv`.

* `--xmltv-timezone <ZEITZONE>`: Spezifiziert die Zeitzone, die für die XMLTV-Ausgabe verwendet werden soll (z.B. `"Europe/Berlin"`, `"America/New_York"`). Dies beeinflusst die Zeitstempel in der XMLTV-Datei. Standard: `"Europe/Berlin"`.

* `--img-size <GRÖSSE>`: Bildgröße für die extrahierten URLs (`"150"`, `"300"` oder `"600"`). Standard: `600`.

* `--img-check`: Führt eine zusätzliche HEAD-Anfrage durch, um die Gültigkeit der Bild-URLs zu überprüfen. Erhöht die Scraping-Zeit.

* `--log-level <LEVEL>`: Setzt das Logging-Level (`DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`). Standard: `WARNING`.

* `--verbose`: Aktiviert DEBUG-Logging-Ausgabe (überschreibt `--log-level` auf `DEBUG`).

* `--use-syslog`: Sendet Log-Ausgabe an Syslog.

* `--syslog-tag <TAG>`: Bezeichner (Tag) für Syslog-Nachrichten. Standard: `tvs-scraper`.

* `--cache-dir <PFAD>`: Benutzerdefiniertes Verzeichnis für die Cache-Dateien. Standard ist ein Unterverzeichnis `"tvs-cache"` im System-Temp-Verzeichnis.

* `--cache-clear`: Löscht das gesamte Cache-Verzeichnis (einschließlich des Caches für verarbeitete Daten) vor dem Start des Scrapers. Dies löscht alle zwischengespeicherten Antworten.

* `--cache-disable`: Deaktiviert das Caching von verarbeiteten JSON-Daten auf der Festplatte. Standard: `False` (Cache ist aktiviert).

* `--cache-ttl <SEKUNDEN>`: Cache Time To Live in Sekunden. Dies definiert, wie lange eine verarbeitete JSON-Datei als "frisch" gilt und direkt ohne erneutes Scraping des HTMLs verwendet wird. Standard: `24` Stunden (`86400` Sekunden).

* `--cache-validation-tolerance <BYTES>`: Toleranz in Bytes für den `Content-Length`-Vergleich, wenn ETag/Last-Modified keine 304-Antwort liefert. Standard: `5` Bytes.

* `--cache-keep`: Wenn gesetzt, werden Cache-Dateien für vergangene Tage NICHT automatisch gelöscht. Standardmäßig werden Cache-Dateien vergangener Tage gelöscht.

* `--cache-blind-read`: Wenn gesetzt, werden Daten aus dem Cache direkt verwendet, ohne erneut überprüft zu werden, sofern sie vorhanden sind. Dadurch werden Aktualitätsprüfungen und bedingte GET-Anfragen für zwischengespeicherte Inhalte umgangen.

* `--max-workers <ANZAHL>`: Maximale Anzahl gleichzeitiger Worker für das Abrufen von Daten. Standard: `10`.

* `--max-retries <ANZAHL>`: Maximale Anzahl von Wiederholungsversuchen für fehlgeschlagene HTTP-Anfragen (z.B. 429, 5xx, Verbindungsprobleme). Standard: `5`.

* `--min-request-delay <SEKUNDEN>`: Minimale Verzögerung in Sekunden zwischen HTTP-Anfragen (nur für Live-Abrufe). Standard: `0.05`s.

* `--max-concurrent-requests <ANZAHL>`: Maximale Anzahl von gleichzeitigen HTTP-Anfragen. Dies dient als globale Ratenbegrenzung. Standard: `15`.

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

## Serverlast und Fair Use

Der Scraper bietet mehrere Parameter, um die Last auf der Webseite `m.tvspielfilm.de` zu steuern. Eine verantwortungsvolle Nutzung ist entscheidend, um die Verfügbarkeit der Webseite nicht zu beeinträchtigen und nicht als missbräuchliche Aktivität (z.B. Denial-of-Service-Angriff) interpretiert zu werden.

* **`--max-workers`:** Dieser Parameter steuert die Anzahl der gleichzeitigen Worker-Threads, die Daten verarbeiten (z.B. HTML parsen, Details extrahieren). Obwohl er die Gesamtgeschwindigkeit beeinflusst, wird sein direkter Einfluss auf gleichzeitige HTTP-Anfragen durch andere Parameter gesteuert.

  * **Niedrige Werte (z.B. 1-5):** Sehr schonend für den Server in Bezug auf die Verarbeitung, aber der gesamte Scraping-Vorgang dauert länger.

  * **Hohe Werte (z.B. 10+):** Beschleunigt die Datenverarbeitung, aber die tatsächlichen Netzwerkanfragen unterliegen weiterhin den globalen Ratenbegrenzungen.

* **`--min-request-delay`:** Dieser Parameter (Standard: 0.05 Sekunden) definiert eine minimale Verzögerung zwischen einzelnen HTTP-Anfragen. Er ist entscheidend für ein "höfliches" Scraping, um sicherzustellen, dass Ihr Scraper den Server nicht mit schnellen Anfragen überlastet. Eine Verzögerung von 0.5 bis 1.0 Sekunden oder mehr wird für öffentliche Webseiten oft empfohlen.

* **`--max-concurrent-requests`:** Dieser Parameter (Standard: 15) fungiert als globale Ratenbegrenzung für die Gesamtzahl der HTTP-Anfragen, die zu einem bestimmten Zeitpunkt aktiv sein können. Unabhängig von der Einstellung von `--max-workers` stellt dieser Parameter sicher, dass die Gesamtzahl der gleichzeitigen Netzwerkverbindungen zu m.tvspielfilm.de das angegebene Limit nicht überschreitet. Er ist eine kritische Schutzmaßnahme, um eine Überlastung des Servers zu verhindern.

**Empfehlung für faires Scraping:**

1. **Beginnen Sie konservativ:** Starten Sie mit einer moderaten `--max-workers`-Einstellung (z.B. 5-10), einer merklichen `--min-request-delay` (z.B. 0.5 Sekunden) und dem Standardwert für --max-concurrent-requests (15).

2. **Beobachten Sie das Serververhalten:** Achten Sie auf Log-Meldungen wie `HTTP Error 429 (Too Many Requests)` oder ungewöhnlich lange Antwortzeiten. Dies sind Indikatoren für eine Serverüberlastung.

3. **Anpassen der Parameter:**

   * Wenn Sie 429-Fehler erhalten, erhöhen Sie zunächst die `--min-request-delay` oder verringern Sie `--max-concurrent-requests`.

   * Wenn der Scraper stabil läuft und keine Probleme auftreten, können Sie `--max-workers` schrittweise erhöhen oder `--min-request-delay` leicht verringern, aber immer mit Vorsicht. 

   * Passen Sie `--max-concurrent-requests` nur an, wenn Sie die Kapazität des Servers verstehen und eine höhere Parallelität benötigen.

4. **Caching nutzen:** Der aktivierte Cache reduziert die Anzahl der Live-Anfragen erheblich, was die Serverlast minimiert.

Für `m.tvspielfilm.de`, eine größere Medienseite, ist eine Kombination aus einem moderaten `--max-workers` (z.B. 10), einer `--min-request-delay` von mindestens 0.5 Sekunden und dem Standardwert für `--max-concurrent-requests` (15) ein fairer und angemessener Startpunkt.

## Integration mit *vdr-epg-daemon*

Bitte lesen Sie [diese](contrib/vdr-epg-daemon/README.de.md) Informationen.

## Fehlerbehebung

* **Keine Daten extrahiert / Leere Ausgabedatei:**

  * Überprüfen Sie Ihr `--log-level` (verwenden Sie `INFO` oder `DEBUG` für detailliertere Ausgaben).

  * Stellen Sie sicher, dass die angegebenen `--channel-ids` korrekt sind (verwenden Sie `--list-channels` zur Überprüfung).

  * Überprüfen Sie die Internetverbindung und ob TVSpielfilm.de erreichbar ist.

  * Möglicherweise hat sich die HTML-Struktur der Webseite geändert. In diesem Fall müsste der Scraper-Code angepasst werden.

* **`HTTP Error 403 (Forbidden)` oder `429 (Too Many Requests)`:** Dies deutet darauf hin, dass die Webseite Ihre Anfragen blockiert. Der Scraper hat eingebaute Retries und Verzögerungen, aber bei aggressiver Nutzung kann dies weiterhin passieren. Erhöhen Sie den `--min-request-delay` oder reduzieren Sie `--max-workers`.

* **Falsche XMLTV-Ausgabe:** Stellen Sie sicher, dass die Kanal-IDs den von TVSpielfilm.de verwendeten IDs entsprechen.

* **Berechtigungsprobleme:** Stellen Sie sicher, dass das Skript und die Ausgabeverzeichnisse die richtigen Lese- und Schreibberechtigungen haben.

## Entwicklung

Dieser Abschnitt bietet Einblicke für Entwickler, die daran interessiert sind, den Scraper zu erweitern oder zu modifizieren.

### Code-Struktur
Die Kernlogik ist in der Datei `tvs-scraper` gekapselt. Wichtige Komponenten sind:

* **`TvsLeanScraper`-Klasse:** Dies ist die Hauptklasse, die den Scraping-Prozess orchestriert und HTTP-Anfragen, Caching und den gesamten Datenfluss verwaltet.

* **`TvsHtmlParser`-Klasse:** Speziell für das Parsen von HTML-Inhalten von TVSpielfilm.de, enthält alle notwendigen CSS-Selektoren und regulären Ausdrücke.

Die folgenden Methoden und Funktionen sind ebenfalls zentral für den Betrieb des Scrapers:

* **`fetch_url` Methode:** Verantwortlich für das Abrufen von URLs und die Fehlerbehandlung auf HTTP-Ebene. Sie nutzt `functools.lru_cache` für das In-Memory-Caching von HTTP-Antworten und implementiert einen benutzerdefinierten dateibasierten Caching-Mechanismus mit Inhaltskonsistenzprüfungen, einschließlich `Content-Length` (bei fehlendem 304-Status), sowie ETag/Last-Modified. Sie erzwingt explizit die UTF-8-Dekodierung des Antworttextes.

* **`_get_channel_list` Methode:** Extrahiert die Liste der Kanäle und integriert sich mit dem dateibasierten Cache für Kanallistendaten.

* **`_get_daily_cache_filepath` Methode:** Konstruiert den Dateipfad für den täglichen Zeitplan-JSON-Cache.

* **`_load_daily_json_cache` Methode:** Lädt verarbeitete JSON-Daten aus dem täglichen Daten-Cache, zusammen mit ETag, Last-Modified, Content-Length und der Zeitzone, mit der es zwischengespeichert wurde. Prüft, ob die Daten basierend auf ihrem internen Zeitstempel und TTL frisch sind. Löscht auch Cache-Dateien für vergangene Tage (wenn `--keep-past-cache` nicht gesetzt ist) und für Daten, die über `MAX_DAYS_TO_SCRAPE` vom aktuellen Datum entfernt sind.

* **`_save_daily_json_cache` Methode:** Speichert verarbeitete JSON-Daten im täglichen Daten-Cache, einschließlich HTTP-ETag-, Last-Modified-, Content-Length-Headern und der für die XMLTV-Zeitformatierung verwendeten Zeitzone.

* **`_process_channel_day_schedule` Methode:** Eine Hilfsmethode, die den Abruf und das Parsen für einen Tag und Kanal orchestriert, einschließlich der anwendungsspezifischen Retry-Logik und der Interaktion mit dem dateibasierten Cache. Sie priorisiert frische Daten aus dem lokalen JSON-Cache. Wenn diese veraltet oder nicht vorhanden sind, wird ein bedingter HTTP-GET durchgeführt, um nach Updates zu suchen. Wenn die Zeitzone der zwischengespeicherten Daten von der angeforderten abweicht, werden die Zeitstempel neu verarbeitet.

* **`_proactive_cache_cleanup` Methode:** Diese Methode zur proaktiven Bereinigung veralteter oder nicht mehr relevanter Cache-Dateien für alle Kanäle und Daten, einschließlich des Entfernens leerer Kanal-Unterverzeichnisse, von Cache-Dateien für Kanäle, die nicht mehr gezielt gescrapt werden, und von Tages-Cache-Dateien, die außerhalb des relevanten Zeitraums liegen.

* **`generate_xmltv` Funktion:** Erstellt die XMLTV-Ausgabedatei.

Bei Änderungen an der TVSpielfilm.de-Webseite müssen möglicherweise die CSS-Selektoren in der `TvsHtmlParser`-Klasse aktualisiert werden, um die korrekten Elemente zu finden.

### Abhängigkeiten
Stellen Sie sicher, dass alle im Abschnitt [Abhängigkeiten](#abhängigkeiten) aufgeführten Abhängigkeiten installiert sind.

### Protokollierung
Das Skript verwendet Pythons Standard-`logging`-Modul. Sie können die Ausführlichkeit der Protokollierung über Befehlszeilenoptionen (`--log-level` oder `--verbose`) anpassen.

### Mitwirken
Beiträge sind willkommen! Erstellen Sie gerne Issues für Fehlerberichte oder Funktionsanfragen, oder reichen Sie Pull Requests mit Verbesserungen ein.
