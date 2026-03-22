--[[
  MTC Bot - Módulo Principal
  
  Bot customizado com interface moderna
  Versão: 1.0.0
]]

MTCBot = MTCBot or {}

-- Status do bot
MTCBot.enabled = false
MTCBot.version = "1.0.0"

-- Evento de execução
MTCBot.executeEvent = nil

-- Módulos carregados
MTCBot.modules = {}

-- Inicializa o MTC Bot (chamado externamente)
function MTCBot.init()
  print("[MTC Bot] Inicializado - v" .. MTCBot.version)
  -- Inicia loop de execucao (sempre roda para recording)
  if not MTCBot.executeEvent then
    MTCBot.executeEvent = scheduleEvent(MTCBot.execute, 100)
  end
end

-- Liga o bot
function MTCBot.enable()
  if MTCBot.enabled then return end
  
  MTCBot.enabled = true
  
  -- Garante que loop esta rodando
  if not MTCBot.executeEvent then
    MTCBot.executeEvent = scheduleEvent(MTCBot.execute, 100)
  end
  
  print("[MTC Bot] Ativado")
end

-- Desliga o bot
function MTCBot.disable()
  if not MTCBot.enabled then return end
  
  MTCBot.enabled = false
  
  -- NAO para o loop - precisa continuar para recording do CaveBot
  
  print("[MTC Bot] Desativado")
end

-- Toggle on/off
function MTCBot.toggle()
  if MTCBot.enabled then
    MTCBot.disable()
  else
    MTCBot.enable()
  end
  return MTCBot.enabled
end

-- Loop principal de execucao
function MTCBot.execute()
  if not g_game.isOnline() then
    -- Agenda proxima execucao mesmo offline (para quando logar)
    MTCBot.executeEvent = scheduleEvent(MTCBot.execute, 100)
    return
  end
  
  -- Recording do CaveBot funciona mesmo com bot OFF
  if MTCCaveBot then
    MTCCaveBot.checkRecording()
  end
  
  -- Se bot desligado, nao executa os modulos
  if not MTCBot.enabled then
    MTCBot.executeEvent = scheduleEvent(MTCBot.execute, 100)
    return
  end
  
  -- Executa modulo de healing
  if MTCHealing then
    MTCHealing.execute()
  end
  
  -- Executa modulo de heal friend (cura em outros jogadores)
  if MTCHealFriend then
    MTCHealFriend.execute()
  end
  
  -- Executa modulo de mana
  if MTCMana then
    MTCMana.execute()
  end
  
  -- Executa modulo de attack
  if MTCAttack then
    MTCAttack.execute()
    -- Atualiza UI de cooldown das spells
    MTCAttack.updateCooldownUI()
  end
  
  -- Executa modulo de targeting
  if MTCTargeting then
    MTCTargeting.execute()
  end
  
  -- Executa modulo de tools (buffs de suporte)
  if MTCTools then
    MTCTools.execute()
  end
  
  -- Executa modulo de equipment (ring/amulet automatico)
  if MTCEquipment then
    MTCEquipment.execute()
  end
  
  -- Executa modulo de cavebot
  if MTCCaveBot then
    MTCCaveBot.execute()
  end
  
  -- Executa modulo de time (uso temporizado de itens)
  if MTCTime then
    MTCTime.execute()
  end
  
  -- Agenda proxima execucao (100ms = 10 vezes por segundo)
  MTCBot.executeEvent = scheduleEvent(MTCBot.execute, 100)
end

-- Retorna status atual
function MTCBot.isEnabled()
  return MTCBot.enabled
end

-- Termina o bot
function MTCBot.terminate()
  MTCBot.disable()
  print("[MTC Bot] Terminado")
end

return MTCBot
