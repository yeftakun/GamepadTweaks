local config = require('config')

local function getMotorValue(processedOutput, axisConfig)
    if not axisConfig.enable then return 0.0 end
    
    local maxVib = axisConfig.maxVibrationPercent / 100.0
    
    -- Mode 1 adalah static (bukan string lagi)
    if axisConfig.mode == 1 then
        -- Sedikit threshold (0.01) agar tidak bergetar saat noise/idle
        return (processedOutput > 0.01) and maxVib or 0.0
    else
        -- Proportional (mode 0)
        return processedOutput * maxVib
    end
end

local function apply(data)
    local cfg = config.state
    
    -- AMBIL getaran asli dari game (Kerbs, ABS, Tabrakan) agar tidak hilang
    local leftMotor = data.vibrationLeft or 0.0
    local rightMotor = data.vibrationRight or 0.0

    -- 1. Evaluasi kebutuhan motor untuk RT (Gas)
    local rtValue = getMotorValue(data.gas, cfg.rt.vibration)
    if cfg.rt.vibration.motor == 0 then
        leftMotor = math.max(leftMotor, rtValue)
    else
        rightMotor = math.max(rightMotor, rtValue)
    end

    -- 2. Evaluasi kebutuhan motor untuk LT (Brake)
    local ltValue = getMotorValue(data.brake, cfg.lt.vibration)
    if cfg.lt.vibration.motor == 0 then
        leftMotor = math.max(leftMotor, ltValue)
    else
        rightMotor = math.max(rightMotor, ltValue)
    end

    -- Terapkan hasil ke data object dengan batas maksimal 1.0
    data.vibrationLeft = math.min(1.0, leftMotor)
    data.vibrationRight = math.min(1.0, rightMotor)
end

local function reset(data)
    -- Jangan reset getaran asli game, biarkan engine yang mengurusnya
end

return {
    apply = apply,
    reset = reset
}
