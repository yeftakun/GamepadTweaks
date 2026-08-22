local cfgPath = ac.getFolder(ac.FolderID.ExtCfgUser) .. '/hall_config.ini'

local shared = ac.connect({
    key = ac.StructItem.key('HallConfig_Telemetry_v1'),
    rawGas = ac.StructItem.float(),
    processedGas = ac.StructItem.float(),
    rawBrake = ac.StructItem.float(),
    processedBrake = ac.StructItem.float()
}, true)

local state = {
    global = { nativeVibrationMultiplier = 1.0 },
    effects = {
        slip = 1.0, kerb = 1.0, abs = 1.0, collision = 1.0,
        gforce = 1.0, offroad = 1.0, engine = 1.0, gearshift = 1.0
    },
    rt = {
        hysteresisEnable = true, hysteresisThresholdUp = 0.27, hysteresisThresholdDown = 0.23,
        smoothingEnable = true, smoothingTimeConstant = 0.015,
        vibration = { enable = true, motor = 1, mode = 0, maxVibrationPercent = 80 }
    },
    lt = {
        hysteresisEnable = true, hysteresisThresholdUp = 0.27, hysteresisThresholdDown = 0.23,
        smoothingEnable = true, smoothingTimeConstant = 0.015,
        vibration = { enable = true, motor = 0, mode = 0, maxVibrationPercent = 80 }
    }
}

local function loadTriggerConfig(cfg, prefix, ts)
    ts.hysteresisEnable = cfg:get(prefix .. '_HYSTERESIS', 'ENABLE', true)
    ts.hysteresisThresholdUp = cfg:get(prefix .. '_HYSTERESIS', 'UP', 0.27)
    ts.hysteresisThresholdDown = cfg:get(prefix .. '_HYSTERESIS', 'DOWN', 0.23)
    
    ts.smoothingEnable = cfg:get(prefix .. '_SMOOTHING', 'ENABLE', true)
    ts.smoothingTimeConstant = cfg:get(prefix .. '_SMOOTHING', 'TIME_CONSTANT', 0.015)
    
    local defaultMotor = (prefix == 'RT') and 1 or 0
    ts.vibration.enable = cfg:get(prefix .. '_VIBRATION', 'ENABLE', true)
    ts.vibration.motor = cfg:get(prefix .. '_VIBRATION', 'MOTOR', defaultMotor)
    ts.vibration.mode = cfg:get(prefix .. '_VIBRATION', 'MODE', 0)
    ts.vibration.maxVibrationPercent = cfg:get(prefix .. '_VIBRATION', 'MAX', 80)
end

local function saveTriggerConfig(cfg, prefix, ts)
    cfg:set(prefix .. '_HYSTERESIS', 'ENABLE', ts.hysteresisEnable)
    cfg:set(prefix .. '_HYSTERESIS', 'UP', ts.hysteresisThresholdUp)
    cfg:set(prefix .. '_HYSTERESIS', 'DOWN', ts.hysteresisThresholdDown)
    
    cfg:set(prefix .. '_SMOOTHING', 'ENABLE', ts.smoothingEnable)
    cfg:set(prefix .. '_SMOOTHING', 'TIME_CONSTANT', ts.smoothingTimeConstant)
    
    cfg:set(prefix .. '_VIBRATION', 'ENABLE', ts.vibration.enable)
    cfg:set(prefix .. '_VIBRATION', 'MOTOR', ts.vibration.motor)
    cfg:set(prefix .. '_VIBRATION', 'MODE', ts.vibration.mode)
    cfg:set(prefix .. '_VIBRATION', 'MAX', ts.vibration.maxVibrationPercent)
end

local function loadConfig()
    local cfg = ac.INIConfig.load(cfgPath)
    state.global.nativeVibrationMultiplier = cfg:get('GLOBAL', 'NATIVE_MULTIPLIER', 1.0)
    
    state.effects.slip = cfg:get('EFFECTS', 'SLIP', 1.0)
    state.effects.kerb = cfg:get('EFFECTS', 'KERB', 1.0)
    state.effects.abs = cfg:get('EFFECTS', 'ABS', 1.0)
    state.effects.collision = cfg:get('EFFECTS', 'COLLISION', 1.0)
    state.effects.gforce = cfg:get('EFFECTS', 'GFORCE', 1.0)
    state.effects.offroad = cfg:get('EFFECTS', 'OFFROAD', 1.0)
    state.effects.engine = cfg:get('EFFECTS', 'ENGINE', 1.0)
    state.effects.gearshift = cfg:get('EFFECTS', 'GEARSHIFT', 1.0)
    
    loadTriggerConfig(cfg, 'RT', state.rt)
    loadTriggerConfig(cfg, 'LT', state.lt)
