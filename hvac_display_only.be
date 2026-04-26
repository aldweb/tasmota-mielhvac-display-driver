#-

----------------------------------------------------------------------
| Mitsubishi Electric HVAC sensors display driver written in Berry   |
| #1 Coded by aldweb (December 17th, 2024)                           |
| #2 < Applies to hvac_with_controls.be driver only >                |
| #3 Updated for MiElHVAC driver PR#24660 (April 25th, 2026)         |
| #4 Added backward compatibility (April 26th, 2026)                 |
| #5 < Applies to hvac_with_controls.be driver only >                |
----------------------------------------------------------------------

For those using the MiElHVAC driver (https://github.com/arendst/Tasmota/blob/development/tasmota/tasmota_xdrv_driver/xdrv_44_miel_hvac.ino),
this berry display driver lets you visualize the MiElHVAC sensor parameters on the Tasmota web console, which it does not offer by default.

#3 Key renames in driver PR#24660 (Tasmota >= 15.4.x):
  Power            -> PowerState      (on/off string)
  Temperature      -> RoomTemperature (room temp float)
  Compressor       -> CompressorState (on/off string)
  OperationPower   -> Power           (integer Watts)
  OperationEnergy  -> Energy          (float kWh)

#4 Backward compatibility: the driver auto-detects the API version at runtime
   by checking for the presence of 'PowerState' (new API) or 'Power' string
   (old API <= 15.3.x), and normalizes all keys transparently.

To enable a field: remove the leading #
To disable a field: add a leading #
Each field requires TWO lines to be commented/uncommented:
  - the format string line  "{s}MiElHVAC ...{m}...{e}"
  - the value line          sensors['MiElHVAC']['...'],

-#

var sensors

class HVAC : Driver

  #- normalize sensor keys to new API format regardless of driver version -#
  def normalize_keys()
    var h = sensors['MiElHVAC']
    # Detect old API (<= 15.3.x): 'Power' is a string "on"/"off"
    # In new API (>= 15.4.x): 'PowerState' exists and 'Power' is an integer
    if !h.contains('PowerState')
      # Old API -> normalize to new key names
      h['PowerState']      = h.contains('Power')           ? h['Power']                   : 'unknown'
      h['RoomTemperature'] = h.contains('Temperature')     ? real(h['Temperature'])        : 0.0
      h['CompressorState'] = h.contains('Compressor')      ? h['Compressor']              : 'unknown'
      h['Power']           = h.contains('OperationPower')  ? int(h['OperationPower'])      : 0
      h['Energy']          = h.contains('OperationEnergy') ? real(h['OperationEnergy'])    : 0.0
      # Keys unchanged between versions (listed for reference):
      # Mode, SetTemperature, FanSpeed, SwingV, SwingH, AirDirection,
      # Prohibit, OutdoorTemperature, OperationTime, CompressorFrequency,
      # RemoteTemperatureSensorState, RemoteTemperatureSensorAutoClearTime,
      # TimerMode, TimerOn, TimerOnRemaining, TimerOff, TimerOffRemaining,
      # OperationStage, FanStage, ModeStage
      # Keys only in new API (not available in old, left absent):
      # HAMode, RemoteTemperature, Purifier, NightMode, EconoCool
    end
  end

  #- read sensor data -#
  def read_hvac()
    import json
    sensors = json.load(tasmota.read_sensors())
    if sensors != nil && sensors.contains('MiElHVAC')
      self.normalize_keys()
    end
  end

  #- trigger a read every second -#
  def every_second()
    self.read_hvac()
  end

  #- display sensor value in the web UI -#
  def web_sensor()
    import string

    if sensors == nil || !sensors.contains('MiElHVAC') return end

    # Calculate OperationTime in days, hours, minutes
    var total_minutes = int(sensors['MiElHVAC']['OperationTime'])
    var days = int(total_minutes / 1440)
    var remaining_minutes = int(total_minutes % 1440)
    var hours = int(remaining_minutes / 60)
    var minutes = int(remaining_minutes % 60)
    var operation_time_str = ""
    if days >= 1
      operation_time_str = string.format("%dd %dhr", days, hours)
    else
      operation_time_str = string.format("%dhr %dmn", hours, minutes)
    end

    var msg = string.format(
    # --- General state ---
      "{s}MiElHVAC Power State{m}%s{e}"
      "{s}MiElHVAC Mode{m}%s{e}"
    # "{s}MiElHVAC HA Mode{m}%s{e}"
      "{s}MiElHVAC Set Temperature{m}%1.1f °%s{e}"
      "{s}MiElHVAC Fan Speed{m}%s{e}"
      "{s}MiElHVAC Swing Vertical{m}%s{e}"
      "{s}MiElHVAC Swing Horizontal{m}%s{e}"
    # "{s}MiElHVAC Air Direction{m}%s{e}"
    # "{s}MiElHVAC Prohibit{m}%s{e}"
    # "{s}MiElHVAC Purifier{m}%s{e}"      # requires cap_run_state (new API >= 15.4.x only)
    # "{s}MiElHVAC Night Mode{m}%s{e}"    # requires cap_run_state (new API >= 15.4.x only)
    # "{s}MiElHVAC Econo Cool{m}%s{e}"    # requires cap_run_state (new API >= 15.4.x only)
    # --- Temperatures ---
      "{s}MiElHVAC Room Temperature{m}%1.1f °%s{e}"
    # "{s}MiElHVAC Remote Temperature{m}%1.1f °%s{e}"
      "{s}MiElHVAC Outdoor Temperature{m}%1.1f °%s{e}"
    # --- Remote temperature sensor ---
    # "{s}MiElHVAC Remote Sensor State{m}%s{e}"
    # "{s}MiElHVAC Remote Sensor Auto Clear Time{m}%i s{e}"
    # --- Timers ---
    # "{s}MiElHVAC Timer Mode{m}%s{e}"
    # "{s}MiElHVAC Timer On{m}%i mn{e}"
    # "{s}MiElHVAC Timer On Remaining{m}%i mn{e}"
    # "{s}MiElHVAC Timer Off{m}%i mn{e}"
    # "{s}MiElHVAC Timer Off Remaining{m}%i mn{e}"
    # --- Operation ---
      "{s}MiElHVAC Operation Time{m}%s{e}"
      "{s}MiElHVAC Compressor{m}%s{e}"
    # "{s}MiElHVAC Compressor Frequency{m}%i Hz{e}"
    # "{s}MiElHVAC Operation Stage{m}%s{e}"
    # "{s}MiElHVAC Fan Stage{m}%s{e}"
    # "{s}MiElHVAC Mode Stage{m}%s{e}"
    # --- Energy ---
    # "{s}MiElHVAC Power{m}%i W{e}"
    # "{s}MiElHVAC Energy{m}%1.1f kWh{e}"
    # --- Sentinel (do not remove) ---
      "%s",
    # --- General state ---
      sensors['MiElHVAC']['PowerState'],
      sensors['MiElHVAC']['Mode'],
    # sensors['MiElHVAC']['HAMode'],
      sensors['MiElHVAC']['SetTemperature'], sensors['TempUnit'],
      sensors['MiElHVAC']['FanSpeed'],
      sensors['MiElHVAC']['SwingV'],
      sensors['MiElHVAC']['SwingH'],
    # sensors['MiElHVAC']['AirDirection'],
    # sensors['MiElHVAC']['Prohibit'],
    # sensors['MiElHVAC']['Purifier'],
    # sensors['MiElHVAC']['NightMode'],
    # sensors['MiElHVAC']['EconoCool'],
    # --- Temperatures ---
      sensors['MiElHVAC']['RoomTemperature'], sensors['TempUnit'],
    # sensors['MiElHVAC']['RemoteTemperature'], sensors['TempUnit'],
      sensors['MiElHVAC']['OutdoorTemperature'], sensors['TempUnit'],
    # --- Remote temperature sensor ---
    # sensors['MiElHVAC']['RemoteTemperatureSensorState'],
    # sensors['MiElHVAC']['RemoteTemperatureSensorAutoClearTime'],
    # --- Timers ---
    # sensors['MiElHVAC']['TimerMode'],
    # sensors['MiElHVAC']['TimerOn'],
    # sensors['MiElHVAC']['TimerOnRemaining'],
    # sensors['MiElHVAC']['TimerOff'],
    # sensors['MiElHVAC']['TimerOffRemaining'],
    # --- Operation ---
      operation_time_str,
      sensors['MiElHVAC']['CompressorState'],
    # sensors['MiElHVAC']['CompressorFrequency'],
    # sensors['MiElHVAC']['OperationStage'],
    # sensors['MiElHVAC']['FanStage'],
    # sensors['MiElHVAC']['ModeStage'],
    # --- Energy ---
    # sensors['MiElHVAC']['Power'],
    # sensors['MiElHVAC']['Energy'],
    # --- Sentinel (do not remove) ---
      ""
    )

    tasmota.web_send_decimal(msg)
  end

end

HVAC = HVAC()
tasmota.add_driver(HVAC)
