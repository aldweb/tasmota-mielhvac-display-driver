#-

--------------------------------------------------------------------
| Mitsubishi Electric HVAC sensors display driver written in Berry |
| #1 coded by aldweb (December 17th, 2024)                         |
| #2 enhanced with control buttons (January 30th, 2026)            |
| #3 Updated for MiElHVAC driver PR#24660 (April 25th, 2026)       |
--------------------------------------------------------------------

For those using the MiElHVAC driver (https://github.com/arendst/Tasmota/blob/development/tasmota/tasmota_xdrv_driver/xdrv_44_miel_hvac.ino),
this berry display driver lets you visualize the MiElHVAC sensor parameters on the Tasmota web console, which it does not offer by default.
The driver adds interactive buttons to control Mode, Set Temperature, Fan Speed, Swing Vertical and Swing Horizontal.

#3 Key renames vs old driver:
  Power            -> PowerState      (on/off string)
  Temperature      -> RoomTemperature (room temp float)
  Compressor       -> CompressorState (on/off string)
  OperationPower   -> Power           (integer Watts)
  OperationEnergy  -> Energy          (float kWh)

To enable a field: remove the leading #
To disable a field: add a leading #
Each field requires TWO lines to be commented/uncommented:
  - the format string line  "{s}MiElHVAC ...{m}...{e}"
  - the value line          sensors['MiElHVAC']['...']

-#

var sensors

class HVAC : Driver

  #- read sensor data -#
  def read_hvac()
    import json
    sensors = json.load(tasmota.read_sensors())
  end

  #- trigger a read every second -#
  def every_second()
    self.read_hvac()
  end

  #- display sensor value in the web UI -#
  def web_sensor()
    import string
    import webserver

    if sensors == nil || !sensors.contains('MiElHVAC') return end

    # Handle button clicks first

    if webserver.has_arg("m_miel_mode")
      tasmota.cmd(string.format("HVACSetMode %s", webserver.arg("m_miel_mode")))
    end

    if webserver.has_arg("m_miel_temp")
      var temp_delta = real(webserver.arg("m_miel_temp"))
      var new_temp = real(sensors['MiElHVAC']['SetTemperature']) + temp_delta
      if sensors['TempUnit'] == 'C'
        if new_temp < 10 new_temp = 10 end
        if new_temp > 31 new_temp = 31 end
      else
        if new_temp < 50 new_temp = 50 end
        if new_temp > 88 new_temp = 88 end
      end
      tasmota.cmd(string.format("HVACSetTemp %.1f", new_temp))
    end

    if webserver.has_arg("m_miel_fan")
      tasmota.cmd(string.format("HVACSetFanSpeed %s", webserver.arg("m_miel_fan")))
    end

    if webserver.has_arg("m_miel_swingv")
      tasmota.cmd(string.format("HVACSetSwingV %s", webserver.arg("m_miel_swingv")))
    end

    if webserver.has_arg("m_miel_swingh")
      tasmota.cmd(string.format("HVACSetSwingH %s", webserver.arg("m_miel_swingh")))
    end

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
    # "{s}MiElHVAC Purifier{m}%s{e}"
    # "{s}MiElHVAC Night Mode{m}%s{e}"
    # "{s}MiElHVAC Econo Cool{m}%s{e}"
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
      ,
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
      sensors['MiElHVAC']['CompressorState']
    # sensors['MiElHVAC']['CompressorFrequency'],
    # sensors['MiElHVAC']['OperationStage'],
    # sensors['MiElHVAC']['FanStage'],
    # sensors['MiElHVAC']['ModeStage'],
    # --- Energy ---
    # sensors['MiElHVAC']['Power'],
    # sensors['MiElHVAC']['Energy']
    )

    tasmota.web_send_decimal(msg)
  end

  #- add control buttons to web interface -#
  def web_add_main_button()
    import webserver
    import string

    if sensors == nil || !sensors.contains('MiElHVAC') return end

    webserver.content_send("<style>")
    webserver.content_send(".hvac-control{margin:5px 0;padding:5px 10px;background:#1fa3ec;border-radius:5px;}")
    webserver.content_send(".hvac-control.compact{padding:3px 10px;}")
    webserver.content_send(".hvac-title{color:#fff;font-weight:bold;margin-bottom:0;font-size:1em;flex:0 0 48%;}")
    webserver.content_send(".hvac-inline{display:flex;align-items:center;gap:5px;}")
    webserver.content_send(".hvac-btn{margin:0;border:none;border-radius:3px;cursor:pointer;background:#fff;color:#1fa3ec;font-size:1em;flex:0 0 48%;}")
    webserver.content_send("select.hvac-btn{padding:5px 10px;}")
    webserver.content_send("button.hvac-btn{padding:3px;font-size:0.9em;}")
    webserver.content_send(".hvac-btn:hover{background:#e0e0e0;}")
    webserver.content_send(".hvac-btn:active{background:#c0c0c0;}")
    webserver.content_send(".hvac-toggle-btn{width:100%;padding:10px;margin:10px 0;background:#1fa3ec;color:#fff;border:none;border-radius:5px;cursor:pointer;font-weight:bold;font-size:1em;}")
    webserver.content_send(".hvac-toggle-btn:hover{background:#1890d0;}")
    webserver.content_send(".hvac-controls-container{display:none;}")
    webserver.content_send(".hvac-controls-container.show{display:block;}")
    webserver.content_send(".hvac-temp-btns{display:flex;gap:3px;flex:0 0 48%;align-items:center;}")
    webserver.content_send(".hvac-temp-btns button{flex:1;}")
    webserver.content_send("</style>")

    webserver.content_send("<script>")
    webserver.content_send("function toggleHVACControls(){")
    webserver.content_send("var container=document.getElementById('hvac-controls');")
    webserver.content_send("var btn=document.getElementById('hvac-toggle');")
    webserver.content_send("container.classList.toggle('show');")
    webserver.content_send("if(container.classList.contains('show')){")
    webserver.content_send("btn.innerHTML='HVAC Control&nbsp;&nbsp;&nbsp;&#9650;';")
    webserver.content_send("}else{")
    webserver.content_send("btn.innerHTML='HVAC Control&nbsp;&nbsp;&nbsp;&#9660;';")
    webserver.content_send("}")
    webserver.content_send("}")
    webserver.content_send("</script>")

    webserver.content_send("<button id='hvac-toggle' class='hvac-toggle-btn' onclick='toggleHVACControls();'>HVAC Control&nbsp;&nbsp;&nbsp;&#9660;</button>")
    webserver.content_send("<div id='hvac-controls' class='hvac-controls-container'>")

    # Temperature Control
    webserver.content_send("<div class='hvac-control compact'><div class='hvac-inline'>")
    webserver.content_send("<div class='hvac-title'>Set Temperature</div>")
    webserver.content_send("<div class='hvac-temp-btns'>")
    webserver.content_send(string.format("<button class='hvac-btn' onclick='la(\"&m_miel_temp=-1\");'>-1°%s</button>", sensors['TempUnit']))
    webserver.content_send(string.format("<button class='hvac-btn' onclick='la(\"&m_miel_temp=0.5\");'>+&#189;°%s</button>", sensors['TempUnit']))
    webserver.content_send(string.format("<button class='hvac-btn' onclick='la(\"&m_miel_temp=1\");'>+1°%s</button>", sensors['TempUnit']))
    webserver.content_send("</div></div></div>")

    # Fan Speed Control
    webserver.content_send("<div class='hvac-control'><div class='hvac-inline'>")
    webserver.content_send("<div class='hvac-title'>Fan Speed</div>")
    var current_fan = str(sensors['MiElHVAC']['FanSpeed'])
    webserver.content_send("<select class='hvac-btn' onchange='la(\"&m_miel_fan=\"+this.value);'>")
    webserver.content_send("<option value=''>Select Speed...</option>")
    webserver.content_send(string.format("<option value='auto'%s>Auto</option>",   current_fan == 'auto'  ? ' selected' : ''))
    webserver.content_send(string.format("<option value='quiet'%s>Quiet</option>", current_fan == 'quiet' ? ' selected' : ''))
    webserver.content_send(string.format("<option value='1'%s>Speed 1</option>",   current_fan == '1'     ? ' selected' : ''))
    webserver.content_send(string.format("<option value='2'%s>Speed 2</option>",   current_fan == '2'     ? ' selected' : ''))
    webserver.content_send(string.format("<option value='3'%s>Speed 3</option>",   current_fan == '3'     ? ' selected' : ''))
    webserver.content_send(string.format("<option value='4'%s>Speed 4</option>",   current_fan == '4'     ? ' selected' : ''))
    webserver.content_send("</select></div></div>")

    # Swing Vertical Control
    webserver.content_send("<div class='hvac-control'><div class='hvac-inline'>")
    webserver.content_send("<div class='hvac-title'>Swing Vertical</div>")
    var current_swingv = sensors['MiElHVAC']['SwingV']
    webserver.content_send("<select class='hvac-btn' onchange='la(\"&m_miel_swingv=\"+this.value);'>")
    webserver.content_send("<option value=''>Select Position...</option>")
    webserver.content_send(string.format("<option value='auto'%s>Auto</option>",              current_swingv == 'auto'        ? ' selected' : ''))
    webserver.content_send(string.format("<option value='up'%s>Up</option>",                  current_swingv == 'up'          ? ' selected' : ''))
    webserver.content_send(string.format("<option value='up_middle'%s>Up Middle</option>",    current_swingv == 'up_middle'   ? ' selected' : ''))
    webserver.content_send(string.format("<option value='center'%s>Center</option>",          current_swingv == 'center'      ? ' selected' : ''))
    webserver.content_send(string.format("<option value='down_middle'%s>Down Middle</option>",current_swingv == 'down_middle' ? ' selected' : ''))
    webserver.content_send(string.format("<option value='down'%s>Down</option>",              current_swingv == 'down'        ? ' selected' : ''))
    webserver.content_send(string.format("<option value='swing'%s>Swing</option>",            current_swingv == 'swing'       ? ' selected' : ''))
    webserver.content_send("</select></div></div>")

    # Swing Horizontal Control
    webserver.content_send("<div class='hvac-control'><div class='hvac-inline'>")
    webserver.content_send("<div class='hvac-title'>Swing Horizontal</div>")
    var current_swingh = sensors['MiElHVAC']['SwingH']
    webserver.content_send("<select class='hvac-btn' onchange='la(\"&m_miel_swingh=\"+this.value);'>")
    webserver.content_send("<option value=''>Select Position...</option>")
    webserver.content_send(string.format("<option value='auto'%s>Auto</option>",               current_swingh == 'auto'         ? ' selected' : ''))
    webserver.content_send(string.format("<option value='left'%s>Left</option>",               current_swingh == 'left'         ? ' selected' : ''))
    webserver.content_send(string.format("<option value='left_middle'%s>Left Middle</option>", current_swingh == 'left_middle'  ? ' selected' : ''))
    webserver.content_send(string.format("<option value='center'%s>Center</option>",           current_swingh == 'center'       ? ' selected' : ''))
    webserver.content_send(string.format("<option value='right'%s>Right</option>",             current_swingh == 'right'        ? ' selected' : ''))
    webserver.content_send(string.format("<option value='right_middle'%s>Right Middle</option>",current_swingh == 'right_middle'? ' selected' : ''))
    webserver.content_send(string.format("<option value='split'%s>Split</option>",             current_swingh == 'split'        ? ' selected' : ''))
    webserver.content_send(string.format("<option value='swing'%s>Swing</option>",             current_swingh == 'swing'        ? ' selected' : ''))
    webserver.content_send("</select></div></div>")

    # Mode Control
    webserver.content_send("<div class='hvac-control'><div class='hvac-inline'>")
    webserver.content_send("<div class='hvac-title'>Mode</div>")
    var current_mode = sensors['MiElHVAC']['Mode']
    webserver.content_send("<select class='hvac-btn' onchange='la(\"&m_miel_mode=\"+this.value);'>")
    webserver.content_send("<option value=''>Select Mode...</option>")
    webserver.content_send(string.format("<option value='heat'%s>Heat</option>", current_mode == 'heat' ? ' selected' : ''))
    webserver.content_send(string.format("<option value='cool'%s>Cool</option>", current_mode == 'cool' ? ' selected' : ''))
    webserver.content_send(string.format("<option value='dry'%s>Dry</option>",   current_mode == 'dry'  ? ' selected' : ''))
    webserver.content_send(string.format("<option value='fan'%s>Fan</option>",   current_mode == 'fan'  ? ' selected' : ''))
    webserver.content_send(string.format("<option value='auto'%s>Auto</option>", current_mode == 'auto' ? ' selected' : ''))
    webserver.content_send("</select></div></div>")

    webserver.content_send("</div>")  # close hvac-controls-container
  end

end

HVAC = HVAC()
tasmota.add_driver(HVAC)
