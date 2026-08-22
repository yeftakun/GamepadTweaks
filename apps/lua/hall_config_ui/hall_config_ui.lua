local cfgPath = ac.getFolder(ac.FolderID.ExtCfgUser) .. '/hall_config.ini'

-- State lokal untuk UI
local state = {
    hysteresisEnable = true,
    hysteresisThresholdUp = 0.27,
    hysteresisThresholdDown = 0.23,

    smoothingEnable = true,
    smoothingTimeConstant = 0.015,

    vibRTEnable = true,
    vibRTMotor = 1,   -- 1=right, 0=left
    vibRTMode = 0,    -- 0=proportional, 1=static
    vibRTMax = 80,

    vibLTEnable = true,
    vibLTMotor = 0,
    vibLTMode = 0,
    vibLTMax = 80
}

-- Load config dari file INI (jika ada)
local function loadConfig()
    local cfg = ac.INIConfig.load(cfgPath)
    state.hysteresisEnable = cfg:get('HYSTERESIS', 'ENABLE', true)
    state.hysteresisThresholdUp = cfg:get('HYSTERESIS', 'UP', 0.27)
    state.hysteresisThresholdDown = cfg:get('HYSTERESIS', 'DOWN', 0.23)
    state.smoothingEnable = cfg:get('SMOOTHING', 'ENABLE', true)
    state.smoothingTimeConstant = cfg:get('SMOOTHING', 'TIME_CONSTANT', 0.015)
    state.vibRTEnable = cfg:get('VIBRATION_RT', 'ENABLE', true)
    state.vibRTMotor = cfg:get('VIBRATION_RT', 'MOTOR', 1)
    state.vibRTMode = cfg:get('VIBRATION_RT', 'MODE', 0)
    state.vibRTMax = cfg:get('VIBRATION_RT', 'MAX', 80)
    state.vibLTEnable = cfg:get('VIBRATION_LT', 'ENABLE', true)
    state.vibLTMotor = cfg:get('VIBRATION_LT', 'MOTOR', 0)
    state.vibLTMode = cfg:get('VIBRATION_LT', 'MODE', 0)
    state.vibLTMax = cfg:get('VIBRATION_LT', 'MAX', 80)
end

-- Save config ke file INI
local function saveConfig()
    local cfg = ac.INIConfig.load(cfgPath)
    cfg:set('HYSTERESIS', 'ENABLE', state.hysteresisEnable)
    cfg:set('HYSTERESIS', 'UP', state.hysteresisThresholdUp)
    cfg:set('HYSTERESIS', 'DOWN', state.hysteresisThresholdDown)
    cfg:set('SMOOTHING', 'ENABLE', state.smoothingEnable)
    cfg:set('SMOOTHING', 'TIME_CONSTANT', state.smoothingTimeConstant)
    cfg:set('VIBRATION_RT', 'ENABLE', state.vibRTEnable)
    cfg:set('VIBRATION_RT', 'MOTOR', state.vibRTMotor)
    cfg:set('VIBRATION_RT', 'MODE', state.vibRTMode)
    cfg:set('VIBRATION_RT', 'MAX', state.vibRTMax)
    cfg:set('VIBRATION_LT', 'ENABLE', state.vibLTEnable)
    cfg:set('VIBRATION_LT', 'MOTOR', state.vibLTMotor)
    cfg:set('VIBRATION_LT', 'MODE', state.vibLTMode)
    cfg:set('VIBRATION_LT', 'MAX', state.vibLTMax)
    cfg:save(cfgPath)
end

-- Load config saat script start
loadConfig()

-- Helper: dropdown motor
local motorLabels = { [0] = "Left (Low Freq)", [1] = "Right (High Freq)" }
local modeLabels = { [0] = "Proportional", [1] = "Static" }

function windowMain(dt)
    local dirty = false
    local val, changed

    -- === Hysteresis ===
    ui.header("Hysteresis Deadzone")
    if ui.checkbox("Enable Hysteresis", state.hysteresisEnable) then
        state.hysteresisEnable = not state.hysteresisEnable
        dirty = true
    end

    val, changed = ui.slider("##hyst_up", state.hysteresisThresholdUp, 0.0, 1.0, "Threshold Up: %.2f")
    if changed then state.hysteresisThresholdUp = val; dirty = true end

    val, changed = ui.slider("##hyst_down", state.hysteresisThresholdDown, 0.0, 1.0, "Threshold Down: %.2f")
    if changed then state.hysteresisThresholdDown = val; dirty = true end

    -- === Smoothing ===
    ui.separator()
    ui.header("Smoothing (EMA)")
    if ui.checkbox("Enable Smoothing", state.smoothingEnable) then
        state.smoothingEnable = not state.smoothingEnable
        dirty = true
    end

    val, changed = ui.slider("##smooth_tc", state.smoothingTimeConstant, 0.001, 0.1, "Time Constant: %.3f s")
    if changed then state.smoothingTimeConstant = val; dirty = true end

    -- === Vibration RT ===
    ui.separator()
    ui.header("Vibration - Right Trigger (Gas)")
    if ui.checkbox("Enable RT Vibration", state.vibRTEnable) then
        state.vibRTEnable = not state.vibRTEnable
        dirty = true
    end

    ui.combo("Motor##RT", motorLabels[state.vibRTMotor], ui.ComboFlags.None, function()
        if ui.selectable("Left (Low Freq)", state.vibRTMotor == 0) then state.vibRTMotor = 0; dirty = true end
        if ui.selectable("Right (High Freq)", state.vibRTMotor == 1) then state.vibRTMotor = 1; dirty = true end
    end)

    ui.combo("Mode##RT", modeLabels[state.vibRTMode], ui.ComboFlags.None, function()
        if ui.selectable("Proportional", state.vibRTMode == 0) then state.vibRTMode = 0; dirty = true end
        if ui.selectable("Static", state.vibRTMode == 1) then state.vibRTMode = 1; dirty = true end
    end)

    val, changed = ui.slider("##rt_max", state.vibRTMax, 0, 100, "Max Vibration: %.0f%%")
    if changed then state.vibRTMax = val; dirty = true end

    -- === Vibration LT ===
    ui.separator()
    ui.header("Vibration - Left Trigger (Brake)")
    if ui.checkbox("Enable LT Vibration", state.vibLTEnable) then
        state.vibLTEnable = not state.vibLTEnable
        dirty = true
    end

    ui.combo("Motor##LT", motorLabels[state.vibLTMotor], ui.ComboFlags.None, function()
        if ui.selectable("Left (Low Freq)", state.vibLTMotor == 0) then state.vibLTMotor = 0; dirty = true end
        if ui.selectable("Right (High Freq)", state.vibLTMotor == 1) then state.vibLTMotor = 1; dirty = true end
    end)

    ui.combo("Mode##LT", modeLabels[state.vibLTMode], ui.ComboFlags.None, function()
        if ui.selectable("Proportional", state.vibLTMode == 0) then state.vibLTMode = 0; dirty = true end
        if ui.selectable("Static", state.vibLTMode == 1) then state.vibLTMode = 1; dirty = true end
    end)

    val, changed = ui.slider("##lt_max", state.vibLTMax, 0, 100, "Max Vibration: %.0f%%")
    if changed then state.vibLTMax = val; dirty = true end

    -- Save hanya ketika ada perubahan
    if dirty then
        saveConfig()
    end
end
