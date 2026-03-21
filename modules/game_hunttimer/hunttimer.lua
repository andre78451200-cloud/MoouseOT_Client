-- ============================================================
-- Modulo OTC: Timer de Hunt Exclusiva
-- Exibe um contador regressivo verde no topo da tela
-- quando o jogador esta dentro de uma sala de hunt exclusiva.
-- Comunicacao com servidor via extended opcode 221.
-- ============================================================

HUNT_OPCODE = 221

local huntTimerWidget = nil
local countdownEvent = nil
local secondsLeft = 0
local currentRoom = 0

function init()
    g_ui.importStyle('hunttimer')

    ProtocolGame.registerExtendedOpcode(HUNT_OPCODE, onHuntTimerOpcode)

    connect(g_game, {
        onGameEnd = onGameEnd
    })
end

function terminate()
    disconnect(g_game, {
        onGameEnd = onGameEnd
    })

    ProtocolGame.unregisterExtendedOpcode(HUNT_OPCODE)

    stopCountdown()
    destroyWidget()
end

function onGameEnd()
    stopCountdown()
    destroyWidget()
end

-- Callback chamado quando servidor envia opcode 220
function onHuntTimerOpcode(protocol, opcode, buffer)
    -- Formato do buffer: "acao|sala|tempoSegundos"
    -- start|3|3600  -> iniciar timer da sala 3 com 3600 segundos
    -- stop|0|0      -> parar/esconder timer
    local parts = buffer:split('|')
    if not parts or #parts < 3 then
        return
    end

    local action = parts[1]
    local room = tonumber(parts[2]) or 0
    local time = tonumber(parts[3]) or 0

    if action == 'start' and time > 0 then
        currentRoom = room
        secondsLeft = time
        startCountdown()
    elseif action == 'stop' then
        stopCountdown()
        destroyWidget()
    end
end

function createWidget()
    if huntTimerWidget then
        return
    end

    local mapPanel = modules.game_interface.getMapPanel()
    if not mapPanel then
        return
    end

    huntTimerWidget = g_ui.createWidget('HuntTimerLabel', mapPanel)
    huntTimerWidget:setVisible(true)
end

function destroyWidget()
    if huntTimerWidget then
        huntTimerWidget:destroy()
        huntTimerWidget = nil
    end
    secondsLeft = 0
    currentRoom = 0
end

function startCountdown()
    stopCountdown()
    createWidget()
    updateDisplay()
    scheduleCountdown()
end

function stopCountdown()
    if countdownEvent then
        removeEvent(countdownEvent)
        countdownEvent = nil
    end
end

function scheduleCountdown()
    countdownEvent = scheduleEvent(function()
        countdownEvent = nil
        if secondsLeft > 0 then
            secondsLeft = secondsLeft - 1
            updateDisplay()
            if secondsLeft > 0 then
                scheduleCountdown()
            else
                destroyWidget()
            end
        end
    end, 1000)
end

function updateDisplay()
    if not huntTimerWidget then
        return
    end

    local minutes = math.floor(secondsLeft / 60)
    local secs = secondsLeft % 60
    local text = string.format('Hunt Exclusiva (Sala %d) - %02d:%02d', currentRoom, minutes, secs)
    huntTimerWidget:setText(text)

    -- Mudar cor conforme tempo restante
    if secondsLeft <= 60 then
        -- Vermelho nos ultimos 60 segundos
        huntTimerWidget:setColor('#FF3333')
    elseif secondsLeft <= 300 then
        -- Amarelo nos ultimos 5 minutos
        huntTimerWidget:setColor('#FFFF00')
    else
        -- Verde normal
        huntTimerWidget:setColor('#00FF00')
    end
end
