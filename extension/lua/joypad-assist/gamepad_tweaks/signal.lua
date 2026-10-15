local config = require('config')

-- Response curve: quadratic Bezier dari (0,0) ke (1,1) dengan satu titik kontrol (cx, cy).
-- Kemiringan awal = cy/cx, kemiringan akhir = (1-cy)/(1-cx). (0.5, 0.5) = linear.
-- Memakai bentuk stabil t = x / (cx + sqrt(cx^2 + (1-2cx)*x)), aman juga saat cx = 0.5.
local function curve(x, cx, cy)
    if x <= 0.0 then return 0.0 end
    if x >= 1.0 then return 1.0 end
    local t = x / (cx + math.sqrt(cx * cx + (1.0 - 2.0 * cx) * x))
    return 2.0 * (1.0 - t) * t * cy + t * t
end

local function createProcessor(triggerId)
    local state = {
        active = false,
        prevSmoothed = 0.0
    }

    -- Mengembalikan: output akhir (S2 setelah smoothing), dan S1 (output hysteresis, input curve)
    local function process(raw, dt)
        local cfg = config.state[triggerId] -- state terbaru ("rt" atau "lt")

        -- S0: sinyal mentah
        local s0 = raw

        -- 1. Hysteresis Deadzone Remap  (S0 -> S1)
        local s1 = s0
        if cfg.hysteresisEnable then
            if not state.active and s1 > cfg.hysteresisThresholdUp then
                state.active = true
            elseif state.active and s1 < cfg.hysteresisThresholdDown then
                state.active = false
            end

            if not state.active then
                s1 = 0.0
            else
                local denom = 1.0 - cfg.hysteresisThresholdDown
                if denom < 0.001 then denom = 0.001 end
                s1 = (s1 - cfg.hysteresisThresholdDown) / denom
            end
        end
        s1 = math.max(0.0, math.min(1.0, s1))

        -- 2. Response Curve  (S1 -> S2)
        local s2 = s1
        if cfg.curve.enable then
            s2 = curve(s1, cfg.curve.x, cfg.curve.y)
        end

        -- 3. Smoothing (EMA dt-normalized), diterapkan pada S2
        local out = s2
        if cfg.smoothingEnable then
            -- Mencegah pembagian dengan nol jika time constant diatur ke 0
            if cfg.smoothingTimeConstant > 0.001 then
                local factor = 1 - math.exp(-dt / cfg.smoothingTimeConstant)
                out = state.prevSmoothed + (out - state.prevSmoothed) * factor
            end
            state.prevSmoothed = out
        else
            state.prevSmoothed = out
        end

        return math.max(0.0, math.min(1.0, out)), s1
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
    create = createProcessor,
    curve = curve
}