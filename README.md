# TVSpielfilm.de EPG Scraper

This Python-based scraper is designed to extract EPG (Electronic Program Guide) data from the mobile website of TVSpielfilm.de and output it in XMLTV or JSON format. It is optimized for integration into systems like VDR (Video Disk Recorder) with the `epgd` daemon, but can also be used as a standalone tool.

## Features

* **Flexible Channel Selection:** Scrapes either all available channels or a specific list of channels provided via the command line or a file.

* **Time Range Scraping:** Supports scraping for a specific start date or for a configurable number of days from the current date.

* **Enhanced Caching:** Utilizes a custom in-memory and file-based caching system to store fetched HTML content and processed JSON data, which significantly reduces the number of live requests and increases scraping speed on repeated runs. Supports cache revalidation, proactive cache cleanup, and cache clearing.

* **Parallel Processing:** Uses a thread pool to concurrently fetch schedules for channels and days, significantly reducing overall scraping time.

* **Robust Retry Mechanism:** Implements retries for network errors (HTTP 429, 5xx, connection errors) as well as for application-level errors that may occur during schedule parsing.

* **Output Formats:** Generates EPG data in the standardized XMLTV format (`.xml`) or as a JSON array (`.json`).

* **Image Validation:** Optional checking of image URLs to ensure that program images are actually available.

* **Comprehensive Data Extraction:** Extracts detailed program information such as short description, long description, genre, original title, country, year, duration, FSK (parental rating), cast, director, screenplay, camera, numerical and textual ratings, IMDb ratings, subtitles, and season/episode numbers.

* **XML Security Filter:** Cleanses all text content of invalid XML characters before XMLTV output to ensure compatibility.

* **Syslog Integration:** Optional output of log messages to syslog for centralized logging.

## Installation

### Dependencies

The scraper primarily uses `lxml` for efficient HTML parsing and `cssselect` for CSS selector support. For file access with locks, `portalocker` is used. Timezone information is handled via the standard `zoneinfo` module (available from Python 3.9+). It requires the following Python libraries:

* `requests`
* `lxml`
* `cssselect`
* `portalocker`

You can install these using pip:

```bash
pip install requests lxml cssselect portalocker
```

### Make Executable

Ensure the script is executable:

```bash
chmod +x tvs-scraper
```

It is recommended to place the script in a directory included in your `PATH` (e.g., `/usr/local/bin/`), or to use the full path to the script.

## Cache Behavior and First Run

The scraper offers a custom caching system to minimize the number of live requests to the server and accelerate execution time on repeated runs. Caching of processed JSON data is **enabled by default**.

**First Run:**
During the **first run** of the scraper, especially when scraping many channels and days, execution can take a **very long time**. This is because the cache is initially empty, and all data must be fetched live from the internet. The default cache Time To Live (`--cache-ttl`) is 24 hours, and the cache is stored by default in the system's temporary directory in a subdirectory named `tvs-cache` (`--cache-dir`).

**Subsequent Runs:**
**After** the **first run**, subsequent scraper runs will generally be **significantly faster**. The scraper stores fetched HTML responses and processed JSON data on disk. For repeated requests to the same URLs or data, information will be loaded from the cache instead of being downloaded or re-processed, which significantly reduces the time.

**Cache Consistency Check:**
By default, the scraper uses a robust cache consistency check based on `Content-Length` (as a fallback when a 304 status is not received) and ETag/Last-Modified headers. This ensures that cached data is only used if the remote content hasn't significantly changed.

**Proactive Cache Cleanup:**
The scraper performs proactive cache cleanup to automatically remove stale or no longer relevant cache files. This includes removing empty channel subdirectories, cache files for channels no longer targeted, and daily cache files outside the relevant time period. By default, cache files for past days are deleted; this behavior can be disabled with `--cache-keep`.

**Potential Slowdowns due to Cache:**
In certain scenarios, using the cache can, however, lead to **considerable slowdowns**. This can happen if:

* The cache storage location (e.g., a slow network drive) is not optimal.

* Many cache entries have expired, and revalidation with the server takes place, which can lead to many live requests despite the cache.

Ensure that sufficient disk space is available on the drive where the cache is stored. You can clear the cache at any time using the `--cache-clear` option.

## Usage

The scraper is controlled via the command line with various arguments.

### General Syntax

```bash
./tvs-scraper [OPTIONS]
```

### Important Options

* `--list-channels`: Lists all available channel IDs and their names, then exits. Useful for configuring `channelmap.conf`.

* `--channel-ids <IDS>`: A comma-separated list of channel IDs (e.g., `"ARD,ZDF"`). If not provided, all channels are scraped.

* `--channel-ids-file <FILE>`: Path to a file containing a comma-separated list of channel IDs. If provided, this option takes precedence over `--channel-ids`.