end

local function saveConfig()
    local cfg = ac.INIConfig.load(cfgPath)
    cfg:set('GLOBAL', 'NATIVE_MULTIPLIER', state.global.nativeVibrationMultiplier)
    
    cfg:set('EFFECTS', 'SLIP', state.effects.slip)
    cfg:set('EFFECTS', 'KERB', state.effects.kerb)
    cfg:set('EFFECTS', 'ABS', state.effects.abs)
    cfg:set('EFFECTS', 'COLLISION', state.effects.collision)
    cfg:set('EFFECTS', 'GFORCE', state.effects.gforce)
    cfg:set('EFFECTS', 'OFFROAD', state.effects.offroad)
    cfg:set('EFFECTS', 'ENGINE', state.effects.engine)
    cfg:set('EFFECTS', 'GEARSHIFT', state.effects.gearshift)

    saveTriggerConfig(cfg, 'RT', state.rt)
    saveTriggerConfig(cfg, 'LT', state.lt)
    cfg:save(cfgPath)
end

loadConfig()

local motorLabels = { [0] = "Left (Low Freq)", [1] = "Right (High Freq)" }
local modeLabels = { [0] = "Proportional", [1] = "Static" }

local needsSave = false
local saveDelayTimer = 0.0
local currentTriggerTab = "rt" -- "rt" atau "lt"
local showEffectsConfig = false

