local cfgPath = ac.getFolder(ac.FolderID.ExtCfgUser) .. '/hall_config.ini'

local state = {
    hysteresisEnable = true,
    hysteresisThresholdUp = 0.27,
    hysteresisThresholdDown = 0.23,
    
    smoothingEnable = true,
    smoothingTimeConstant = 0.015,
    
    vibrationRT = { enable = true, motor = "right", mode = "proportional", maxVibrationPercent = 80 },
    vibrationLT = { enable = true, motor = "left", mode = "proportional", maxVibrationPercent = 80 }
}

local timer = 0.5 -- Langsung reload di frame pertama

local function reload(dt)
    timer = timer + dt
    -- Polling file INI tiap 0.5 detik agar UI perubahan langsung terasa
    if timer >= 0.5 then
        timer = 0
        local cfg = ac.INIConfig.load(cfgPath)
        
        state.hysteresisEnable = cfg:get('HYSTERESIS', 'ENABLE', true)
        state.hysteresisThresholdUp = cfg:get('HYSTERESIS', 'UP', 0.27)
        state.hysteresisThresholdDown = cfg:get('HYSTERESIS', 'DOWN', 0.23)
        
        state.smoothingEnable = cfg:get('SMOOTHING', 'ENABLE', true)
        state.smoothingTimeConstant = cfg:get('SMOOTHING', 'TIME_CONSTANT', 0.015)
        
        state.vibrationRT.enable = cfg:get('VIBRATION_RT', 'ENABLE', true)
        state.vibrationRT.motor = cfg:get('VIBRATION_RT', 'MOTOR', 1) == 1 and "right" or "left"
        state.vibrationRT.mode = cfg:get('VIBRATION_RT', 'MODE', 0) == 0 and "proportional" or "static"
        state.vibrationRT.maxVibrationPercent = cfg:get('VIBRATION_RT', 'MAX', 80)

        state.vibrationLT.enable = cfg:get('VIBRATION_LT', 'ENABLE', true)
        state.vibrationLT.motor = cfg:get('VIBRATION_LT', 'MOTOR', 0) == 1 and "right" or "left"
        state.vibrationLT.mode = cfg:get('VIBRATION_LT', 'MODE', 0) == 0 and "proportional" or "static"
        state.vibrationLT.maxVibrationPercent = cfg:get('VIBRATION_LT', 'MAX', 80)
    end
end

return {
    state = state,
    reload = reload
}
