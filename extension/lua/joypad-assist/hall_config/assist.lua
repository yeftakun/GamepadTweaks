local config = require('config')
local signal = require('signal')
local vibration = require('vibration')

local timer = 0
local isLoadedLogged = false

local gasProcessor = signal.create()
local brakeProcessor = signal.create()

function script.update(dt)
    local data = ac.getJoypadState()

    if not isLoadedLogged then
        ac.log("HallConfig: Phase 3 (Live UI Config) Loaded!")
        isLoadedLogged = true
    end

    -- Reload config secara periodik (0.5s) agar live tuning dari UI bekerja
    config.reload(dt)

    -- 1. Signal Processing
    data.gas = gasProcessor.process(data.gas, dt)
    data.brake = brakeProcessor.process(data.brake, dt)

    -- 2. Vibration Feedback
    vibration.apply(data)
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
    ac.log("HallConfig: reset() called, state cleared.")
end
