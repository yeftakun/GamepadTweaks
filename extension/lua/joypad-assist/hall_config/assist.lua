local signal = require('signal')

local timer = 0
local isLoadedLogged = false

-- Buat instance processor terpisah untuk masing-masing axis
local gasProcessor = signal.create()
local brakeProcessor = signal.create()

function script.update(dt)
    local data = ac.getJoypadState()

    if not isLoadedLogged then
        ac.log("HallConfig: Phase 1 (RT & LT Processing) Loaded!")
        isLoadedLogged = true
    end

    local rawGas = data.gas
    local rawBrake = data.brake

    -- Terapkan signal processing ke Right Trigger (Gas) dan Left Trigger (Brake)
    data.gas = gasProcessor.process(data.gas, dt)
    data.brake = brakeProcessor.process(data.brake, dt)

    timer = timer + dt
    if timer >= 1.0 then
        timer = 0
        ac.log(string.format(
            "HallConfig | RT: %.3f->%.3f | LT: %.3f->%.3f", 
            rawGas, data.gas, 
            rawBrake, data.brake
        ))
    end
end

function script.reset()
    timer = 0
    isLoadedLogged = false
    gasProcessor.reset()
    brakeProcessor.reset()
    ac.log("HallConfig: reset() called, state cleared.")
end
