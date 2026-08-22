local cfgPath = ac.getFolder(ac.FolderID.ExtCfgUser) .. '/hall_config.ini'

-- Load awal konfigurasi
local cfg = ac.INIConfig.load(cfgPath)

local state = {
    hysteresisEnable = cfg:get('HYSTERESIS', 'ENABLE', true),
    hysteresisThresholdUp = cfg:get('HYSTERESIS', 'UP', 0.27),
    hysteresisThresholdDown = cfg:get('HYSTERESIS', 'DOWN', 0.23),
    
    smoothingEnable = cfg:get('SMOOTHING', 'ENABLE', true),
    smoothingTimeConstant = cfg:get('SMOOTHING', 'TIME_CONSTANT', 0.015),
    
    vibRTEnable = cfg:get('VIBRATION_RT', 'ENABLE', true),
    vibRTMotor = cfg:get('VIBRATION_RT', 'MOTOR', 1), -- 1=right, 0=left
    vibRTMode = cfg:get('VIBRATION_RT', 'MODE', 0),   -- 0=proportional, 1=static
    vibRTMax = cfg:get('VIBRATION_RT', 'MAX', 80),
    
    vibLTEnable = cfg:get('VIBRATION_LT', 'ENABLE', true),
    vibLTMotor = cfg:get('VIBRATION_LT', 'MOTOR', 0),
    vibLTMode = cfg:get('VIBRATION_LT', 'MODE', 0),
    vibLTMax = cfg:get('VIBRATION_LT', 'MAX', 80)
}

local function saveState()
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

-- Helper render dropdown/combo
local function renderMotorCombo(label, currentVal)
    local changed = false
    local newVal = currentVal
    local currentText = (currentVal == 0) and "Left (Low Freq)" or "Right (High Freq)"
    
    ui.combo(label, currentText, ui.ComboFlags.None, function()
        if ui.selectable("Left (Low Freq)", currentVal == 0) then newVal = 0; changed = true end
        if ui.selectable("Right (High Freq)", currentVal == 1) then newVal = 1; changed = true end
    end)
    return changed, newVal
end

local function renderModeCombo(label, currentVal)
    local changed = false
    local newVal = currentVal
    local currentText = (currentVal == 0) and "Proportional" or "Static"
    
    ui.combo(label, currentText, ui.ComboFlags.None, function()
        if ui.selectable("Proportional", currentVal == 0) then newVal = 0; changed = true end
        if ui.selectable("Static", currentVal == 1) then newVal = 1; changed = true end
    end)
    return changed, newVal
end

function windowMain()
    local dirty = false
    local b, changed, val

    ui.header("Hysteresis Deadzone")
    b = ui.checkbox("Enable Hysteresis", state.hysteresisEnable)
    if b ~= state.hysteresisEnable then state.hysteresisEnable = b; dirty = true end
    
    changed, val = ui.slider("Threshold Up", state.hysteresisThresholdUp, 0.0, 1.0, "%.2f")
    if changed then state.hysteresisThresholdUp = val; dirty = true end

    changed, val = ui.slider("Threshold Down", state.hysteresisThresholdDown, 0.0, 1.0, "%.2f")
    if changed then state.hysteresisThresholdDown = val; dirty = true end

    ui.separator()
    ui.header("Smoothing (EMA)")
    b = ui.checkbox("Enable Smoothing", state.smoothingEnable)
    if b ~= state.smoothingEnable then state.smoothingEnable = b; dirty = true end

    changed, val = ui.slider("Time Constant (s)", state.smoothingTimeConstant, 0.0, 0.1, "%.3f")
    if changed then state.smoothingTimeConstant = val; dirty = true end

    ui.separator()
    ui.header("Vibration - Right Trigger (Gas)")
    b = ui.checkbox("Enable RT Vib", state.vibRTEnable)
    if b ~= state.vibRTEnable then state.vibRTEnable = b; dirty = true end

    changed, val = renderMotorCombo("Motor##RT", state.vibRTMotor)
    if changed then state.vibRTMotor = val; dirty = true end

    changed, val = renderModeCombo("Mode##RT", state.vibRTMode)
    if changed then state.vibRTMode = val; dirty = true end

    changed, val = ui.slider("Max Vibration##RT", state.vibRTMax, 0, 100, "%.0f%%")
    if changed then state.vibRTMax = val; dirty = true end

    ui.separator()
    ui.header("Vibration - Left Trigger (Brake)")
    b = ui.checkbox("Enable LT Vib", state.vibLTEnable)
    if b ~= state.vibLTEnable then state.vibLTEnable = b; dirty = true end

    changed, val = renderMotorCombo("Motor##LT", state.vibLTMotor)
    if changed then state.vibLTMotor = val; dirty = true end

    changed, val = renderModeCombo("Mode##LT", state.vibLTMode)
    if changed then state.vibLTMode = val; dirty = true end

    changed, val = ui.slider("Max Vibration##LT", state.vibLTMax, 0, 100, "%.0f%%")
    if changed then state.vibLTMax = val; dirty = true end

    if dirty then
        saveState()
    end
end
