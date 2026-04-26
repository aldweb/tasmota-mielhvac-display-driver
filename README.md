# Tasmota MiElHVAC Display and Web UI Controls driver

[![Platform](https://img.shields.io/badge/Platform-ESP32-informational?logo=espressif&logoColor=white)](https://www.espressif.com/)
[![Tasmota](https://img.shields.io/badge/Compatible%20with-Tasmota-00ADD8?logo=tasmota&logoColor=white)](https://tasmota.github.io/docs/)
[![Berry](https://img.shields.io/badge/Script-Berry-9cf?logo=berry&logoColor=white)](https://tasmota.github.io/docs/Berry/)
[![Latest Version](https://img.shields.io/github/v/tag/aldweb/tasmota-mielhvac-display-driver?label=Latest%20Version&logo=github&color=blue)](https://github.com/aldweb/tasmota-mielhvac-display-driver/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Enhanced Berry driver for Tasmota providing interactive web UI controls for Mitsubishi Electric heat pumps.

## Overview

<img src="images/mitsubishi_heat_pump.png" align="left" width="300" style="margin-right: 20px; margin-bottom: 20px;">
This Berry driver extends the native Tasmota MiElHVAC driver by adding a web interface for Mitsubishi Electric heat pumps.
<br clear="all" />

Two versions are available:

**Full Version (`hvac_with_controls.be`):**
- Interactive web controls directly in the Tasmota interface
- Temperature adjustment buttons (-1°, +½°, +1°)
- Dropdown selectors for Mode, Fan Speed, Swing Vertical, and Swing Horizontal
- Real-time display of current settings (pre-selected values in dropdowns)
- Collapsible control panel to save screen space
- Formatted operation time display (days/hours/minutes)
- Automatic temperature unit adaptation (°C or °F)
- **Dynamic controls** — selectors and options adapt automatically to your model's capabilities
- **Backward compatible** — works with Tasmota MiElHVAC driver <= 15.3.x and >= 15.4.x

**Display-Only Version (`hvac_display_only.be`):**
- Sensor readings display only
- No interactive controls
- Lightweight and minimal memory footprint
- Ideal for monitoring or when controlling via Home Assistant/MQTT
- **Backward compatible** — works with Tasmota MiElHVAC driver <= 15.3.x and >= 15.4.x

Both versions provide a clean, responsive interface matching Tasmota's design.

<img src="images/hvac_with_expanded.png" style="margin-right: 20px; margin-bottom: 20px;">

## Compatibility

| Tasmota version | MiElHVAC driver | Status |
|---|---|---|
| <= 15.3.x | Old API | ✅ Supported (auto-detected) |
| >= 15.4.x | New API (PR#24660) | ✅ Supported (auto-detected) |

The driver automatically detects which API version is running at runtime — no configuration needed.

### API changes in Tasmota >= 15.4.x (PR#24660)

The MiElHVAC driver introduced in PR#24660 renamed several JSON keys. The display driver handles this transparently:

| Old key (<=15.3.x) | New key (>=15.4.x) | Description |
|---|---|---|
| `Power` | `PowerState` | On/off state (string) |
| `Temperature` | `RoomTemperature` | Room temperature (float) |
| `Compressor` | `CompressorState` | Compressor state (string) |
| `OperationPower` | `Power` | Electrical power (integer Watts) |
| `OperationEnergy` | `Energy` | Total energy (float kWh) |

Additionally, the new API exposes model capability flags and supported temperature ranges, which the driver uses to adapt the control panel dynamically.

## Requirements

### Hardware
- **Mitsubishi Electric Heat Pump** with CN105 connector
- **ESP32 board** (DevKit, NodeMCU-32S, etc.) — **ESP8266 is NOT compatible** as Berry scripting requires ESP32
- **JST PA 5-pin connector (2.0mm pitch)** to interface with CN105

### Software
- **Tasmota32 firmware with MiElHVAC enabled** — A pre-compiled version (Tasmota 15.2.0) is included in this repository for convenience
- Alternatively, you can compile your own custom firmware (see below)

## Hardware Setup

For complete hardware setup instructions including wiring diagrams, photos, and physical installation steps, please consult these comprehensive guides:

- **[Integration with Home Assistant via Tasmota (Archive)](https://web.archive.org/web/20240314034821/https://isaiahchia.com/2022/06/)** — Complete end-to-end guide with detailed photos and CN105 pinout
- **[Hacking A Mitsubishi Heat Pump Part 1](https://chrdavis.github.io/hacking-a-mitsubishi-heat-pump-Part-1/)** — Hardware overview and initial setup

**Important Notes:**
- Berry scripting is only available on ESP32, not ESP8266
- Use Tasmota32 firmware, not the standard ESP8266 version
- The CN105 connector provides serial UART communication at 5V
- Proper wiring is critical — refer to the guides above for detailed instructions

## Tasmota Firmware Compilation

### Option 1: Use Pre-compiled Firmware (Quickest)

A ready-to-use Tasmota32 firmware with MiElHVAC enabled is included in this repository:
- **Version:** Tasmota 15.2.0
- **File:** `tasmota32-miel-hvac.bin` (or similar, check repository files)
- **Note:** This is provided for convenience. Regular updates are not provided, so you may want to compile your own firmware for the latest features and security patches.

### Option 2: Compile Your Own (Recommended for Latest Version)

This driver requires a custom **Tasmota32** build (for ESP32) with the MiElHVAC component enabled.

### Recommended: Use TasmoCompiler (Easiest Method)

The easiest way to compile custom Tasmota firmware is using **[TasmoCompiler](https://github.com/benzino77/tasmocompiler)** — a web GUI for custom Tasmota compilation.

**Steps:**

1. Visit one of the available TasmoCompiler instances (see [Compiling - Tasmota](https://tasmota.github.io/docs/Compile-your-build/) for options)
2. Select your **Tasmota version** (latest stable recommended)
3. Choose **tasmota32** as the build environment
4. In **Custom parameters** (step 4), add:
   ```
   #define USE_MIEL_HVAC
   ```
5. Click **Compile** and wait for the build to complete
6. Download the compiled `.bin` file

**Note:** Manual compilation with PlatformIO is also possible if you prefer a local development environment.

### Flashing the Firmware

**Recommended: Web-based Flasher**

Use the official web-based flasher (easiest, no software installation required):
- **[https://tasmota.github.io/install/](https://tasmota.github.io/install/)**
- Connect your ESP32 via USB
- Click "Install" and follow the prompts
- Upload your custom compiled `.bin` file when prompted

### Configure Tasmota Module

After flashing:

1. Connect to the Tasmota WiFi AP and configure your network
2. Navigate to **Configuration → Configure Module**
3. Set the module type appropriately for your ESP32 board
4. Configure GPIO pins:
   - **TX GPIO** → `MiEl HVAC Tx` (commonly GPIO1 or GPIO17)
   - **RX GPIO** → `MiEl HVAC Rx` (commonly GPIO3 or GPIO16)
5. Save and reboot

**Note:** GPIO pin numbers vary by ESP32 board model. Consult your board's pinout diagram and the hardware guides above.

## Driver Installation

### Choose Your Driver Version

Two versions of the Berry driver are available in this repository:

1. **`hvac_with_controls.be`** (Recommended)
   - Full-featured version with interactive web controls
   - Includes buttons for temperature adjustment
   - Dropdown selectors for Mode, Fan Speed, and Swing positions
   - Collapsible control panel
   - Controls adapt dynamically to model capabilities

2. **`hvac_display_only.be`** (Lightweight)
   - Display-only version showing sensor readings
   - No interactive controls
   - Smaller file size, lower memory footprint
   - Ideal if you only need monitoring or control via Home Assistant/MQTT

Choose the version that best fits your needs.

### Installation Steps

1. **Download your chosen `.be` file** from this repository

2. **Upload to Tasmota**:
   - Navigate to **Tools → Manage File system**
   - Upload the `.be` file to the root directory

3. **Enable the driver**:
   - Add to `autoexec.be` (create if it doesn't exist):
     ```berry
     load('hvac_with_controls.be')
     ```
     or
     ```berry
     load('hvac_display_only.be')
     ```

4. **Reboot** Tasmota device

5. **Verify installation**:
   - Navigate to the Tasmota main page
   - You should see sensor readings from your heat pump
   - If using `hvac_with_controls.be`, click the "HVAC Control   ▼" button to reveal interactive controls

## Usage

### Web Interface Controls

**HVAC Control Button (Collapsible)**
- Click to expand/collapse the control panel
- Shows ▼ when collapsed, ▲ when expanded

**Set Temperature**
- Three buttons for temperature adjustment: -1°, +½°, +1°
- Temperature unit automatically matches your Tasmota configuration (°C or °F)
- Temperature range is automatically read from your model's capabilities when running Tasmota >= 15.4.x (e.g. 10–31°C in heat mode), falling back to generic defaults otherwise

**Mode**
- Heat, Cool, Dry, Fan, Auto
- Current mode is pre-selected in dropdown
- Dry and Fan options are hidden automatically if not supported by your model (Tasmota >= 15.4.x)

**Fan Speed**
- Auto, Quiet, Speed 1–4
- Current speed is pre-selected
- Auto option is hidden automatically if not supported by your model (Tasmota >= 15.4.x)

**Swing Vertical**
- Auto, Up, Up Middle, Center, Down Middle, Down, Swing
- Current position is pre-selected
- Entire control is hidden automatically if not supported by your model (Tasmota >= 15.4.x)

**Swing Horizontal**
- Auto, Left, Left Middle, Center, Right, Right Middle, Split, Swing
- Current position is pre-selected
- Entire control is hidden automatically if not supported by your model (Tasmota >= 15.4.x)

### Sensor Display

The main page displays (enabled fields shown by default):

| Field | Description |
|---|---|
| Power State | On/Off state of the heat pump |
| Mode | Current operating mode |
| Set Temperature | Target temperature |
| Fan Speed | Current fan speed |
| Swing Vertical | Vertical vane position |
| Swing Horizontal | Horizontal vane position |
| Room Temperature | Measured indoor temperature |
| Outdoor Temperature | Measured outdoor temperature |
| Operation Time | Total runtime (formatted as Xd Xhr or Xhr Xmn) |
| Compressor | Compressor on/off state |

Additional fields available but disabled by default (uncomment to enable):

| Field | Description |
|---|---|
| HA Mode | Home Assistant mode state |
| Remote Temperature | Temperature from remote sensor |
| Remote Sensor State | Remote sensor enabled/disabled |
| Remote Sensor Auto Clear Time | Remote sensor timeout |
| Timer Mode / On / Off / Remaining | Timer settings |
| Compressor Frequency | Compressor frequency in Hz |
| Operation Stage / Fan Stage / Mode Stage | Internal operation stages |
| Power (W) | Current electrical power draw |
| Energy (kWh) | Total energy consumed |

### Customization

You can show or hide any sensor field by editing the `web_sensor()` function in either `.be` file.

Each field uses **two lines** that must be commented/uncommented together:
- the format string: `"{s}MiElHVAC ...{m}...{e}"`
- the value: `sensors['MiElHVAC']['...'],`

To **enable** a field: remove the leading `#` from both lines.
To **disable** a field: add a leading `#` to both lines.

```berry
# Currently hidden — remove both # to display:
# "{s}MiElHVAC Air Direction{m}%s{e}"
# sensors['MiElHVAC']['AirDirection'],

# Currently shown — add both # to hide:
  "{s}MiElHVAC Room Temperature{m}%1.1f °%s{e}"
  sensors['MiElHVAC']['RoomTemperature'], sensors['TempUnit'],
```

> **Note:** All value lines end with a comma `,` — a hidden sentinel field at the end of the list safely absorbs the trailing comma of the last active field, so you never need to worry about removing a trailing comma.

Available sensors vary by heat pump model. Refer to your heat pump's service manual for available features.

## Troubleshooting

### No sensor readings (empty data)
- Check GPIO pin configuration in Tasmota
- Verify physical wiring connections
- Ensure TX/RX are not swapped
- Try swapping TX/RX if still no communication
- Check that CN105 has power (measure 5V between pins 2 and 3)

### Controls not responding
- Verify the driver is loaded (check Tasmota logs)
- Ensure you're using the correct firmware with `USE_MIEL_HVAC`
- Check MQTT is configured if using Home Assistant integration
- Try manual commands via console: `HVACSetTemp 22`

### `key_error - Temperature` in logs after firmware upgrade
- You are running Tasmota >= 15.4.x with a display driver older than v2.0.0
- Update to v2.0.0 or later — the driver now handles both API versions automatically

### "Unsupported" error messages
- Your heat pump may not support all features
- Some older models have limited functionality
- Refer to your heat pump's service manual for supported features

### Web UI issues
- Clear browser cache
- Try a different browser
- Check Tasmota logs for Berry script errors

## Tested Hardware

Any ESP32 board should work (DevKit, NodeMCU-32S, TTGO, etc.).

Mitsubishi Electric heat pump models with CN105 connector should be compatible, but your mileage may vary depending on your specific model and available features.

## Home Assistant Integration

For Home Assistant integration via MQTT, refer to:
- [Tasmota MQTT Climate integration](https://www.home-assistant.io/integrations/climate.mqtt/)
- Sample configuration provided in the referenced guides

## Credits

- **SwiCago** — Original Mitsubishi protocol reverse engineering and Arduino library
- **Tasmota team** — Native MiElHVAC driver implementation
- **Community contributors** — Hardware guides and troubleshooting

## License

This Berry driver is provided as-is for community use. Feel free to modify and share.

## Contributing

Contributions are welcome! Please:
- Test thoroughly before submitting
- Document any hardware-specific quirks
- Follow the existing code style
- Update this README if adding features

## Disclaimer

The authors take no responsibility for any damage to equipment or injury resulting from following these instructions. Proceed at your own risk.

---

**Questions?** Open an issue on GitHub or refer to the Tasmota documentation and forums.
