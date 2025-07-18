# Integration mit `epgd`

Der Scraper ist darauf ausgelegt, mit dem [vdr-epg-daemon](https://github.com/horchi/vdr-epg-daemon) (epgd) zu funktionieren, der typischerweise eine `channelmap.conf` und eine `epgd.conf` verwendet. **Beachten Sie, dass für die Integration mit `epgd` das [xmltv-Plugin](https://github.com/Zabrimus/epgd-plugin-xmltv) auf Ihrem System installiert und aktiviert sein muss.**

**Wichtiger Hinweis zum XMLTV-Plugin und XSLT:**
Die standardmäßige `xmltv.xsl` (bereitgestellt vom [xmltv-Plugin](https://github.com/Zabrimus/epgd-plugin-xmltv/tree/master/configs)) ist möglicherweise nicht darauf ausgelegt, alle vom Scraper extrahierten Felder (z.B. Untertitel, detaillierte Besetzung/Crew, spezielle Bewertungen wie IMDB oder TVSpielfilm-Tipp, Bild-URLs) korrekt zu verarbeiten.
Es kann notwendig sein, eine [**modifizierte xmltv.xsl Datei**](configs/xmltv.xsl) zu verwenden oder eine eigene anzupassen, um diese zusätzlichen Informationen vollständig zu visualisieren und darzustellen. Eine Anpassung der XSLT ist auch erforderlich, um die verschiedenen Bildgrößen (`size="1"`, `size="2"`, `size="3"`) korrekt zu verarbeiten, die der Scraper bereitstellt.

### `run-tvs-scraper` Skript

Das bereitgestellte [run-tvs-scraper](run-tvs-scraper)-Skript automatisiert den Aufruf des Python-Scrapers basierend auf den Einstellungen in `epgd.conf` und `channelmap.conf`. Es prüft, ob ein Update der EPG-Daten notwendig ist (z.B. wenn die Ausgabedatei nicht existiert, zu alt ist oder die `channelmap.conf` neuer ist).

### `channelmap.conf`

Die `channelmap.conf` definiert, welche Kanäle von welchem EPG-Anbieter gescrapt werden sollen. Für diesen Scraper verwenden Sie das Präfix `xmltv:` gefolgt von der Kanal-ID von [TVSpielfilm.de](https://m.tvspielfilm.de/sender/) und der `.tvs`-Endung.

**Beispiel-Eintrag in `channelmap.conf`:**

```
xmltv:ard.tvs = S19.2E-1-1019-10301 // Das Erste HD
xmltv:zdf.tvs = S19.2E-1-1011-11110 // ZDF HD
```

* `xmltv`: Der Quellenname, der vom `run-tvs-scraper`-Skript erkannt wird.

* `ard.tvs`: Die Kanal-ID von TVSpielfilm.de (`ARD`) mit der Endung `.tvs`. **ACHTUNG: Es müssen Kleinbuchstaben verwendet werden!**

### `epgd.conf`

Die `epgd.conf` konfiguriert den `epgd`-Daemon selbst, einschließlich des Pfads zur Ausgabedatei des Scrapers und der Anzahl der Tage, die gescrapt werden sollen.

**Beispiel-Einträge in `epgd.conf`:**

```
xmltv.getdata = /usr/local/bin/run-tvs-scraper
xmltv.input = /path/to/your/tvs_xmltv.xml
DaysInAdvance = 7
UpdateTime = 24
```

* `xmltv.getdata`: Optionales Skript, das zum Abrufen oder Generieren von xmltv-EPG-Daten aufgerufen wird.

* `xmltv.input`: Der Pfad, unter dem der Scraper die XMLTV-Datei ablegt.

* `DaysInAdvance`: Die Anzahl der Tage, die der Scraper im Voraus scrapen soll.

* `UpdateTime`: Die Zeit in Stunden, nach der die EPG-Daten als veraltet gelten und neu gescrapt werden sollten.
