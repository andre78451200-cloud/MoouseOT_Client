--[[
  BTC Bot - Módulo Principal
  
  Bot customizado com interface moderna
  Versão: 1.0.0
]]

BTCBot = BTCBot or {}

-- Status do bot
BTCBot.enabled = false
BTCBot.version = "1.0.0"

-- Evento de execução
BTCBot.executeEvent = nil

-- Módulos carregados
BTCBot.modules = {}

-- Inicializa o BTC Bot (chamado externamente)
function BTCBot.init()
  print("[BTC Bot] Inicializado - v" .. BTCBot.version)
  -- Inicia loop de execucao (sempre roda para recording)
  if not BTCBot.executeEvent then
    BTCBot.executeEvent = scheduleEvent(BTCBot.execute, 100)
  end
end

-- Liga o bot
function BTCBot.enable()
  if BTCBot.enabled then return end
  
  BTCBot.enabled = true
  
  -- Garante que loop esta rodando
  if not BTCBot.executeEvent then
    BTCBot.executeEvent = scheduleEvent(BTCBot.execute, 100)
  end
  
  print("[BTC Bot] Ativado")
end

-- Desliga o bot
function BTCBot.disable()
  if not BTCBot.enabled then return end
  
  BTCBot.enabled = false
  
  -- NAO para o loop - precisa continuar para recording do CaveBot
  
  print("[BTC Bot] Desativado")
end

-- Toggle on/off
function BTCBot.toggle()
  if BTCBot.enabled then
    BTCBot.disable()
  else
    BTCBot.enable()
  end
  return BTCBot.enabled
end

-- Loop principal de execucao
function BTCBot.execute()
  if not g_game.isOnline() then
    -- Agenda proxima execucao mesmo offline (para quando logar)
    BTCBot.executeEvent = scheduleEvent(BTCBot.execute, 100)
    return
  end
  
  -- Recording do CaveBot funciona mesmo com bot OFF
  if BTCCaveBot then
    BTCCaveBot.checkRecording()
  end
  
  -- Se bot desligado, nao executa os modulos
  if not BTCBot.enabled then
    BTCBot.executeEvent = scheduleEvent(BTCBot.execute, 100)
    return
  end
  
  -- Executa modulo de healing
  if BTCHealing then
    BTCHealing.execute()
  end
  
  -- Executa modulo de heal friend (cura em outros jogadores)
  if BTCHealFriend then
    BTCHealFriend.execute()
  end
  
  -- Executa modulo de mana
  if BTCMana then
    BTCMana.execute()
  end
  
  -- Executa modulo de attack
  if BTCAttack then
    BTCAttack.execute()
    -- Atualiza UI de cooldown das spells
    BTCAttack.updateCooldownUI()
  end
  
  -- Executa modulo de targeting
  if BTCTargeting then
    BTCTargeting.execute()
  end
  
  -- Executa modulo de tools (buffs de suporte)
  if BTCTools then
    BTCTools.execute()
  end
  
  -- Executa modulo de equipment (ring/amulet automatico)
  if BTCEquipment then
    BTCEquipment.execute()
  end
  
  -- Executa modulo de cavebot
  if BTCCaveBot then
    BTCCaveBot.execute()
  end
  
  -- Executa modulo de time (uso temporizado de itens)
  if BTCTime then
    BTCTime.execute()
  end
  
  -- Agenda proxima execucao (100ms = 10 vezes por segundo)
  BTCBot.executeEvent = scheduleEvent(BTCBot.execute, 100)
end

-- Retorna status atual
function BTCBot.isEnabled()
  return BTCBot.enabled
end

-- Termina o bot
function BTCBot.terminate()
  BTCBot.disable()
  print("[BTC Bot] Terminado")
end

return BTCBot
