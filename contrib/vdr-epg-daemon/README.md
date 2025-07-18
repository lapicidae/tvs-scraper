## Integration with `epgd`

The scraper is designed to work with the [vdr-epg-daemon](https://github.com/horchi/vdr-epg-daemon) (epgd) daemon, which typically uses a `channelmap.conf` and an `epgd.conf`. **Note that for integration with `epgd`, the [xmltv-plugin](https://github.com/Zabrimus/epgd-plugin-xmltv) must be installed and activated on your system.**

**Important Note on XMLTV Plugin and XSLT:**
The default `xmltv.xsl` (provided by [xmltv-plugin](https://github.com/Zabrimus/epgd-plugin-xmltv/tree/master/configs)) may not be designed to correctly process all fields extracted by this scraper (e.g., subtitles, detailed cast/crew, special ratings like IMDb or TVSpielfilm's "Tipp", image URLs).
It might be necessary to use a **[modified xmltv.xsl file](configs/xmltv.xsl)** or customize your own to fully visualize and present this additional information. Customizing the XSLT is also required to properly handle the different image sizes (`size="1"`, `size="2"`, `size="3"`) provided by the scraper.

### `run-tvs-scraper` Script

The provided [run-tvs-scraper](run-tvs-scraper) script automates the invocation of the Python scraper based on the settings in `epgd.conf` and `channelmap.conf`. It checks if an update of the EPG data is necessary (e.g., if the output file does not exist, is too old, or the `channelmap.conf` is newer).

### `channelmap.conf`

The `channelmap.conf` defines which channels should be scraped by which EPG provider. For this scraper, use the prefix `xmltv:` followed by the TVSpielfilm.de channel ID and the `.tvs` extension.

**Example entry in `channelmap.conf`:**

```
xmltv:ard.tvs = S19.2E-1-1019-10301 // Das Erste HD
xmltv:zdf.tvs = S19.2E-1-1011-11110 // ZDF HD
```

* `xmltv`: The source name recognized by the `run-tvs-scraper` script.

* `ard.tvs`: The TVSpielfilm.de channel ID (`ARD`) with the `.tvs` extension. **ATTENTION: Lowercase letters must be used!**

### `epgd.conf`

The `epgd.conf` configures the `epgd` daemon itself, including the path to the scraper's output file and the number of days to scrape.

**Example entries in `epgd.conf`:**

```
xmltv.getdata = /usr/local/bin/run-tvs-scraper
xmltv.input = /path/to/your/tvs_xmltv.xml
DaysInAdvance = 7
UpdateTime = 24
```
* `xmltv.getdata`: Optional script that is called to retrieve or generate xmltv EPG data.

* `xmltv.input`: The path where the scraper will place the XMLTV file.

* `DaysInAdvance`: The number of days the scraper should scrape in advance.

* `UpdateTime`: The time in hours after which the EPG data is considered stale and should be re-scraped.
