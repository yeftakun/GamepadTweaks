local config = require('config')

local function createProcessor()
    local state = {
        active = false,
        prevSmoothed = 0.0
    }

    local function process(raw, dt)
        local processed = raw

        -- 1. Hysteresis Deadzone Remap
        if config.hysteresisEnable then
            if not state.active and processed > config.hysteresisThresholdUp then 
                state.active = true
            elseif state.active and processed < config.hysteresisThresholdDown then 
                state.active = false 
            end
            
            if not state.active then 
                processed = 0.0 
            else
                processed = (processed - config.hysteresisThresholdDown) / (1.0 - config.hysteresisThresholdDown)
            end
        end

        -- 2. Smoothing (EMA dt-normalized)
        if config.smoothingEnable then
            local factor = 1 - math.exp(-dt / config.smoothingTimeConstant)
            processed = state.prevSmoothed + (processed - state.prevSmoothed) * factor
            state.prevSmoothed = processed
        else
            state.prevSmoothed = processed
        end

        return math.max(0.0, math.min(1.0, processed))
    end

    local function reset()
        state.active = false
        state.prevSmoothed = 0.0
    end

    return {
        process = process,
        reset = reset
    }
end

return {
    create = createProcessor
}
