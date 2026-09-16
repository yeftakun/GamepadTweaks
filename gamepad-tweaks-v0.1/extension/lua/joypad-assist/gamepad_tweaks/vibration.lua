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

    local totalL, totalR = 0.0, 0.0

    -- Helper functions for motor routing
    local function addSideVib(vL, vR, setting)
        local effL = vL * setting.mult
        local effR = vR * setting.mult
        if setting.motor == 0 then -- Left (Low)
            totalL = totalL + math.max(effL, effR)
        elseif setting.motor == 1 then -- Right (Hi)
            totalR = totalR + math.max(effL, effR)
        else -- Both
            totalL = totalL + effL
            totalR = totalR + effR
        end
    end

    local function addGlobalVib(vib, setting)
        local effVal = vib * setting.mult
        if setting.motor == 0 then -- Left
            totalL = totalL + effVal
        elseif setting.motor == 1 then -- Right
            totalR = totalR + effVal
        else -- Both
            totalL = totalL + effVal
            totalR = totalR + effVal
        end
    end

    -- 1. SLIP (Ban Selip)
    local slipL = math.max(0, data.ndSlipL or 0)
    local slipR = math.max(0, data.ndSlipR or 0)
    local rumbleEffects = data.rumbleEffects or 1.0
    
    local slipForceL = ((math.ceil(slipL * 10) ^ 0.3) - 1) * ((1 + slipL) ^ 0.3) * rumbleEffects * 0.01
    local slipForceR = ((math.ceil(slipR * 10) ^ 0.3) - 1) * ((1 + slipR) ^ 0.3) * rumbleEffects * 0.01
    if slipForceL ~= slipForceL or slipForceL < 0 then slipForceL = 0 end
    if slipForceR ~= slipForceR or slipForceR < 0 then slipForceR = 0 end
    addSideVib(slipForceL, slipForceR, eff.slip)

    -- 2. KERBS / ROAD (Permukaan Jalan)
    local speedFactor = math.max(0, math.min(1.0, (data.speedKmh or 0) / 100))
    local surfL = speedFactor * (data.surfaceVibrationGainLeft or 0) / 20
    local surfR = speedFactor * (data.surfaceVibrationGainRight or 0) / 20
    addSideVib(surfL, surfR, eff.kerb)

    -- 3. ABS (Rem Mengunci)
    local absVib = 0.0
    if car and car.absInAction then
        absVib = 0.6
    end
    addGlobalVib(absVib, eff.abs)

    -- 4. COLLISION (Tabrakan)
    local colVib = 0.0
    if car and car.collisionDepth and car.collisionDepth > 0.01 then
        colVib = 1.0
    end
    addGlobalVib(colVib, eff.collision)

    -- 5. G-FORCE (Guncangan/Suspensi mentok)
    local gVib = 0.0
    if data.gForces then
        local gLoad = math.abs(data.gForces.y) + math.abs(data.gForces.x)
        if gLoad > 1.5 then
            gVib = (gLoad - 1.5) * 0.1
        end
    end
    addGlobalVib(gVib, eff.gforce)

    -- 6. OFF-ROAD (Keluar Trek / Rumput / Gravel)
    local offroadVib = 0.0
    if car and car.wheelsOutside and car.wheelsOutside > 1 then
        offroadVib = speedFactor * 0.3
    end
    addGlobalVib(offroadVib, eff.offroad)

    -- 7. ENGINE RPM
    local engineVib = 0.0
    if car and car.rpmLimiter and car.rpmLimiter > 0 then
        local rpmRatio = car.rpm / car.rpmLimiter
        if rpmRatio > 0.85 then
            engineVib = (rpmRatio - 0.85) * 1.5
        end
    end
    addGlobalVib(engineVib, eff.engine)

    -- 8. GEARSHIFT (Sentakan Gigi)
    local gearVib = 0.0
    if car then
        if localState.lastGear ~= car.gear then
            localState.gearJolt = 0.8
            localState.lastGear = car.gear
        end
        if localState.gearJolt > 0 then
            gearVib = localState.gearJolt
            localState.gearJolt = localState.gearJolt - 0.05
        end
    end
    addGlobalVib(gearVib, eff.gearshift)

    return totalL * multiplier, totalR * multiplier
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
