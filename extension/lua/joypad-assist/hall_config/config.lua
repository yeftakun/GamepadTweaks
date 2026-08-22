return {
    -- Hysteresis settings
    hysteresisEnable = true,
    hysteresisThresholdUp = 0.27,
    hysteresisThresholdDown = 0.23,

    -- Smoothing settings
    smoothingEnable = true,
    smoothingTimeConstant = 0.015, -- dalam detik

    -- Vibration settings (Fase 2)
    vibrationRT = {
        enable = true,
        motor = "right", -- "left" (motor besar/low freq) atau "right" (motor kecil/high freq)
        mode = "proportional", -- "proportional" atau "static"
        maxVibrationPercent = 80 -- 0 sampai 100
    },
    
    vibrationLT = {
        enable = true,
        motor = "left",
        mode = "proportional", 
        maxVibrationPercent = 80
    }
}
