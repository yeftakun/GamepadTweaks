local cfgPath = ac.getFolder(ac.FolderID.ExtCfgUser) .. '/gamepad_tweaks.ini'

-- === Response Curve helpers (harus sama dengan config.lua / signal.lua di sisi script) ===
local MIN_SLOPE = 0.2

local function clampKnee(x, y)
    x = math.max(0.05, math.min(0.95, x))
    local yMin = math.max(0.05, MIN_SLOPE * x)
    local yMax = math.min(0.95, 1.0 - MIN_SLOPE * (1.0 - x))
    y = math.max(yMin, math.min(yMax, y))
    return x, y
end

local function bezier(x, cx, cy)
    if x <= 0.0 then return 0.0 end
    if x >= 1.0 then return 1.0 end
    local t = x / (cx + math.sqrt(cx * cx + (1.0 - 2.0 * cx) * x))
    return 2.0 * (1.0 - t) * t * cy + t * t
end

local CURVE_PRESETS = {
    { name = "Linear",     x = 0.50, y = 0.50, tip = "Straight response. No change to the hysteresis output." },
    { name = "Soft start", x = 0.60, y = 0.30, tip = "Light pressure is dulled, deep pressure is more responsive.\nA good starting point for throttle." },
    { name = "Quick bite", x = 0.45, y = 0.60, tip = "Light pressure reacts sooner, deep pressure is finer.\nA good starting point for brake." },
}

local CURVE_HELP = table.concat({
    "Response Curve",
    "",
    "Changes how strongly the trigger reacts to finger pressure.",
    "The dashed diagonal is a straight response. The blue line is",
    "yours, and the hollow circle is the knee that pulls the curve",
    "toward it. The red dot is where the trigger is right now.",
    "",
    "Knee below the diagonal: light pressure is dulled and deep",
    "pressure is more responsive. Good for throttle if your finger",
    "feels too twitchy.",
    "",
    "Knee above the diagonal: light pressure reacts right away and",
    "deep pressure is finer. Good for brake bite.",
    "",
    "How to tune:",
    "1. Set Hysteresis first, then the Curve.",
    "2. Start from a preset and nudge Knee Y a little at a time.",
    "3. Compare Raw and Processed in Live Telemetry, and toggle",
    "   Enable Curve to A/B test.",
    "4. Test on track before settling.",
}, "\n")

local shared = ac.connect({
    key = ac.StructItem.key('GamepadTweaks_Telemetry_v2'),
    rawGas = ac.StructItem.float(),
    processedGas = ac.StructItem.float(),
    rawBrake = ac.StructItem.float(),
    processedBrake = ac.StructItem.float(),
    s1Gas = ac.StructItem.float(),
    s1Brake = ac.StructItem.float()
}, true)

local state = {
    global = { nativeVibrationMultiplier = 1.0 },
    effects = {
        slip = { mult = 1.0, motor = 2 },
        kerb = { mult = 1.0, motor = 2 },
        abs = { mult = 1.0, motor = 2 },
        collision = { mult = 1.0, motor = 2 },
        gforce = { mult = 1.0, motor = 2 },
        offroad = { mult = 1.0, motor = 2 },
        engine = { mult = 1.0, motor = 2 },
        gearshift = { mult = 1.0, motor = 2 }
    },
    rt = {
        hysteresisEnable = true, hysteresisThresholdUp = 0.27, hysteresisThresholdDown = 0.23,
        smoothingEnable = true, smoothingTimeConstant = 0.015,
        curve = { enable = true, x = 0.5, y = 0.5 },
        vibration = { enable = true, motor = 1, mode = 0, maxVibrationPercent = 80 }
    },
    lt = {
        hysteresisEnable = true, hysteresisThresholdUp = 0.27, hysteresisThresholdDown = 0.23,
        smoothingEnable = true, smoothingTimeConstant = 0.015,
        curve = { enable = true, x = 0.5, y = 0.5 },
        vibration = { enable = true, motor = 0, mode = 0, maxVibrationPercent = 80 }
    }
}

