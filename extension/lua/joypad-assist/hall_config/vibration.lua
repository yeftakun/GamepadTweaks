local config = require('config')

local function getMotorValue(processedOutput, axisConfig)
    if not axisConfig.enable then return 0.0 end
    
    local maxVib = axisConfig.maxVibrationPercent / 100.0
    
    if axisConfig.mode == "static" then
        -- Sedikit threshold (0.01) agar tidak bergetar saat noise/idle
        return (processedOutput > 0.01) and maxVib or 0.0
    else
        -- Proportional
        return processedOutput * maxVib
    end
end

local function apply(data)
    local cfg = config.state
    local leftMotor = 0.0
    local rightMotor = 0.0

    -- 1. Evaluasi kebutuhan motor untuk RT (Gas)
    local rtValue = getMotorValue(data.gas, cfg.vibrationRT)
    if cfg.vibrationRT.motor == "left" then
        leftMotor = math.max(leftMotor, rtValue)
    else
        rightMotor = math.max(rightMotor, rtValue)
    end

    -- 2. Evaluasi kebutuhan motor untuk LT (Brake)
    local ltValue = getMotorValue(data.brake, cfg.vibrationLT)
    if cfg.vibrationLT.motor == "left" then
        leftMotor = math.max(leftMotor, ltValue)
    else
        rightMotor = math.max(rightMotor, ltValue)
    end

    -- Terapkan hasil ke data object
    data.vibrationLeft = leftMotor
    data.vibrationRight = rightMotor
end

local function reset(data)
    data.vibrationLeft = 0.0
    data.vibrationRight = 0.0
end

return {
    apply = apply,
    reset = reset
}