* `--date <DATE>`: Specific start date for scraping in `YYYYMMDD` format (e.g., `20250523`). If provided, only this date is scraped, and `--days` is ignored. Only dates from 'yesterday' up to 'today + 12 days' are allowed.

* `--days <NUMBER>`: Number of days to scrape (1-13). Default: `0` (means today only). This argument is ignored if `--date` is provided.

* `--output-file <FILE>`: Path to the output file. The file extension (`.json` or `.xml`) will be automatically added if not present. Default: `tvspielfilm`.

* `--output-format <FORMAT>`: Output format: `"xmltv"` or `"json"`. Default: `xmltv`.

* `--xmltv-timezone <TIMEZONE>`: Specifies the timezone to use for XMLTV output (e.g., `"Europe/Berlin"`, `"America/New_York"`). This affects the timestamps in the XMLTV file. Default: `"Europe/Berlin"`.

* `--img-size <SIZE>`: Image size to extract (`"150"`, `"300"` or `"600"`). Default: `600`.

* `--img-check`: If set, performs an additional HEAD request to check if image URLs are valid. Increases scraping time.

* `--log-level <LEVEL>`: Sets the logging level (`DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`). Default: `WARNING`.

* `--verbose`: Enables DEBUG logging output (overrides `--log-level` to `DEBUG`).

* `--use-syslog`: Sends log output to syslog.

* `--syslog-tag <TAG>`: Identifier (tag) to use for syslog messages. Default: `tvs-scraper`.

* `--cache-dir <PATH>`: Specifies a custom directory for cache files. Default is a subdirectory `"tvs-cache"` in the system temporary directory.

* `--cache-clear`: Clears the entire cache directory (including processed data cache) before scraping begins. This will delete all cached responses.

* `--cache-disable`: Disables caching of processed JSON data to disk. Default: `False` (cache is enabled).

* `--cache-ttl <SECONDS>`: Cache Time To Live in seconds. This defines how long a processed JSON file is considered "fresh" and used directly without re-scraping HTML. Default: `24` hours (`86400` seconds).

* `--cache-validation-tolerance <BYTES>`: Tolerance in bytes for content-length comparison when ETag/Last-Modified fails to return 304. Default: `5` bytes.

* `--cache-keep`: If set, cache files for past days will NOT be automatically deleted. By default, past days' cache files are deleted.

* `--max-workers <NUMBER>`: Maximum number of concurrent workers for data fetching. Default: `10`.

* `--max-retries <NUMBER>`: Maximum number of retry attempts for failed HTTP requests (e.g., 429, 5xx, connection errors). Default: `5`.

* `--min-request-delay <SECONDS>`: Minimum delay in seconds between HTTP requests (only for live fetches). Default: `0.05`s.

* `--max-concurrent-requests <NUMBER>`: Maximum number of concurrent HTTP requests allowed. This acts as a global rate limiter. Default: `15`.

* `--max-schedule-retries <NUMBER>`: Maximum number of retry attempts for application-level errors during schedule parsing/generation. Default: `3`.

* `--timeout-http <SECONDS>`: Timeout in seconds for all HTTP requests (GET, HEAD). Default: `10`s.

### Examples

**Scrape all channels for today and output XMLTV:**

```bash
./tvs-scraper --output-format xmltv --output-file tvspielfilm.xml --log-level INFO
```

**Scrape specific channels (ARD, ZDF) for the next 3 days and output JSON, with detailed logging:**

```bash
./tvs-scraper --channel-ids "ARD,ZDF" --days 3 --output-format json --output-file my_epg_data.json --verbose
```

**Scrape schedule for a specific day for a channel and clear cache:**

```bash
./tvs-scraper --channel-ids "PRO7" --date 20250601 --cache-clear --output-format xmltv
```

## Server Load and Fair Use

The scraper offers several parameters to control the load on the `m.tvspielfilm.de` website. Responsible usage is crucial to avoid impairing website availability and to prevent being interpreted as abusive activity (e.g., a denial-of-service-attack).

* **`--max-workers`:** This parameter controls the number of concurrent worker threads that process data (e.g., parsing HTML, extracting details). While it influences the overall speed, its direct impact on *concurrent HTTP requests* is managed by other parameters.
    * **Low values (e.g., 1-5):** Very gentle on the server in terms of processing, but the overall scraping process takes longer.
    * **High values (e.g., 10+):** Accelerates the data processing, but the actual network requests are still subject to the global rate limits.

* **`--min-request-delay`:** This parameter (default: `0.05` seconds) defines a minimum delay between individual HTTP requests. It is crucial for polite scraping, ensuring that your scraper does not overwhelm the server with rapid-fire requests. A delay of 0.5 to 1.0 seconds or more is often recommended for public websites.