local function loadTriggerConfig(cfg, prefix, ts)
    ts.hysteresisEnable = cfg:get(prefix .. '_HYSTERESIS', 'ENABLE', true)
    ts.hysteresisThresholdUp = cfg:get(prefix .. '_HYSTERESIS', 'UP', 0.27)
    ts.hysteresisThresholdDown = cfg:get(prefix .. '_HYSTERESIS', 'DOWN', 0.23)
    
    ts.smoothingEnable = cfg:get(prefix .. '_SMOOTHING', 'ENABLE', true)
    ts.smoothingTimeConstant = cfg:get(prefix .. '_SMOOTHING', 'TIME_CONSTANT', 0.015)
    
    ts.curve.enable = cfg:get(prefix .. '_CURVE', 'ENABLE', true)
    ts.curve.x, ts.curve.y = clampKnee(
        cfg:get(prefix .. '_CURVE', 'X', 0.5),
        cfg:get(prefix .. '_CURVE', 'Y', 0.5))

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

    cfg:set(prefix .. '_CURVE', 'ENABLE', ts.curve.enable)
    cfg:set(prefix .. '_CURVE', 'X', ts.curve.x)
    cfg:set(prefix .. '_CURVE', 'Y', ts.curve.y)
    
    cfg:set(prefix .. '_VIBRATION', 'ENABLE', ts.vibration.enable)
    cfg:set(prefix .. '_VIBRATION', 'MOTOR', ts.vibration.motor)
    cfg:set(prefix .. '_VIBRATION', 'MODE', ts.vibration.mode)
    cfg:set(prefix .. '_VIBRATION', 'MAX', ts.vibration.maxVibrationPercent)
end

local function loadConfig()
    local cfg = ac.INIConfig.load(cfgPath)
    state.global.nativeVibrationMultiplier = cfg:get('GLOBAL', 'NATIVE_MULTIPLIER', 1.0)
    
    state.effects.slip.mult = cfg:get('EFFECTS', 'SLIP', 1.0)
    state.effects.kerb.mult = cfg:get('EFFECTS', 'KERB', 1.0)
    state.effects.abs.mult = cfg:get('EFFECTS', 'ABS', 1.0)
    state.effects.collision.mult = cfg:get('EFFECTS', 'COLLISION', 1.0)
    state.effects.gforce.mult = cfg:get('EFFECTS', 'GFORCE', 1.0)
    state.effects.offroad.mult = cfg:get('EFFECTS', 'OFFROAD', 1.0)
    state.effects.engine.mult = cfg:get('EFFECTS', 'ENGINE', 1.0)
    state.effects.gearshift.mult = cfg:get('EFFECTS', 'GEARSHIFT', 1.0)

    state.effects.slip.motor = cfg:get('EFFECTS_MOTOR', 'SLIP', 2)
    state.effects.kerb.motor = cfg:get('EFFECTS_MOTOR', 'KERB', 2)
    state.effects.abs.motor = cfg:get('EFFECTS_MOTOR', 'ABS', 2)
    state.effects.collision.motor = cfg:get('EFFECTS_MOTOR', 'COLLISION', 2)
    state.effects.gforce.motor = cfg:get('EFFECTS_MOTOR', 'GFORCE', 2)
    state.effects.offroad.motor = cfg:get('EFFECTS_MOTOR', 'OFFROAD', 2)
    state.effects.engine.motor = cfg:get('EFFECTS_MOTOR', 'ENGINE', 2)
    state.effects.gearshift.motor = cfg:get('EFFECTS_MOTOR', 'GEARSHIFT', 2)
    
    loadTriggerConfig(cfg, 'RT', state.rt)
    loadTriggerConfig(cfg, 'LT', state.lt)
end

