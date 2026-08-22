local config = require('config')

local function createProcessor(triggerId)
    local state = {
        active = false,
        prevSmoothed = 0.0
    }

    local function process(raw, dt)
        local processed = raw
        local cfg = config.state[triggerId] -- Ambil state terbaru dari config ("rt" atau "lt")

        -- 1. Hysteresis Deadzone Remap
        if cfg.hysteresisEnable then
            if not state.active and processed > cfg.hysteresisThresholdUp then 
                state.active = true
            elseif state.active and processed < cfg.hysteresisThresholdDown then 
                state.active = false 
            end
            
            if not state.active then 
                processed = 0.0 
            else
                local denom = 1.0 - cfg.hysteresisThresholdDown
                if denom < 0.001 then denom = 0.001 end
                processed = (processed - cfg.hysteresisThresholdDown) / denom
            end
        end

        -- 2. Smoothing (EMA dt-normalized)
        if cfg.smoothingEnable then
            -- Mencegah pembagian dengan nol jika time constant diatur ke 0
            if cfg.smoothingTimeConstant > 0.001 then
                local factor = 1 - math.exp(-dt / cfg.smoothingTimeConstant)
                processed = state.prevSmoothed + (processed - state.prevSmoothed) * factor
            end
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
