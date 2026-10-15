local config = require('config')
local signal = require('signal')
local vibration = require('vibration')

local timer = 0
local isLoadedLogged = false

-- Shared memory untuk mengirim data telemetri ke UI
local shared = ac.connect({
    key = ac.StructItem.key('GamepadTweaks_Telemetry_v2'),
    rawGas = ac.StructItem.float(),
    processedGas = ac.StructItem.float(),
    rawBrake = ac.StructItem.float(),
    processedBrake = ac.StructItem.float(),
    s1Gas = ac.StructItem.float(),   -- output hysteresis (input curve), untuk titik live di preview
    s1Brake = ac.StructItem.float()
}, true)

local gasProcessor = signal.create('rt')
local brakeProcessor = signal.create('lt')

function script.update(dt)
    local data = ac.getJoypadState()

    if not isLoadedLogged then
        ac.log("GamepadTweaks: Phase 3 (Live UI Config) Loaded!")
        isLoadedLogged = true
    end

    -- Reload config secara periodik (0.5s) agar live tuning dari UI bekerja
    config.reload(dt)

    -- Simpan nilai raw sebelum di-process
    local rawGas = data.gas
    local rawBrake = data.brake

    -- 1. Signal Processing
    local gasS1, brakeS1
    data.gas, gasS1 = gasProcessor.process(data.gas, dt)
    data.brake, brakeS1 = brakeProcessor.process(data.brake, dt)

    -- 2. Vibration Feedback
    vibration.apply(data)
    
    -- 3. Telemetry for UI (Shared memory)
    if shared then
        shared.rawGas = rawGas
        shared.processedGas = data.gas
        shared.rawBrake = rawBrake
        shared.processedBrake = data.brake
        shared.s1Gas = gasS1
        shared.s1Brake = brakeS1
    end
end

function script.reset()
    timer = 0
    isLoadedLogged = false
    gasProcessor.reset()
    brakeProcessor.reset()
    local data = ac.getJoypadState()
    if data then
        vibration.reset(data)
    end
    ac.log("GamepadTweaks: reset() called, state cleared.")
end