local function saveConfig()
    local cfg = ac.INIConfig.load(cfgPath)
    cfg:set('GLOBAL', 'NATIVE_MULTIPLIER', state.global.nativeVibrationMultiplier)
    
    cfg:set('EFFECTS', 'SLIP', state.effects.slip.mult)
    cfg:set('EFFECTS', 'KERB', state.effects.kerb.mult)
    cfg:set('EFFECTS', 'ABS', state.effects.abs.mult)
    cfg:set('EFFECTS', 'COLLISION', state.effects.collision.mult)
    cfg:set('EFFECTS', 'GFORCE', state.effects.gforce.mult)
    cfg:set('EFFECTS', 'OFFROAD', state.effects.offroad.mult)
    cfg:set('EFFECTS', 'ENGINE', state.effects.engine.mult)
    cfg:set('EFFECTS', 'GEARSHIFT', state.effects.gearshift.mult)

    cfg:set('EFFECTS_MOTOR', 'SLIP', state.effects.slip.motor)
    cfg:set('EFFECTS_MOTOR', 'KERB', state.effects.kerb.motor)
    cfg:set('EFFECTS_MOTOR', 'ABS', state.effects.abs.motor)
    cfg:set('EFFECTS_MOTOR', 'COLLISION', state.effects.collision.motor)
    cfg:set('EFFECTS_MOTOR', 'GFORCE', state.effects.gforce.motor)
    cfg:set('EFFECTS_MOTOR', 'OFFROAD', state.effects.offroad.motor)
    cfg:set('EFFECTS_MOTOR', 'ENGINE', state.effects.engine.motor)
    cfg:set('EFFECTS_MOTOR', 'GEARSHIFT', state.effects.gearshift.motor)

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
                ui.pushItemWidth(100)
                val, changed = ui.slider("##sld", state.effects[e.key].mult, 0.0, 1.0, "%.1fx")
                if changed then
                    state.effects[e.key].mult = val
                    dirty = true
                end
                ui.popItemWidth()
                ui.sameLine()
                ui.pushItemWidth(120)
                local motorNames = {
                    [0] = "Left (Low)", 
                    [1] = "Right (Hi)", 
                    [2] = "Both"
                }
                local currentMotor = state.effects[e.key].motor
                
                ui.combo("##mot", motorNames[currentMotor] or "Both", ui.ComboFlags.None, function()
                    if ui.selectable("Left (Low)", currentMotor == 0) then 
                        state.effects[e.key].motor = 0; dirty = true 
                    end
                    if ui.selectable("Right (Hi)", currentMotor == 1) then 
                        state.effects[e.key].motor = 1; dirty = true 
                    end
                    if ui.selectable("Both", currentMotor == 2) then 
                        state.effects[e.key].motor = 2; dirty = true 
                    end
                end)
                ui.popItemWidth()
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

    -- === Response Curve (S1 -> S2) ===
    ui.separator()
    ui.header("Response Curve")
    if ui.checkbox("Enable Curve", ts.curve.enable) then
        ts.curve.enable = not ts.curve.enable
        dirty = true
    end
    ui.sameLine(0, 10)
    ui.textColored("(?)", rgbm(0.5, 0.8, 1.0, 1.0))
    if ui.itemHovered() then ui.setTooltip(CURVE_HELP) end

    for i, preset in ipairs(CURVE_PRESETS) do
        if i > 1 then ui.sameLine(0, 6) end
        if ui.button(preset.name) then
            ts.curve.x, ts.curve.y = clampKnee(preset.x, preset.y)
            dirty = true
        end
        if ui.itemHovered() then ui.setTooltip(preset.tip) end
    end

    val, changed = ui.slider("##curve_x", ts.curve.x, 0.05, 0.95, "Knee X (position): %.2f")
    if changed then
        ts.curve.x, ts.curve.y = clampKnee(val, ts.curve.y)
        dirty = true
    end
    if ui.itemHovered() then
        ui.setTooltip("Where the bend happens along the pressure axis.\nHigher = the flat part lasts longer.")
    end

    val, changed = ui.slider("##curve_y", ts.curve.y, 0.05, 0.95, "Knee Y (depth): %.2f")
    if changed then
        ts.curve.x, ts.curve.y = clampKnee(ts.curve.x, val)
        dirty = true
    end
    if ui.itemHovered() then
        ui.setTooltip("How far the knee sits from the straight line.\nBelow it: light pressure is dulled. Above it: sharper.\nLimited so the curve never becomes a dead zone.")
    end

    -- Preview: kurva, titik kontrol (lingkaran kosong), dan posisi trigger sekarang (titik merah)
    local c = ts.curve
    local alpha = c.enable and 1.0 or 0.35
    local plotSize = 160
    local origin = ui.getCursor()
    local function P(px, py)
        return vec2(origin.x + 4 + px * plotSize, origin.y + 4 + (1 - py) * plotSize)
    end
    ui.dummy(vec2(plotSize + 8, plotSize + 8))
    ui.drawRectFilled(P(0, 1), P(1, 0), rgbm(0.05, 0.07, 0.09, 0.85))
    ui.drawRect(P(0, 1), P(1, 0), rgbm(1, 1, 1, 0.25))
    ui.drawLine(P(0, 0), P(1, 1), rgbm(1, 1, 1, 0.35), 1)
    ui.drawLine(P(0, 0), P(c.x, c.y), rgbm(0.3, 0.8, 1.0, 0.25 * alpha), 1)
    ui.drawLine(P(c.x, c.y), P(1, 1), rgbm(0.3, 0.8, 1.0, 0.25 * alpha), 1)
    for i = 0, 40 do
        local t = i / 40
        ui.pathLineTo(P(t, bezier(t, c.x, c.y)))
    end
    ui.pathStroke(rgbm(0.3, 0.8, 1.0, alpha), false, 2.5)

    local liveX = 0.0
    if shared then
        liveX = (currentTriggerTab == "rt") and (shared.s1Gas or 0.0) or (shared.s1Brake or 0.0)
    end
    local liveY = c.enable and bezier(liveX, c.x, c.y) or liveX
    ui.drawCircle(P(c.x, c.y), 5, rgbm(0.3, 0.8, 1.0, alpha), 16, 1.5)
    ui.drawCircleFilled(P(liveX, liveY), 4, rgbm(1.0, 0.35, 0.25, 1.0), 12)

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