* **`--max-concurrent-requests`:** This parameter (default: `15`) acts as a **global rate limiter** for the total number of HTTP requests that can be active at any given moment. Regardless of the `--max-workers` setting, this parameter ensures that the total number of simultaneous network connections to `m.tvspielfilm.de` does not exceed the specified limit. It's a critical safeguard to prevent overloading the server.

**Recommendation for Fair Scraping:**

1.  **Start conservatively:** Begin with a moderate `--max-workers` (e.g., 5-10), a noticeable `--min-request-delay` (e.g., 0.5 seconds), and the default `--max-concurrent-requests` (15).
2.  **Observe server behavior:** Pay attention to log messages for `HTTP Error 429 (Too Many Requests)` or unusually long response times. These are indicators of server overload.
3.  **Adjust parameters:**
    * If you receive 429 errors, first increase the `--min-request-delay` or decrease `--max-concurrent-requests`.
    * If the scraper runs stably and no issues occur, you can gradually increase `--max-workers` or slightly decrease `--min-request-delay`, but always with caution. Adjust `--max-concurrent-requests` only if you understand the server's capacity and need higher concurrency.
4.  **Observe `robots.txt`:** Although `m.tvspielfilm.de/robots.txt` does not contain a specific `Crawl-delay` directive, it specifies disallowed paths and explicitly excludes certain bots. Adhere to these rules.
5.  **Utilize caching:** Enabled caching significantly reduces the number of live requests, minimizing server load.

For `m.tvspielfilm.de`, a larger media site, a combination of a moderate `--max-workers` (e.g., 10), a `--min-request-delay` of at least 0.5 seconds, and the default `--max-concurrent-requests` (15) is a fair and appropriate starting point.

## Integration with *vdr-epg-daemon*

Please read [this](contrib/vdr-epg-daemon/README.md) information.

## Troubleshooting

* **No data extracted / Empty output file:**

  * Check your `--log-level` (use `INFO` or `DEBUG` for more detailed output).

  * Ensure that the specified `--channel-ids` are correct (use `--list-channels` to verify).

  * Check your internet connection and if TVSpielfilm.de is reachable.

  * The HTML structure of the website may have changed. In this case, the scraper code would need to be adapted.

* **`HTTP Error 403 (Forbidden)` or `429 (Too Many Requests)`:** This indicates that the website is blocking your requests. The scraper has built-in retries and delays, but with aggressive use, this can still happen. Increase `--min-request-delay` or reduce `--max-workers`.

* **Incorrect XMLTV output:** Ensure that `channelmap.conf` is correct and that channel IDs match those used by TVSpielfilm.de.

* **Permission issues:** Ensure that the script and output directories have the correct read and write permissions.

## Development

The scraper is written in Python and uses `requests` for HTTP requests and `lxml.html` with `cssselect` for HTML parsing.

* **`TvsLeanScraper` Class:** Encapsulates all scraping logic.

* **`fetch_url` Method:** Responsible for fetching URLs and HTTP-level error handling. It uses `functools.lru_cache` for in-memory caching of HTTP responses and implements a custom file-based caching mechanism with content consistency checks, including `Content-Length` (as a fallback when a 304 status is not received), as well as ETag/Last-Modified. It explicitly forces UTF-8 decoding of the response text.

* **`_get_channel_list` Method:** Extracts the list of channels and integrates with the file-based cache for channel list data.

* **`_get_daily_cache_filepath` Method:** Constructs the file path for the daily schedule JSON cache.

* **`_load_daily_json_cache` Method:** Loads processed JSON data from the daily data cache, along with ETag, Last-Modified, Content-Length, and the timezone it was cached with. Checks if the data is fresh based on its internal timestamp and TTL. Also deletes cache files for past days (if `--keep-past-cache` is not set) and for dates beyond `MAX_DAYS_TO_SCRAPE` from the current date.

* **`_save_daily_json_cache` Method:** Saves processed JSON data to the daily data cache, including HTTP ETag, Last-Modified, Content-Length headers, and the timezone used for XMLTV time formatting.

* **`_process_channel_day_schedule` Method:** A helper method that orchestrates fetching and parsing for a day and channel, including application-specific retry logic and interaction with the file-based cache. It prioritizes fresh data from the local JSON cache. If stale or missing, it performs a conditional HTTP GET to check for updates. If the cached data's timezone differs from the requested one, timestamps are reprocessed.

* **`_proactive_cache_cleanup` Method:** This method for proactive cleanup of old or irrelevant cache files for all channels and data, including removing empty channel subdirectories, cache files for channels no longer targeted, and daily cache files outside the relevant time period.

* **`generate_xmltv` Function:** Creates the XMLTV output file.

Should changes occur on the TVSpielfilm.de website, the CSS selectors in the `TvsHtmlParser` class may need to be updated to find the correct elements.
