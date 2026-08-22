local signal = require('signal')
local vibration = require('vibration')

local timer = 0
local isLoadedLogged = false

-- Buat instance processor terpisah untuk masing-masing axis
local gasProcessor = signal.create()
local brakeProcessor = signal.create()

function script.update(dt)
    local data = ac.getJoypadState()

    if not isLoadedLogged then
        ac.log("HallConfig: Phase 2 (RT & LT + Vibration) Loaded!")
        isLoadedLogged = true
    end

    local rawGas = data.gas
    local rawBrake = data.brake

    -- 1. Signal Processing
    data.gas = gasProcessor.process(data.gas, dt)
    data.brake = brakeProcessor.process(data.brake, dt)

    -- 2. Vibration Feedback (Menghitung & mengaplikasikan rumble)
    vibration.apply(data)

    -- Logging tiap 1 detik
    timer = timer + dt
    if timer >= 1.0 then
        timer = 0
        ac.log(string.format(
            "HallConfig | Gas: %.2f->%.2f | Brk: %.2f->%.2f | VibL: %.2f | VibR: %.2f", 
            rawGas, data.gas, 
            rawBrake, data.brake,
            data.vibrationLeft, data.vibrationRight
        ))
    end
end

function script.reset()
    timer = 0
    isLoadedLogged = false
    gasProcessor.reset()
    brakeProcessor.reset()
    -- reset vibration state (optional, because data is re-initialized by AC, 
    -- but good practice if needed)
    local data = ac.getJoypadState()
    if data then
        vibration.reset(data)
    end
    ac.log("HallConfig: reset() called, state cleared.")
end
