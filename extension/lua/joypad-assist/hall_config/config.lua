local cfgPath = ac.getFolder(ac.FolderID.ExtCfgUser) .. '/hall_config.ini'

local state = {
    global = {
        nativeVibrationEnable = true
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

local timer = 0.5

local function loadTrigger(cfg, prefix, triggerState)
    triggerState.hysteresisEnable = cfg:get(prefix .. '_HYSTERESIS', 'ENABLE', true)
    triggerState.hysteresisThresholdUp = cfg:get(prefix .. '_HYSTERESIS', 'UP', 0.27)
    triggerState.hysteresisThresholdDown = cfg:get(prefix .. '_HYSTERESIS', 'DOWN', 0.23)
    
    triggerState.smoothingEnable = cfg:get(prefix .. '_SMOOTHING', 'ENABLE', true)
    triggerState.smoothingTimeConstant = cfg:get(prefix .. '_SMOOTHING', 'TIME_CONSTANT', 0.015)
    
    local defaultMotor = (prefix == 'RT') and 1 or 0
    triggerState.vibration.enable = cfg:get(prefix .. '_VIBRATION', 'ENABLE', true)
    triggerState.vibration.motor = cfg:get(prefix .. '_VIBRATION', 'MOTOR', defaultMotor) == 1 and "right" or "left"
    triggerState.vibration.mode = cfg:get(prefix .. '_VIBRATION', 'MODE', 0) == 0 and "proportional" or "static"
    triggerState.vibration.maxVibrationPercent = cfg:get(prefix .. '_VIBRATION', 'MAX', 80)
end

local function reload(dt)
    timer = timer + dt
    if timer >= 0.5 then
        timer = 0
        local cfg = ac.INIConfig.load(cfgPath)
        state.global.nativeVibrationEnable = cfg:get('GLOBAL', 'NATIVE_VIBRATION', true)
        loadTrigger(cfg, 'RT', state.rt)
        loadTrigger(cfg, 'LT', state.lt)
    end
end

return {
    state = state,
    reload = reload
}