function windowMain(dt)
    local dirty = false
    local val, changed
    
    -- === Global Settings ===
    ui.pushFont(ui.Font.Title)
    ui.text("Global Settings")
    ui.popFont()
    
    val, changed = ui.slider("##native_mult", state.global.nativeVibrationMultiplier, 0.0, 5.0, "Native Vibration")
    if changed then
        state.global.nativeVibrationMultiplier = val
        dirty = true
    end
    if state.global.nativeVibrationMultiplier > 0.0 then
        ui.sameLine(0, 10)
        ui.textColored(string.format("(%.1fx)", state.global.nativeVibrationMultiplier), rgbm(1, 1, 0, 1))
    end
    
    if ui.button("Available Effects", vec2(-1, 0)) then
        showEffectsConfig = not showEffectsConfig
    end
    
    if showEffectsConfig then
        ui.childWindow("effects_window", vec2(-1, 220), function()
            ui.textColored("Individual Effect Multipliers", rgbm(0.5, 0.8, 1.0, 1.0))
            ui.separator()
            
            local effs = {
                { key = "slip", label = "Tire Slip" },
                { key = "kerb", label = "Kerbs / Road" },
                { key = "abs", label = "ABS" },
                { key = "collision", label = "Collisions" },
                { key = "gforce", label = "G-Force / Suspension" },
                { key = "offroad", label = "Off-road / Gravel" },
                { key = "engine", label = "Engine RPM" },
                { key = "gearshift", label = "Gearshifts" }
            }
            
            for _, e in ipairs(effs) do
                ui.pushID(e.key)
                ui.text(e.label)
                ui.sameLine(140)
                val, changed = ui.slider("##sld", state.effects[e.key], 0.0, 1.0, "%.1fx")
                if changed then
                    state.effects[e.key] = val
                    dirty = true
                end
                ui.popID()
            end
        end)
    end
    ui.separator()

    -- Pilihan Trigger Tab
    ui.pushFont(ui.Font.Title)
    ui.text("Select Trigger to Configure:")
    ui.popFont()
    
    local currentTabText = currentTriggerTab == "rt" and "Right Trigger (Gas)" or "Left Trigger (Brake)"
    ui.combo("##triggerSelect", currentTabText, ui.ComboFlags.None, function()
        if ui.selectable("Right Trigger (Gas)", currentTriggerTab == "rt") then currentTriggerTab = "rt" end
        if ui.selectable("Left Trigger (Brake)", currentTriggerTab == "lt") then currentTriggerTab = "lt" end
    end)
    ui.separator()

    -- Render Pengaturan berdasarkan tab yang aktif
    local ts = state[currentTriggerTab]

    -- === Hysteresis ===
    ui.header("Hysteresis Deadzone")
    if ui.checkbox("Enable Hysteresis", ts.hysteresisEnable) then
        ts.hysteresisEnable = not ts.hysteresisEnable
        dirty = true
    end

    val, changed = ui.slider("##hyst_up", ts.hysteresisThresholdUp, 0.0, 1.0, "Threshold Up: %.2f")
    if changed then 
        ts.hysteresisThresholdUp = val
        -- Paksa Threshold Down agar tidak lebih besar dari Threshold Up
        if ts.hysteresisThresholdDown > val then
            ts.hysteresisThresholdDown = val
        end
        dirty = true 
    end

    val, changed = ui.slider("##hyst_down", ts.hysteresisThresholdDown, 0.0, 1.0, "Threshold Down: %.2f")
    if changed then 
        ts.hysteresisThresholdDown = val
        -- Paksa Threshold Up agar tidak lebih kecil dari Threshold Down
        if ts.hysteresisThresholdUp < val then
            ts.hysteresisThresholdUp = val
        end
        dirty = true 
    end

    -- === Smoothing ===
    ui.separator()
    ui.header("Smoothing (EMA)")
    if ui.checkbox("Enable Smoothing", ts.smoothingEnable) then
        ts.smoothingEnable = not ts.smoothingEnable
        dirty = true
    end

    val, changed = ui.slider("##smooth_tc", ts.smoothingTimeConstant, 0.001, 0.1, "Time Constant: %.3f s")
    if changed then ts.smoothingTimeConstant = val; dirty = true end

    -- === Vibration ===
    ui.separator()
    ui.header("Vibration Feedback")
    if ui.checkbox("Enable Vibration", ts.vibration.enable) then
        ts.vibration.enable = not ts.vibration.enable
        dirty = true
    end

    ui.combo("Motor", motorLabels[ts.vibration.motor], ui.ComboFlags.None, function()
        if ui.selectable("Left (Low Freq)", ts.vibration.motor == 0) then ts.vibration.motor = 0; dirty = true end
        if ui.selectable("Right (High Freq)", ts.vibration.motor == 1) then ts.vibration.motor = 1; dirty = true end
    end)

    ui.combo("Mode", modeLabels[ts.vibration.mode], ui.ComboFlags.None, function()
        if ui.selectable("Proportional", ts.vibration.mode == 0) then ts.vibration.mode = 0; dirty = true end
        if ui.selectable("Static", ts.vibration.mode == 1) then ts.vibration.mode = 1; dirty = true end
    end)

    val, changed = ui.slider("##vib_max", ts.vibration.maxVibrationPercent, 0, 100, "Max Vibration: %.0f%%")
    if changed then ts.vibration.maxVibrationPercent = val; dirty = true end

    -- === Telemetry Preview ===
    ui.separator()
    ui.header("Live Telemetry Preview")
    
    if shared then
        local rawVal = currentTriggerTab == "rt" and (shared.rawGas or 0.0) or (shared.rawBrake or 0.0)
        local procVal = currentTriggerTab == "rt" and (shared.processedGas or 0.0) or (shared.processedBrake or 0.0)
        
        ui.text("Raw Input:  ")
        ui.sameLine(100)
        ui.progressBar(rawVal, vec2(-1, 14), string.format("%.1f%%", rawVal * 100))
        
        ui.text("Processed:  ")
        ui.sameLine(100)
        ui.progressBar(procVal, vec2(-1, 14), string.format("%.1f%%", procVal * 100))
    else
        ui.text("Waiting for telemetry data...")
    end

    -- === AutoSave Logic ===
    if dirty then
        needsSave = true
        saveDelayTimer = 0.5
    end

    if needsSave then
        saveDelayTimer = saveDelayTimer - dt
        if saveDelayTimer <= 0 then
            saveConfig()
            needsSave = false
            ui.toast(ui.Icons.Save, "Config Saved")
        end
    end
end
