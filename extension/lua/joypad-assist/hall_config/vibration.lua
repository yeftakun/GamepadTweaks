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

local localState = {
    lastGear = 0,
    gearJolt = 0.0
}

local function getNativeVibration(data, multiplier)
    if multiplier <= 0.0 then return 0.0, 0.0 end
    
    local eff = config.state.effects
    local car = ac.getCar(0)

    -- 1. SLIP (Ban Selip)
    local slipL = math.max(0, data.ndSlipL or 0)
    local slipR = math.max(0, data.ndSlipR or 0)
    local rumbleEffects = data.rumbleEffects or 1.0
    
    local slipForceL = ((math.ceil(slipL * 10) ^ 0.3) - 1) * ((1 + slipL) ^ 0.3) * rumbleEffects * 0.01 * eff.slip
    local slipForceR = ((math.ceil(slipR * 10) ^ 0.3) - 1) * ((1 + slipR) ^ 0.3) * rumbleEffects * 0.01 * eff.slip
    if slipForceL ~= slipForceL or slipForceL < 0 then slipForceL = 0 end
    if slipForceR ~= slipForceR or slipForceR < 0 then slipForceR = 0 end

    -- 2. KERBS / ROAD (Permukaan Jalan)
    local speedFactor = math.max(0, math.min(1.0, (data.speedKmh or 0) / 100))
    local surfL = speedFactor * (data.surfaceVibrationGainLeft or 0) / 20 * eff.kerb
    local surfR = speedFactor * (data.surfaceVibrationGainRight or 0) / 20 * eff.kerb

    -- 3. ABS (Rem Mengunci)
    local absVib = 0.0
    if car and car.absInAction then
        absVib = 0.6 * eff.abs
    end

    -- 4. COLLISION (Tabrakan)
    local colVib = 0.0
    if car and car.collisionDepth and car.collisionDepth > 0.01 then
        colVib = 1.0 * eff.collision
    end

    -- 5. G-FORCE (Guncangan/Suspensi mentok)
    local gVib = 0.0
    if data.gForces then
        local gLoad = math.abs(data.gForces.y) + math.abs(data.gForces.x)
        if gLoad > 1.5 then
            gVib = (gLoad - 1.5) * 0.1 * eff.gforce
        end
    end

    -- 6. OFF-ROAD (Keluar Trek / Rumput / Gravel)
    local offroadVib = 0.0
    if car and car.wheelsOutside and car.wheelsOutside > 1 then
        -- Jika lebih dari 1 roda keluar trek, tambah getaran ekstra
        offroadVib = speedFactor * 0.3 * eff.offroad
    end

    -- 7. ENGINE RPM
    local engineVib = 0.0
    if car and car.rpmLimiter and car.rpmLimiter > 0 then
        local rpmRatio = car.rpm / car.rpmLimiter
        if rpmRatio > 0.85 then -- Mendekati redline
            engineVib = (rpmRatio - 0.85) * 1.5 * eff.engine
        end
    end

    -- 8. GEARSHIFT (Sentakan Gigi)
    local gearVib = 0.0
    if car then
        if localState.lastGear ~= car.gear then
            localState.gearJolt = 0.8 -- Spike getaran 80%
            localState.lastGear = car.gear
        end
        if localState.gearJolt > 0 then
            gearVib = localState.gearJolt * eff.gearshift
            localState.gearJolt = localState.gearJolt - 0.05 -- Pelan-pelan mereda
        end
    end

    local totalL = (slipForceL + surfL + absVib + colVib + gVib + offroadVib + engineVib + gearVib) * multiplier
    local totalR = (slipForceR + surfR + absVib + colVib + gVib + offroadVib + engineVib + gearVib) * multiplier

    return totalL, totalR
end

local function apply(data)
    local cfg = config.state
    
    local nativeLeft, nativeRight = getNativeVibration(data, cfg.global.nativeVibrationMultiplier)
    
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
