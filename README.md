# ArcadeLedMarquee

ArcadeLedMarquee is a dedicated ESP32 firmware for Recalbox arcade cabinets.

It listens for Recalbox game launch events and displays an animated GIF matching the current game on a HUB75 LED matrix. If no matching GIF exists, it scrolls the readable game title instead.

This project intentionally keeps a narrow scope: no web UI, no FTP server, no MQTT/Home Assistant, no OTA, no clock, no weather, no playlist browser, and no WiFiManager portal. Everything required at runtime is preconfigured from `/config.txt` on the SD card.

## Runtime Behavior

1. Before a game is launched, the panel plays `/gif/default.gif`.
2. Recalbox sends the current game to the ESP32 through:

   ```text
   http://ESP32_IP/gif?s=<system>&g=<game>&t=<readable title>
   ```

3. The firmware searches for GIFs matching the ROM basename:

   ```text
   /gif/fbneo/dkong_1.gif
   /gif/fbneo/dkong_2.gif
   /gif/fbneo/dkong_3.gif
   ```

4. If several GIFs exist for the same game, they rotate every `GIF_INTERVAL_SECONDS`.
5. Between two game GIFs, the firmware scrolls the readable game title once.
6. If no GIF exists for the game, the readable game title scrolls continuously.
7. When Recalbox leaves the game, the panel returns to the default GIF.

## SD Card Layout

```text
/config.txt
/gif/
  default.gif
  fbneo/
    dkong_1.gif
    dkong_2.gif
    dkong_3.gif
    sfiii3.gif
  snes/
    zelda3.gif
```

## `/config.txt`

Copy [firmware/config.txt](firmware/config.txt) to `/config.txt` at the SD card root and edit it:

```ini
SSID=YourWifiName
PASSWORD=YourWifiPassword
HOSTNAME=arcade-led-marquee

DHCP=true
# DHCP=false
# IP=192.168.1.108
# GATEWAY=192.168.1.1
# SUBNET=255.255.255.0
# DNS=192.168.1.1

BRIGHTNESS=40
PANEL_CHAIN=4
DISPLAY_X_OFFSET=128
VIEWPORT_WIDTH=128

GIF_ROOT=/gif
DEFAULT_GIF=/gif/default.gif
GIF_INTERVAL_SECONDS=10
TEXT_SPEED_MS=35
TEXT_PAUSE_MS=250
SHOW_TITLE_BETWEEN_GIFS=true
```

For a standard 128x32 matrix made of two 64x32 panels:

```ini
PANEL_CHAIN=2
DISPLAY_X_OFFSET=0
VIEWPORT_WIDTH=128
```

For a 256x32 DMD-style setup where the GIF area is the right 128 pixels:

```ini
PANEL_CHAIN=4
DISPLAY_X_OFFSET=128
VIEWPORT_WIDTH=128
```

## Recalbox Installation

Copy the Recalbox script to the `userscripts` folder.

Recommended filename:

```text
/recalbox/share/userscripts/arcade_led_marquee[rungame,rundemo,endgame,enddemo,systembrowsing,start,stop,shutdown,reboot,quit,relaunch,sleep,wakeup].sh
```

The filename is long because Recalbox supports event filtering directly in the script name:

```text
script_name[event1,event2,event3].sh
```

With this syntax, EmulationStation only calls the script for the listed events. That avoids running the script for every browsing movement or unrelated event.

You can use a shorter script name if preferred, as long as the event list remains in brackets. Example:

```text
/recalbox/share/userscripts/alm[rungame,endgame,start,stop,shutdown,reboot,sleep,wakeup].sh
```

The default script listens to these events:

* `rungame`, `rundemo`: send the current game to the ESP32.
* `endgame`, `enddemo`, `systembrowsing`, `start`, `sleep`, `relaunch`, `wakeup`: return to the default GIF when no game is active.
* `stop`, `shutdown`, `reboot`, `quit`: also return to the default GIF before Recalbox stops.

### Optional Recalbox Config

The script can read an optional Recalbox-side config file:

```text
/recalbox/share/system/configs/arcade_led_marquee.conf
```

This file lets you change the ESP32 IP address or curl timeout without editing the script itself.

Example content:

```sh
IP_ESP32="192.168.1.108"
CURL_TIMEOUT="8"
```

If this file does not exist, the script uses the default values embedded in the script.

### Recalbox Event State File

The script follows the official Recalbox EmulationStation userscript contract by parsing:

* `-action`: the event name, for example `rungame`.
* `-statefile`: path to the EmulationStation state file.
* `-param`: event parameter, usually the launched ROM path for `rungame`.

Recalbox commonly writes the current EmulationStation context to:

```text
/tmp/es_state.inf
```

The script uses the `-statefile` argument when Recalbox provides it. `/tmp/es_state.inf` is kept only as a fallback for manual tests or older setups.

Example state file content:

```ini
Action=rungame
Game=Donkey Kong
GamePath=/recalbox/share/roms/fbneo/dkong.zip
SystemId=fbneo
System=FinalBurn Neo
State=playing
```

From this data, the script extracts:

* `SystemId` or the ROM folder as the system, for example `fbneo`.
* the ROM basename as the game id, for example `dkong`.
* `Game` as the readable title, for example `Donkey Kong`.

It then sends:

```text
http://ESP32_IP/gif?s=fbneo&g=dkong&t=Donkey%20Kong
```

## HTTP Input

Useful test from a PC:

```powershell
curl "http://192.168.1.108/gif?s=fbneo&g=dkong&t=Donkey%20Kong"
```

Status endpoint:

```text
GET /status
```

## Firmware Build

Compile with Arduino CLI:

```powershell
arduino-cli compile --fqbn esp32:esp32:esp32 firmware/ArcadeLedMarquee
```

Current validation build:

```text
Flash: 1,034,390 bytes / 78%
RAM:   73,004 bytes / 22%
```

## Dependencies

* ESP32 Arduino core
* AnimatedGIF
* ESP32-HUB75-MatrixPanel-I2S-DMA

## License

MIT. See [LICENSE](LICENSE).
