g_settings = makesingleton(g_configs.getSettings())

-- Auto-save com debounce: salva configs no disco 1s após a última modificação.
-- Previne perda de configurações caso o cliente feche inesperadamente (crash, alt+f4, etc).
do
    local _pendingSaveEvent = nil
    local _originalSet = g_settings.set

    g_settings.set = function(key, value)
        _originalSet(key, value)

        if _pendingSaveEvent then
            removeEvent(_pendingSaveEvent)
            _pendingSaveEvent = nil
        end

        _pendingSaveEvent = scheduleEvent(function()
            g_settings.save()
            _pendingSaveEvent = nil
        end, 1000)
    end
end
