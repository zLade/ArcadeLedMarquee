# SD Card Template

Copy the content of this folder to the root of the ESP32 SD card.

Required final layout:

```text
/config.txt
/gif/
  default.gif
  fbneo/
    dkong_1.gif
    dkong_2.gif
    dkong_3.gif
```

Before booting the ESP32:

1. Edit `/config.txt`.
2. Replace `SSID` and `PASSWORD` with your WiFi credentials.
3. Put the default idle animation at `/gif/default.gif`.
4. Put game GIFs inside `/gif/<recalbox-system-id>/`.

Game GIF names must use the ROM basename plus a numeric suffix starting at `_1`:

```text
/gif/fbneo/dkong_1.gif
/gif/fbneo/dkong_2.gif
/gif/fbneo/dkong_3.gif
```

`default.gif` is the only GIF that does not use the `_1` suffix.
