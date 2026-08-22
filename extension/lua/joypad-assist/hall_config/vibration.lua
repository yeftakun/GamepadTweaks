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

local function getNativeVibration(data)
    -- Menghitung getaran native persis seperti skrip default CSP (race/drift.lua)
    local slipL = math.max(0, data.ndSlipL or 0)
    local slipR = math.max(0, data.ndSlipR or 0)
    local rumbleEffects = data.rumbleEffects or 1.0
    
    local slipForceL = ((math.ceil(slipL * 10) ^ 0.3) - 1) * ((1 + slipL) ^ 0.3) * rumbleEffects * 0.01
    local slipForceR = ((math.ceil(slipR * 10) ^ 0.3) - 1) * ((1 + slipR) ^ 0.3) * rumbleEffects * 0.01

    -- Hindari hasil NaN jika perhitungan ^0.3 error
    if slipForceL ~= slipForceL or slipForceL < 0 then slipForceL = 0 end
    if slipForceR ~= slipForceR or slipForceR < 0 then slipForceR = 0 end

    -- Tambahkan getaran jalanan (kerbs/surface)
    local speedFactor = math.max(0, math.min(1.0, (data.speedKmh or 0) / 100))
    local surfL = speedFactor * (data.surfaceVibrationGainLeft or 0) / 20
    local surfR = speedFactor * (data.surfaceVibrationGainRight or 0) / 20

    return slipForceL + surfL, slipForceR + surfR
end

local function apply(data)
    local cfg = config.state
    
    local nativeLeft, nativeRight = 0.0, 0.0
    
    if cfg.global.nativeVibrationEnable then
        nativeLeft, nativeRight = getNativeVibration(data)
    end
    
    local hallLeft = 0.0
    local hallRight = 0.0

    -- 1. Evaluasi kebutuhan motor untuk RT (Gas)
    local rtValue = getMotorValue(data.gas, cfg.rt.vibration)
    if cfg.rt.vibration.motor == 0 then
        hallLeft = math.max(hallLeft, rtValue)
    else
        hallRight = math.max(hallRight, rtValue)
    end

    -- 2. Evaluasi kebutuhan motor untuk LT (Brake)
    local ltValue = getMotorValue(data.brake, cfg.lt.vibration)
    if cfg.lt.vibration.motor == 0 then
        hallLeft = math.max(hallLeft, ltValue)
    else
        hallRight = math.max(hallRight, ltValue)
    end

    -- Terapkan secara aditif (+), dibatasi maksimal 100% (1.0)
    data.vibrationLeft = math.max(0.0, math.min(1.0, nativeLeft + hallLeft))
    data.vibrationRight = math.max(0.0, math.min(1.0, nativeRight + hallRight))
end

local function reset(data)
    -- Jangan reset getaran asli game, biarkan engine yang mengurusnya
end

return {
    apply = apply,
    reset = reset
}
