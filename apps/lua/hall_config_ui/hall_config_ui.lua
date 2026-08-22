local cfgPath = ac.getFolder(ac.FolderID.ExtCfgUser) .. '/hall_config.ini'

-- Shared memory untuk menerima data dari Gamepad FX
local shared = ac.connect({
    key = ac.StructItem.key('HallConfig_Telemetry_v1'),
    rawGas = ac.StructItem.float(),
    processedGas = ac.StructItem.float(),
    rawBrake = ac.StructItem.float(),
    processedBrake = ac.StructItem.float()
}, true)

-- State lokal untuk UI
local state = {
    hysteresisEnable = true,
    hysteresisThresholdUp = 0.27,
    hysteresisThresholdDown = 0.23,

    smoothingEnable = true,
    smoothingTimeConstant = 0.015,

    vibRTEnable = true,
    vibRTMotor = 1,
    vibRTMode = 0,
    vibRTMax = 80,

    vibLTEnable = true,
    vibLTMotor = 0,
    vibLTMode = 0,
    vibLTMax = 80
}

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

loadConfig()

local motorLabels = { [0] = "Left (Low Freq)", [1] = "Right (High Freq)" }
local modeLabels = { [0] = "Proportional", [1] = "Static" }

-- Variables for AutoSave (Debounce)
local needsSave = false
local saveDelayTimer = 0.0
local alertTimer = 0.0

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

    -- === AutoSave Logic ===
    -- Jika ada pergerakan slider/checkbox, mulai ulang timer 0.5 detik
    if dirty then
        needsSave = true
        saveDelayTimer = 0.5
    end

    -- Hitung mundur timer save
    if needsSave then
        saveDelayTimer = saveDelayTimer - dt
        if saveDelayTimer <= 0 then
            saveConfig()
            needsSave = false
            alertTimer = 3.0 -- Tampilkan alert "Saved" selama 3 detik
        end
    end

    -- === Alert Message ===
    if alertTimer > 0 then
        alertTimer = alertTimer - dt
        ui.separator()
        ui.textColored("Saved", rgbm(0.2, 1.0, 0.2, 1.0))
        ui.toast(ui.Icons.Save, "HallConfig Saved")
    end

    -- === Telemetry Preview ===
    ui.separator()
    ui.header("Preview: Telemetry")
    
    -- Pastikan object shared tidak nil sebelum dibaca
    if shared then
        -- Gas
        ui.text("RT Raw   ")
        ui.sameLine(80)
        ui.progressBar(shared.rawGas or 0.0, vec2(-1, 14), string.format("%.1f%%", (shared.rawGas or 0) * 100))
        
        ui.text("RT Proc  ")
        ui.sameLine(80)
        ui.progressBar(shared.processedGas or 0.0, vec2(-1, 14), string.format("%.1f%%", (shared.processedGas or 0) * 100))
        
        ui.offsetCursorY(5)
        
        -- Brake
        ui.text("LT Raw   ")
        ui.sameLine(80)
        ui.progressBar(shared.rawBrake or 0.0, vec2(-1, 14), string.format("%.1f%%", (shared.rawBrake or 0) * 100))
        
        ui.text("LT Proc  ")
        ui.sameLine(80)
        ui.progressBar(shared.processedBrake or 0.0, vec2(-1, 14), string.format("%.1f%%", (shared.processedBrake or 0) * 100))
    else
        ui.text("Waiting for telemetry data...")
    end
end
