local cfgPath = ac.getFolder(ac.FolderID.ExtCfgUser) .. '/gamepad_tweaks.ini'

-- Batas aman titik kontrol curve: kemiringan awal dan akhir kurva minimal MIN_SLOPE,
-- supaya area "ditahan" tidak berubah jadi deadzone kedua.
local MIN_SLOPE = 0.2

local function clampKnee(x, y)
    x = math.max(0.05, math.min(0.95, x))
    local yMin = math.max(0.05, MIN_SLOPE * x)
    local yMax = math.min(0.95, 1.0 - MIN_SLOPE * (1.0 - x))
    y = math.max(yMin, math.min(yMax, y))
    return x, y
end

local state = {
    global = {
        nativeVibrationMultiplier = 1.0
    },
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

local timer = 0.5

local function loadTrigger(cfg, prefix, triggerState)
    triggerState.hysteresisEnable = cfg:get(prefix .. '_HYSTERESIS', 'ENABLE', true)
    triggerState.hysteresisThresholdUp = cfg:get(prefix .. '_HYSTERESIS', 'UP', 0.27)
    triggerState.hysteresisThresholdDown = cfg:get(prefix .. '_HYSTERESIS', 'DOWN', 0.23)
    
    triggerState.smoothingEnable = cfg:get(prefix .. '_SMOOTHING', 'ENABLE', true)
    triggerState.smoothingTimeConstant = cfg:get(prefix .. '_SMOOTHING', 'TIME_CONSTANT', 0.015)
    
    triggerState.curve.enable = cfg:get(prefix .. '_CURVE', 'ENABLE', true)
    triggerState.curve.x, triggerState.curve.y = clampKnee(
        cfg:get(prefix .. '_CURVE', 'X', 0.5),
        cfg:get(prefix .. '_CURVE', 'Y', 0.5))

    local defaultMotor = (prefix == 'RT') and 1 or 0
    triggerState.vibration.enable = cfg:get(prefix .. '_VIBRATION', 'ENABLE', true)
    triggerState.vibration.motor = cfg:get(prefix .. '_VIBRATION', 'MOTOR', defaultMotor)
    triggerState.vibration.mode = cfg:get(prefix .. '_VIBRATION', 'MODE', 0)
    triggerState.vibration.maxVibrationPercent = cfg:get(prefix .. '_VIBRATION', 'MAX', 80)
end

local function reload(dt)
    timer = timer + dt
    if timer >= 0.5 then
        timer = 0
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
        
        loadTrigger(cfg, 'RT', state.rt)
        loadTrigger(cfg, 'LT', state.lt)
    end
end

return {
    state = state,
    reload = reload,
    clampKnee = clampKnee
}