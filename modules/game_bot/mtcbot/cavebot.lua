--[[
  MTC Bot - CaveBot
  
  Sistema de waypoints automatico
  - Andar ate posicao (goto)
  - Usar objetos (escadas, buracos, portas)
  - Labels para navegacao
  - Pathfinding inteligente
]]

MTCCaveBot = MTCCaveBot or {}

-- Tipos de waypoints
MTCCaveBot.WaypointTypes = {
  WALK = "walk",       -- Andar ate posicao
  USE = "use",         -- Usar objeto na posicao (escada, buraco, lever)
  USEWITH = "usewith", -- Usar item em objeto
  LABEL = "label",     -- Marcador
  STAND = "stand",     -- Ficar parado na posicao
  ROPE = "rope",       -- Usar rope spot
  SHOVEL = "shovel",   -- Usar shovel em buraco
  STAIRS = "stairs",   -- Andar diretamente na escada (pisar em cima)
}

-- Configuracao padrao
MTCCaveBot.defaultConfig = {
  enabled = false,
  walkDelay = 100,
  waypoints = {},
  currentIndex = 1,
  loopEnabled = true,
  minMonstersToStop = 1,  -- Quantidade minima de monstros para pausar e atacar (0 = nunca para)
}

-- Variaveis de controle
MTCCaveBot.config = nil
MTCCaveBot.isWalking = false
MTCCaveBot.lastWalkTime = 0
MTCCaveBot.walkCooldown = 200
MTCCaveBot.retryCount = 0
MTCCaveBot.maxRetries = 10
MTCCaveBot.stuckCount = 0      -- Contador de vezes que ficou preso
MTCCaveBot.maxStuckCount = 30  -- Apos 30 falhas (3 segundos), volta ao waypoint 1
MTCCaveBot.scrollOffset = 0    -- Offset do scroll da lista
MTCCaveBot.lastPosition = nil  -- Ultima posicao para detectar stuck real
MTCCaveBot.samePositionCount = 0 -- Contador de vezes na mesma posicao

-- IDs de itens
MTCCaveBot.ROPE_ID = 3003
MTCCaveBot.SHOVEL_ID = 3457

-- UI references
MTCCaveBot.waypointListWidget = nil
MTCCaveBot.waypointScrollBar = nil
MTCCaveBot.waypointContainer = nil
MTCCaveBot.recordingEnabled = false
MTCCaveBot.lastRecordedPos = nil
MTCCaveBot.lastKnownPos = nil -- Ultima posicao conhecida do player (atualiza todo tick)
MTCCaveBot.selectedIndex = 1  -- Indice selecionado para edicao

-- Sistema de Emplacement (posicionamento do waypoint)
MTCCaveBot.EmplacementTypes = {
  CENTER = "center",
  NORTH = "north",
  SOUTH = "south",
  EAST = "east",
  WEST = "west",
  NORTHEAST = "northeast",
  NORTHWEST = "northwest",
  SOUTHEAST = "southeast",
  SOUTHWEST = "southwest"
}
MTCCaveBot.currentEmplacement = MTCCaveBot.EmplacementTypes.CENTER
MTCCaveBot.emplValueLabel = nil
MTCCaveBot.emplButtons = {} -- Referencia aos botoes de emplacement

-- Define emplacement atual e atualiza visual dos botoes
function MTCCaveBot.setEmplacement(emplType)
  MTCCaveBot.currentEmplacement = emplType
  if MTCCaveBot.emplValueLabel then
    MTCCaveBot.emplValueLabel:setText('[' .. emplType:upper() .. ']')
  end
  -- Atualiza cor de todos os botoes
  for btnType, btn in pairs(MTCCaveBot.emplButtons) do
    if btn then
      if btnType == emplType then
        btn:setColor('#00ffff') -- Ciano para selecionado
      else
        btn:setColor('#ffffff') -- Branco para nao selecionado
      end
    end
  end
  print("[CaveBot] Emplacement set to: " .. emplType)
end

-- Inicializa o modulo
function MTCCaveBot.init()
  MTCCaveBot.config = MTCCaveBot.loadConfig()
end

-- Carrega configuracao salva ou usa padrao
function MTCCaveBot.loadConfig()
  local saved = MTCConfig.get("cavebot")
  if saved then
    saved.currentIndex = 1
    saved.enabled = false
    -- Garante que loopEnabled existe
    if saved.loopEnabled == nil then
      saved.loopEnabled = true
    end
    -- Garante que minMonstersToStop existe
    if saved.minMonstersToStop == nil then
      saved.minMonstersToStop = 1
    end
    return saved
  end
  return table.copy(MTCCaveBot.defaultConfig)
end

-- Salva configuracao
function MTCCaveBot.saveConfig()
  MTCConfig.set("cavebot", MTCCaveBot.config)
end

-- Retorna posicao atual do player
function MTCCaveBot.getPlayerPosition()
  if not g_game.isOnline() then return nil end
  local player = g_game.getLocalPlayer()
  if not player then return nil end
  return player:getPosition()
end

-- Adiciona waypoint
function MTCCaveBot.addWaypoint(waypointType, x, y, z, extra)
  local waypoint = {
    type = waypointType,
    x = x,
    y = y,
    z = z,
    extra = extra or ""
  }
  table.insert(MTCCaveBot.config.waypoints, waypoint)
  MTCCaveBot.saveConfig()
  MTCCaveBot.refreshWaypointList()
  return waypoint
end

-- Remove waypoint por indice
function MTCCaveBot.removeWaypoint(index)
  if index > 0 and index <= #MTCCaveBot.config.waypoints then
    table.remove(MTCCaveBot.config.waypoints, index)
    -- Ajusta indices
    if MTCCaveBot.config.currentIndex > #MTCCaveBot.config.waypoints then
      MTCCaveBot.config.currentIndex = math.max(1, #MTCCaveBot.config.waypoints)
    end
    if MTCCaveBot.selectedIndex > #MTCCaveBot.config.waypoints then
      MTCCaveBot.selectedIndex = math.max(1, #MTCCaveBot.config.waypoints)
    end
    MTCCaveBot.saveConfig()
    MTCCaveBot.refreshWaypointList()
  end
end

-- Remove waypoint selecionado
function MTCCaveBot.removeSelectedWaypoint()
  if MTCCaveBot.selectedIndex and MTCCaveBot.selectedIndex > 0 then
    MTCCaveBot.removeWaypoint(MTCCaveBot.selectedIndex)
  end
end

-- Move waypoint para cima
function MTCCaveBot.moveWaypointUp(index)
  if index > 1 and index <= #MTCCaveBot.config.waypoints then
    local temp = MTCCaveBot.config.waypoints[index]
    MTCCaveBot.config.waypoints[index] = MTCCaveBot.config.waypoints[index - 1]
    MTCCaveBot.config.waypoints[index - 1] = temp
    -- Atualiza selecao
    MTCCaveBot.selectedIndex = index - 1
    -- Ajusta currentIndex se necessario
    if MTCCaveBot.config.currentIndex == index then
      MTCCaveBot.config.currentIndex = index - 1
    elseif MTCCaveBot.config.currentIndex == index - 1 then
      MTCCaveBot.config.currentIndex = index
    end
    MTCCaveBot.saveConfig()
    MTCCaveBot.refreshWaypointList()
  end
end

-- Move waypoint para baixo
function MTCCaveBot.moveWaypointDown(index)
  if index > 0 and index < #MTCCaveBot.config.waypoints then
    local temp = MTCCaveBot.config.waypoints[index]
    MTCCaveBot.config.waypoints[index] = MTCCaveBot.config.waypoints[index + 1]
    MTCCaveBot.config.waypoints[index + 1] = temp
    -- Atualiza selecao
    MTCCaveBot.selectedIndex = index + 1
    -- Ajusta currentIndex se necessario
    if MTCCaveBot.config.currentIndex == index then
      MTCCaveBot.config.currentIndex = index + 1
    elseif MTCCaveBot.config.currentIndex == index + 1 then
      MTCCaveBot.config.currentIndex = index
    end
    MTCCaveBot.saveConfig()
    MTCCaveBot.refreshWaypointList()
  end
end

-- Move waypoint selecionado para cima
function MTCCaveBot.moveSelectedUp()
  if MTCCaveBot.selectedIndex and MTCCaveBot.selectedIndex > 1 then
    MTCCaveBot.moveWaypointUp(MTCCaveBot.selectedIndex)
  end
end

-- Move waypoint selecionado para baixo
function MTCCaveBot.moveSelectedDown()
  if MTCCaveBot.selectedIndex and MTCCaveBot.selectedIndex < #MTCCaveBot.config.waypoints then
    MTCCaveBot.moveWaypointDown(MTCCaveBot.selectedIndex)
  end
end

-- Limpa todos os waypoints
function MTCCaveBot.clearWaypoints()
  MTCCaveBot.config.waypoints = {}
  MTCCaveBot.config.currentIndex = 1
  MTCCaveBot.saveConfig()
  MTCCaveBot.refreshWaypointList()
end

-- Atualiza lista visual de waypoints
function MTCCaveBot.refreshWaypointList()
  if not MTCCaveBot.waypointListWidget then return end
  
  -- Limpa lista
  MTCCaveBot.waypointListWidget:destroyChildren()
  
  local totalWp = #MTCCaveBot.config.waypoints
  local currentIdx = MTCCaveBot.config.currentIndex
  local selectedIdx = MTCCaveBot.selectedIndex or 1
  
  -- Garante que selectedIndex e valido
  if selectedIdx < 1 then selectedIdx = 1 end
  if selectedIdx > totalWp and totalWp > 0 then selectedIdx = totalWp end
  MTCCaveBot.selectedIndex = selectedIdx
  
  -- Sistema de janela deslizante - mostra 5 waypoints por vez
  local maxVisible = 5
  local scrollOffset = MTCCaveBot.scrollOffset or 0
  
  -- Auto-ajusta scroll para mostrar waypoint ATUAL (sendo executado) - prioridade
  if MTCCaveBot.config.enabled and currentIdx >= 1 and currentIdx <= totalWp then
    -- Quando bot esta ligado, acompanha o waypoint atual
    if currentIdx <= scrollOffset then
      scrollOffset = currentIdx - 1
    elseif currentIdx > scrollOffset + maxVisible then
      scrollOffset = currentIdx - maxVisible
    end
  else
    -- Quando bot esta desligado, acompanha o selecionado
    if selectedIdx <= scrollOffset then
      scrollOffset = selectedIdx - 1
    elseif selectedIdx > scrollOffset + maxVisible then
      scrollOffset = selectedIdx - maxVisible
    end
  end
  
  -- Limita scroll
  if scrollOffset < 0 then scrollOffset = 0 end
  if scrollOffset > totalWp - maxVisible then scrollOffset = math.max(0, totalWp - maxVisible) end
  MTCCaveBot.scrollOffset = scrollOffset
  
  local startIdx = scrollOffset + 1
  local endIdx = math.min(scrollOffset + maxVisible, totalWp)
  
  -- Adiciona waypoints visiveis
  for i = startIdx, endIdx do
    local wp = MTCCaveBot.config.waypoints[i]
    if not wp then break end
    
    -- Verifica estados
    local isCurrentWp = (i == currentIdx and MTCCaveBot.config.enabled)
    local isSelected = (i == selectedIdx)
    
    -- Monta texto do waypoint
    local posText = ""
    if wp.type == MTCCaveBot.WaypointTypes.LABEL then
      posText = wp.extra or ""
    else
      posText = string.format("%d,%d,%d", wp.x, wp.y, wp.z)
    end
    
    -- Prefixo mostra waypoint atual e selecionado
    local prefix = ""
    if isCurrentWp and isSelected then
      prefix = ">>"  -- Atual E selecionado
    elseif isCurrentWp then
      prefix = "> "  -- Apenas atual (executando)
    elseif isSelected then
      prefix = "* "  -- Apenas selecionado
    else
      prefix = "  "  -- Normal
    end
    local text = string.format("%s%02d. %s %s", prefix, i, wp.type:upper(), posText)
    
    -- Cor baseada no tipo
    local typeColor = '#ffffff'
    if wp.type == MTCCaveBot.WaypointTypes.WALK then
      typeColor = '#00ff00'
    elseif wp.type == MTCCaveBot.WaypointTypes.USE then
      typeColor = '#ffaa00'
    elseif wp.type == MTCCaveBot.WaypointTypes.ROPE then
      typeColor = '#00aaff'
    elseif wp.type == MTCCaveBot.WaypointTypes.SHOVEL then
      typeColor = '#aa5500'
    elseif wp.type == MTCCaveBot.WaypointTypes.LABEL then
      typeColor = '#ff00ff' -- Label agora e rosa/roxo
    elseif wp.type == MTCCaveBot.WaypointTypes.STAND then
      typeColor = '#ff00ff'
    elseif wp.type == MTCCaveBot.WaypointTypes.STAIRS then
      typeColor = '#ffff00' -- STAIRS amarelo
    end
    
    -- Cria Button clicavel
    local item = g_ui.createWidget('Button', MTCCaveBot.waypointListWidget)
    item:setId('wp_' .. i)
    item:setText(text)
    item:setHeight(20)
    item:setTextAlign(AlignLeft)
    item:setFont('verdana-11px-antialised')
    
    -- Cor do texto e background baseado no estado
    if isSelected and isCurrentWp then
      -- Selecionado E executando = destaque maximo (amarelo/laranja)
      item:setColor('#ffff00')
      item:setBackgroundColor('#664400')
    elseif isSelected then
      -- Apenas selecionado = destaque forte (ciano/azul vibrante)
      item:setColor('#00ffff')
      item:setBackgroundColor('#004466')
    elseif isCurrentWp then
      -- Apenas executando = roxo
      item:setColor('#ffffff')
      item:setBackgroundColor('#333366')
    else
      -- Normal = cor do tipo
      item:setColor(typeColor)
      item:setBackgroundColor('#2a2a2a')
    end
    
    -- Clique para selecionar
    local wpIndex = i
    item.onClick = function()
      MTCCaveBot.selectedIndex = wpIndex
      MTCCaveBot.refreshWaypointList()
    end
  end
  
  -- Atualiza contador
  MTCCaveBot.updateWaypointCount()
end

-- Scroll para cima na lista
function MTCCaveBot.scrollUp()
  if MTCCaveBot.scrollOffset > 0 then
    MTCCaveBot.scrollOffset = MTCCaveBot.scrollOffset - 1
    MTCCaveBot.refreshWaypointList()
  end
end

-- Scroll para baixo na lista
function MTCCaveBot.scrollDown()
  local totalWp = #MTCCaveBot.config.waypoints
  local maxVisible = 5
  if MTCCaveBot.scrollOffset < totalWp - maxVisible then
    MTCCaveBot.scrollOffset = MTCCaveBot.scrollOffset + 1
    MTCCaveBot.refreshWaypointList()
  end
end

-- Retorna tooltip do waypoint
function MTCCaveBot.getWaypointTooltip(wp, index)
  local lines = {"Waypoint #" .. index}
  table.insert(lines, "Type: " .. wp.type:upper())
  
  if wp.type ~= MTCCaveBot.WaypointTypes.LABEL then
    table.insert(lines, string.format("Position: %d, %d, %d", wp.x, wp.y, wp.z))
  end
  
  if wp.extra and wp.extra ~= "" then
    table.insert(lines, "Extra: " .. wp.extra)
  end
  
  table.insert(lines, "")
  table.insert(lines, "[Click to select]")
  
  return table.concat(lines, "\n")
end

-- Verifica se pode andar
function MTCCaveBot.canWalk()
  local now = g_clock.millis()
  return (now - MTCCaveBot.lastWalkTime) >= MTCCaveBot.walkCooldown
end

-- Calcula distancia entre duas posicoes
function MTCCaveBot.getDistance(pos1, pos2)
  if not pos1 or not pos2 then return 999 end
  if pos1.z ~= pos2.z then return 999 end
  return math.max(math.abs(pos1.x - pos2.x), math.abs(pos1.y - pos2.y))
end

-- Executa waypoint WALK
function MTCCaveBot.executeWalk(waypoint)
  local player = g_game.getLocalPlayer()
  if not player then return false end
  
  local playerPos = player:getPosition()
  if not playerPos then return false end
  
  local destPos = {x = waypoint.x, y = waypoint.y, z = waypoint.z}
  
  -- Verifica se ja chegou (distancia <= 1)
  local distance = MTCCaveBot.getDistance(playerPos, destPos)
  if distance <= 1 then
    MTCCaveBot.lastPosition = nil
    MTCCaveBot.samePositionCount = 0
    return true -- Chegou!
  end
  
  -- Detecta stuck REAL - se esta na mesma posicao por muito tempo
  if MTCCaveBot.lastPosition then
    if playerPos.x == MTCCaveBot.lastPosition.x and 
       playerPos.y == MTCCaveBot.lastPosition.y and 
       playerPos.z == MTCCaveBot.lastPosition.z then
      MTCCaveBot.samePositionCount = MTCCaveBot.samePositionCount + 1
      
      -- Se ficou na mesma posicao por 15 ciclos (1.5 segundos), esta STUCK
      if MTCCaveBot.samePositionCount >= 15 then
        -- Para qualquer autowalk em andamento
        if player:isAutoWalking() then
          g_game.stop()
        end
        
        -- Tenta andar manualmente em direcao alternativa
        MTCCaveBot.tryAlternativeWalk(playerPos, destPos)
        
        -- Se ainda stuck apos 25 ciclos, pula waypoint
        if MTCCaveBot.samePositionCount >= 25 then
          print("[CaveBot] STUCK REAL detectado! Pulando para proximo waypoint")
          MTCCaveBot.samePositionCount = 0
          MTCCaveBot.lastPosition = nil
          return false
        end
        
        return "retry"
      end
    else
      -- Moveu! Reset contador
      MTCCaveBot.samePositionCount = 0
    end
  end
  MTCCaveBot.lastPosition = {x = playerPos.x, y = playerPos.y, z = playerPos.z}
  
  -- Verifica se pode andar (cooldown)
  if not MTCCaveBot.canWalk() then
    return "retry"
  end
  
  -- Se o player esta andando, espera (mas nao muito)
  if player:isWalking() then
    return "retry"
  end
  
  -- Se esta em autowalk mas nao se movendo, cancela
  if player:isAutoWalking() and MTCCaveBot.samePositionCount > 5 then
    g_game.stop()
    MTCCaveBot.lastWalkTime = g_clock.millis()
    return "retry"
  end
  
  -- Se ja esta em autowalk e se movendo, deixa continuar
  if player:isAutoWalking() and MTCCaveBot.samePositionCount <= 5 then
    return "retry"
  end
  
  -- Tenta pathfinding
  local path = g_map.findPath(playerPos, destPos, 50, 0)
  
  if path and #path > 0 then
    g_game.autoWalk(path, playerPos)
    MTCCaveBot.lastWalkTime = g_clock.millis()
    return "retry"
  end
  
  -- Pathfinding falhou, tenta andar passo a passo
  MTCCaveBot.tryDirectWalk(playerPos, destPos)
  
  return "retry"
end

-- Tenta andar diretamente na direcao do destino
function MTCCaveBot.tryDirectWalk(playerPos, destPos)
  local dx = destPos.x - playerPos.x
  local dy = destPos.y - playerPos.y
  
  local directions = {}
  
  -- Adiciona direcoes primarias
  if math.abs(dx) >= math.abs(dy) then
    if dx > 0 then table.insert(directions, East)
    elseif dx < 0 then table.insert(directions, West)
    end
    if dy > 0 then table.insert(directions, South)
    elseif dy < 0 then table.insert(directions, North)
    end
  else
    if dy > 0 then table.insert(directions, South)
    elseif dy < 0 then table.insert(directions, North)
    end
    if dx > 0 then table.insert(directions, East)
    elseif dx < 0 then table.insert(directions, West)
    end
  end
  
  -- Tenta cada direcao
  for _, dir in ipairs(directions) do
    local newPos = MTCCaveBot.getPositionInDirection(playerPos, dir)
    if MTCCaveBot.isWalkable(newPos) then
      g_game.walk(dir)
      MTCCaveBot.lastWalkTime = g_clock.millis()
      return true
    end
  end
  
  return false
end

-- Tenta andar em direcao alternativa quando stuck
function MTCCaveBot.tryAlternativeWalk(playerPos, destPos)
  -- Todas as 8 direcoes
  local allDirections = {North, NorthEast, East, SouthEast, South, SouthWest, West, NorthWest}
  
  -- Calcula direcao geral para o destino
  local dx = destPos.x - playerPos.x
  local dy = destPos.y - playerPos.y
  
  -- Prioriza direcoes que aproximam do destino
  local prioritized = {}
  for _, dir in ipairs(allDirections) do
    local newPos = MTCCaveBot.getPositionInDirection(playerPos, dir)
    if newPos and MTCCaveBot.isWalkable(newPos) then
      -- Calcula se essa direcao aproxima do destino
      local newDist = MTCCaveBot.getDistance(newPos, destPos)
      local currentDist = MTCCaveBot.getDistance(playerPos, destPos)
      local priority = currentDist - newDist  -- Positivo = aproxima
      table.insert(prioritized, {dir = dir, priority = priority, pos = newPos})
    end
  end
  
  -- Ordena por prioridade (aproxima mais primeiro)
  table.sort(prioritized, function(a, b) return a.priority > b.priority end)
  
  -- Tenta a melhor direcao disponivel
  if #prioritized > 0 then
    g_game.walk(prioritized[1].dir)
    MTCCaveBot.lastWalkTime = g_clock.millis()
    return true
  end
  
  return false
end

-- Retorna posicao na direcao especificada
function MTCCaveBot.getPositionInDirection(pos, dir)
  local newPos = {x = pos.x, y = pos.y, z = pos.z}
  
  if dir == North then newPos.y = newPos.y - 1
  elseif dir == NorthEast then newPos.x = newPos.x + 1; newPos.y = newPos.y - 1
  elseif dir == East then newPos.x = newPos.x + 1
  elseif dir == SouthEast then newPos.x = newPos.x + 1; newPos.y = newPos.y + 1
  elseif dir == South then newPos.y = newPos.y + 1
  elseif dir == SouthWest then newPos.x = newPos.x - 1; newPos.y = newPos.y + 1
  elseif dir == West then newPos.x = newPos.x - 1
  elseif dir == NorthWest then newPos.x = newPos.x - 1; newPos.y = newPos.y - 1
  end
  
  return newPos
end

-- Verifica se tile e walkable
function MTCCaveBot.isWalkable(pos)
  if not pos then return false end
  
  local tile = g_map.getTile(pos)
  if not tile then return false end
  
  -- Verifica se o tile base e walkable (ignora criaturas)
  return tile:isWalkable(true)
end

-- Verifica se mudou de andar (para detectar sucesso ao usar escada/rope)
function MTCCaveBot.hasChangedFloor(oldZ)
  local playerPos = MTCCaveBot.getPlayerPosition()
  if not playerPos then return false end
  return playerPos.z ~= oldZ
end

-- Encontra item usavel no tile (escada, buraco, lever, etc)
function MTCCaveBot.findUsableItem(pos)
  local tile = g_map.getTile(pos)
  if not tile then return nil end
  
  -- Primeiro tenta getTopUseThing
  local topUse = tile:getTopUseThing()
  if topUse then return topUse end
  
  -- Se nao encontrou, tenta getTopMultiUseThing
  local topMultiUse = tile:getTopMultiUseThing()
  if topMultiUse then return topMultiUse end
  
  -- Tenta pegar qualquer item no tile
  local items = tile:getItems()
  if items then
    for _, item in ipairs(items) do
      if item:isUsable() or item:isMultiUse() then
        return item
      end
    end
  end
  
  -- Ultimo recurso: ground
  local ground = tile:getGround()
  if ground then return ground end
  
  return nil
end

-- Executa waypoint USE (escada, buraco, porta)
function MTCCaveBot.executeUse(waypoint)
  local player = g_game.getLocalPlayer()
  if not player then return false end
  
  local playerPos = player:getPosition()
  if not playerPos then return false end
  
  local usePos = {x = waypoint.x, y = waypoint.y, z = waypoint.z}
  local distance = MTCCaveBot.getDistance(playerPos, usePos)
  
  -- Guarda o Z atual para verificar se mudou de andar
  local currentZ = playerPos.z
  
  -- Se ja esta no tile do waypoint e em andar diferente, ja subiu/desceu
  if playerPos.x == usePos.x and playerPos.y == usePos.y and playerPos.z ~= usePos.z then
    return true -- Sucesso! Mudou de andar
  end
  
  -- Se esta longe, anda ate la
  if distance > 1 then
    -- Se player esta andando, espera
    if player:isWalking() or player:isAutoWalking() then
      return "retry"
    end
    
    local walkResult = MTCCaveBot.executeWalk(waypoint)
    return walkResult
  end
  
  -- Esta perto (distancia <= 1), tenta usar
  if not MTCCaveBot.canWalk() then
    return "retry"
  end
  
  -- Incrementa contador de tentativas para este waypoint
  MTCCaveBot.useRetryCount = (MTCCaveBot.useRetryCount or 0) + 1
  
  -- Encontra item para usar
  local useItem = MTCCaveBot.findUsableItem(usePos)
  if useItem then
    g_game.use(useItem)
    MTCCaveBot.lastWalkTime = g_clock.millis()
    MTCCaveBot.walkCooldown = 600
    
    -- Agenda verificacao e reset do cooldown
    scheduleEvent(function()
      MTCCaveBot.walkCooldown = 200
    end, 700)
    
    return "retry" -- Continua verificando se mudou de andar
  end
  
  -- Nao encontrou item usavel, tenta usar o ground
  local tile = g_map.getTile(usePos)
  if tile then
    local ground = tile:getGround()
    if ground then
      g_game.use(ground)
      MTCCaveBot.lastWalkTime = g_clock.millis()
      MTCCaveBot.walkCooldown = 600
      scheduleEvent(function()
        MTCCaveBot.walkCooldown = 200
      end, 700)
      return "retry"
    end
  end
  
  -- Se ja tentou usar varias vezes e nao funcionou, tenta andar diretamente no tile
  -- (para escadas que voce precisa pisar em cima ao inves de usar)
  if (MTCCaveBot.useRetryCount or 0) >= 3 then
    if distance == 1 then
      -- Tenta andar diretamente para o tile da escada
      local dir = MTCCaveBot.getDirectionTo(playerPos, usePos)
      if dir then
        g_game.walk(dir, false)
        MTCCaveBot.lastWalkTime = g_clock.millis()
        MTCCaveBot.walkCooldown = 400
        return "retry"
      end
    end
  end
  
  -- Continua tentando
  print("[CaveBot] USE: Tentativa " .. (MTCCaveBot.useRetryCount or 1) .. " - aguardando em " .. usePos.x .. "," .. usePos.y .. "," .. usePos.z)
  return "retry"
end

-- Obtem direcao de uma posicao para outra
function MTCCaveBot.getDirectionTo(fromPos, toPos)
  local dx = toPos.x - fromPos.x
  local dy = toPos.y - fromPos.y
  
  if dx == 0 and dy == -1 then return North
  elseif dx == 1 and dy == -1 then return NorthEast
  elseif dx == 1 and dy == 0 then return East
  elseif dx == 1 and dy == 1 then return SouthEast
  elseif dx == 0 and dy == 1 then return South
  elseif dx == -1 and dy == 1 then return SouthWest
  elseif dx == -1 and dy == 0 then return West
  elseif dx == -1 and dy == -1 then return NorthWest
  end
  
  return nil
end

-- Executa waypoint ROPE
function MTCCaveBot.executeRope(waypoint)
  local player = g_game.getLocalPlayer()
  if not player then return false end
  
  local playerPos = player:getPosition()
  if not playerPos then return false end
  
  local ropePos = {x = waypoint.x, y = waypoint.y, z = waypoint.z}
  local distance = MTCCaveBot.getDistance(playerPos, ropePos)
  
  -- Se mudou de andar, sucesso
  if playerPos.z < ropePos.z then
    return true
  end
  
  -- Se esta longe, anda ate la
  if distance > 1 then
    if player:isWalking() or player:isAutoWalking() then
      return "retry"
    end
    local walkResult = MTCCaveBot.executeWalk(waypoint)
    return walkResult
  end
  
  if not MTCCaveBot.canWalk() then
    return "retry"
  end
  
  -- Encontra rope spot
  local tile = g_map.getTile(ropePos)
  if not tile then return false end
  
  -- Tenta usar rope no tile
  local targetItem = MTCCaveBot.findUsableItem(ropePos)
  if targetItem then
    -- Procura rope no inventario
    local rope = g_game.findPlayerItem(MTCCaveBot.ROPE_ID, -1)
    if rope then
      g_game.useWith(rope, targetItem)
    else
      -- Tenta usar do inventario direto
      g_game.useInventoryItemWith(MTCCaveBot.ROPE_ID, targetItem, 0)
    end
    
    MTCCaveBot.lastWalkTime = g_clock.millis()
    MTCCaveBot.walkCooldown = 600
    scheduleEvent(function()
      MTCCaveBot.walkCooldown = 200
    end, 700)
    return "retry"
  end
  
  print("[CaveBot] ROPE: Nao encontrou rope spot em " .. ropePos.x .. "," .. ropePos.y .. "," .. ropePos.z)
  return false
end

-- Executa waypoint SHOVEL
function MTCCaveBot.executeShovel(waypoint)
  local player = g_game.getLocalPlayer()
  if not player then return false end
  
  local playerPos = player:getPosition()
  if not playerPos then return false end
  
  local shovelPos = {x = waypoint.x, y = waypoint.y, z = waypoint.z}
  local distance = MTCCaveBot.getDistance(playerPos, shovelPos)
  
  -- Se mudou de andar, sucesso
  if playerPos.z > shovelPos.z then
    return true
  end
  
  -- Se esta longe, anda ate la
  if distance > 1 then
    if player:isWalking() or player:isAutoWalking() then
      return "retry"
    end
    local walkResult = MTCCaveBot.executeWalk(waypoint)
    return walkResult
  end
  
  if not MTCCaveBot.canWalk() then
    return "retry"
  end
  
  -- Encontra lugar para usar shovel
  local tile = g_map.getTile(shovelPos)
  if not tile then return false end
  
  local targetItem = MTCCaveBot.findUsableItem(shovelPos)
  if targetItem then
    local shovel = g_game.findPlayerItem(MTCCaveBot.SHOVEL_ID, -1)
    if shovel then
      g_game.useWith(shovel, targetItem)
    else
      g_game.useInventoryItemWith(MTCCaveBot.SHOVEL_ID, targetItem, 0)
    end
    
    MTCCaveBot.lastWalkTime = g_clock.millis()
    MTCCaveBot.walkCooldown = 600
    scheduleEvent(function()
      MTCCaveBot.walkCooldown = 200
    end, 700)
    return "retry"
  end
  
  print("[CaveBot] SHOVEL: Nao encontrou lugar para cavar em " .. shovelPos.x .. "," .. shovelPos.y .. "," .. shovelPos.z)
  return false
end

-- Executa waypoint STAND (espera na posicao)
function MTCCaveBot.executeStand(waypoint)
  local playerPos = MTCCaveBot.getPlayerPosition()
  if not playerPos then return false end
  
  local standPos = {x = waypoint.x, y = waypoint.y, z = waypoint.z}
  
  -- Precisa estar exatamente na posicao
  if playerPos.x == standPos.x and playerPos.y == standPos.y and playerPos.z == standPos.z then
    return true -- Ja esta no lugar
  end
  
  -- Anda ate la
  return MTCCaveBot.executeWalk(waypoint)
end

-- Executa waypoint LABEL (nao faz nada, apenas marcador)
function MTCCaveBot.executeLabel(waypoint)
  return true
end

-- Executa waypoint STAIRS (anda diretamente na escada para mudar de andar)
function MTCCaveBot.executeStairs(waypoint)
  local player = g_game.getLocalPlayer()
  if not player then return false end
  
  local playerPos = player:getPosition()
  if not playerPos then return false end
  
  local stairsPos = {x = waypoint.x, y = waypoint.y, z = waypoint.z}
  local distance = MTCCaveBot.getDistance(playerPos, stairsPos)
  
  -- Inicializa o floor inicial se nao existir
  if not MTCCaveBot.stairsStartZ then
    MTCCaveBot.stairsStartZ = playerPos.z
    MTCCaveBot.stairsAttempts = 0
    print("[CaveBot] STAIRS: Iniciando em Z=" .. playerPos.z .. ", destino=" .. stairsPos.x .. "," .. stairsPos.y .. "," .. stairsPos.z)
  end
  
  -- Se mudou de andar (em relacao ao inicio), sucesso!
  if playerPos.z ~= MTCCaveBot.stairsStartZ then
    print("[CaveBot] STAIRS: Mudou de andar! " .. MTCCaveBot.stairsStartZ .. " -> " .. playerPos.z)
    MTCCaveBot.stairsStartZ = nil
    MTCCaveBot.stairsAttempts = nil
    return true
  end
  
  -- Se player esta andando, espera
  if player:isWalking() or player:isAutoWalking() then
    return "retry"
  end
  
  if not MTCCaveBot.canWalk() then
    return "retry"
  end
  
  MTCCaveBot.stairsAttempts = (MTCCaveBot.stairsAttempts or 0) + 1
  
  -- Se esta no mesmo tile da escada, tenta andar em varias direcoes para subir/descer
  if distance == 0 then
    print("[CaveBot] STAIRS: Estou no tile da escada, tentando andar para subir/descer")
    
    -- Tenta andar em todas as direcoes para encontrar a saida
    local directions = {North, East, South, West, NorthEast, NorthWest, SouthEast, SouthWest}
    local dirIndex = ((MTCCaveBot.stairsAttempts - 1) % #directions) + 1
    local dir = directions[dirIndex]
    
    g_game.walk(dir, false)
    MTCCaveBot.lastWalkTime = g_clock.millis()
    MTCCaveBot.walkCooldown = 400
    return "retry"
  end
  
  -- Se esta perto (distancia 1), anda diretamente no tile da escada
  if distance == 1 then
    local dir = MTCCaveBot.getDirectionTo(playerPos, stairsPos)
    if dir then
      print("[CaveBot] STAIRS: Andando para a escada em direcao " .. dir)
      g_game.walk(dir, false)
      MTCCaveBot.lastWalkTime = g_clock.millis()
      MTCCaveBot.walkCooldown = 400
      return "retry"
    end
  end
  
  -- Se esta longe (> 1), usa autoWalk para chegar perto
  if distance > 1 then
    -- Tenta andar diagonalmente se possivel para chegar mais perto
    local dx = stairsPos.x - playerPos.x
    local dy = stairsPos.y - playerPos.y
    
    -- Limita para movimento de 1 tile
    if dx > 1 then dx = 1 elseif dx < -1 then dx = -1 end
    if dy > 1 then dy = 1 elseif dy < -1 then dy = -1 end
    
    local targetPos = {x = playerPos.x + dx, y = playerPos.y + dy, z = playerPos.z}
    
    -- Verifica se o tile destino eh walkable
    local tile = g_map.getTile(targetPos)
    if tile and tile:isWalkable() then
      local dir = MTCCaveBot.getDirectionTo(playerPos, targetPos)
      if dir then
        g_game.walk(dir, false)
        MTCCaveBot.lastWalkTime = g_clock.millis()
        MTCCaveBot.walkCooldown = 300
        return "retry"
      end
    end
    
    -- Fallback: usa autoWalk
    local result = g_game.autoWalk(stairsPos, {}, 50000)
    if result then
      MTCCaveBot.lastWalkTime = g_clock.millis()
      MTCCaveBot.walkCooldown = 300
    end
    return "retry"
  end
  
  -- Fallback: tenta usar o tile caso seja uma escada que precisa de USE
  if MTCCaveBot.stairsAttempts > 5 then
    local useItem = MTCCaveBot.findUsableItem(stairsPos)
    if useItem then
      print("[CaveBot] STAIRS: Tentando usar item na escada")
      g_game.use(useItem)
      MTCCaveBot.lastWalkTime = g_clock.millis()
      MTCCaveBot.walkCooldown = 600
      return "retry"
    end
  end
  
  -- Reset apos muitas tentativas
  if MTCCaveBot.stairsAttempts > 20 then
    print("[CaveBot] STAIRS: Muitas tentativas, resetando...")
    MTCCaveBot.stairsStartZ = nil
    MTCCaveBot.stairsAttempts = nil
  end
  
  return "retry"
end

-- Vai para um label especifico
function MTCCaveBot.gotoLabel(labelName)
  labelName = labelName:lower()
  for i, wp in ipairs(MTCCaveBot.config.waypoints) do
    if wp.type == MTCCaveBot.WaypointTypes.LABEL then
      if wp.extra and wp.extra:lower() == labelName then
        MTCCaveBot.config.currentIndex = i
        return true
      end
    end
  end
  return false
end

-- Executa o waypoint atual
function MTCCaveBot.executeCurrentWaypoint()
  if not MTCCaveBot.config.enabled then return end
  if #MTCCaveBot.config.waypoints == 0 then return end
  
  local index = MTCCaveBot.config.currentIndex
  if index < 1 or index > #MTCCaveBot.config.waypoints then
    MTCCaveBot.config.currentIndex = 1
    index = 1
  end
  
  local waypoint = MTCCaveBot.config.waypoints[index]
  if not waypoint then return end
  
  -- Obtem posicao atual do player
  local player = g_game.getLocalPlayer()
  if not player then return end
  local playerPos = player:getPosition()
  if not playerPos then return end
  
  -- Para waypoints que mudam de andar (USE, ROPE, SHOVEL, STAIRS),
  -- verifica se o player ja esta em um andar diferente do waypoint
  if waypoint.type == MTCCaveBot.WaypointTypes.USE or 
     waypoint.type == MTCCaveBot.WaypointTypes.ROPE or
     waypoint.type == MTCCaveBot.WaypointTypes.SHOVEL or
     waypoint.type == MTCCaveBot.WaypointTypes.STAIRS then
    -- Se player esta em andar diferente do waypoint, considera como sucesso
    if playerPos.z ~= waypoint.z then
      print("[CaveBot] Waypoint " .. index .. " (" .. waypoint.type .. ") - Mudou de andar (Z: " .. waypoint.z .. " -> " .. playerPos.z .. ")")
      MTCCaveBot.retryCount = 0
      MTCCaveBot.stuckCount = 0
      MTCCaveBot.samePositionCount = 0
      MTCCaveBot.lastPosition = nil
      MTCCaveBot.useRetryCount = 0 -- Reset contador de tentativas USE
      MTCCaveBot.config.currentIndex = MTCCaveBot.config.currentIndex + 1
      
      if MTCCaveBot.config.currentIndex > #MTCCaveBot.config.waypoints then
        if MTCCaveBot.config.loopEnabled then
          MTCCaveBot.config.currentIndex = 1
          MTCCaveBot.config.enabled = true -- Garante que continua enabled
          print("[CaveBot] Loop - voltando ao waypoint 1")
        else
          MTCCaveBot.config.enabled = false
          MTCCaveBot.config.currentIndex = 1
          print("[CaveBot] Finished all waypoints - Bot stopped")
        end
      end
      MTCCaveBot.saveConfig()
      MTCCaveBot.refreshWaypointList()
      return
    end
  end
  
  local result = false
  
  if waypoint.type == MTCCaveBot.WaypointTypes.WALK then
    result = MTCCaveBot.executeWalk(waypoint)
  elseif waypoint.type == MTCCaveBot.WaypointTypes.USE then
    result = MTCCaveBot.executeUse(waypoint)
  elseif waypoint.type == MTCCaveBot.WaypointTypes.ROPE then
    result = MTCCaveBot.executeRope(waypoint)
  elseif waypoint.type == MTCCaveBot.WaypointTypes.SHOVEL then
    result = MTCCaveBot.executeShovel(waypoint)
  elseif waypoint.type == MTCCaveBot.WaypointTypes.STAND then
    result = MTCCaveBot.executeStand(waypoint)
  elseif waypoint.type == MTCCaveBot.WaypointTypes.LABEL then
    result = MTCCaveBot.executeLabel(waypoint)
  elseif waypoint.type == MTCCaveBot.WaypointTypes.STAIRS then
    result = MTCCaveBot.executeStairs(waypoint)
  end
  
  -- Processa resultado
  if result == true then
    -- Waypoint concluido, vai para o proximo
    MTCCaveBot.retryCount = 0
    MTCCaveBot.stuckCount = 0
    MTCCaveBot.samePositionCount = 0
    MTCCaveBot.lastPosition = nil
    MTCCaveBot.useRetryCount = 0 -- Reset contador de tentativas USE
    local oldIndex = MTCCaveBot.config.currentIndex
    MTCCaveBot.config.currentIndex = MTCCaveBot.config.currentIndex + 1
    
    -- Loop - verifica se chegou no fim
    if MTCCaveBot.config.currentIndex > #MTCCaveBot.config.waypoints then
      print("[CaveBot] ========================================")
      print("[CaveBot] REACHED END OF WAYPOINTS!")
      print("[CaveBot] Total waypoints: " .. #MTCCaveBot.config.waypoints)
      print("[CaveBot] Loop enabled: " .. tostring(MTCCaveBot.config.loopEnabled))
      print("[CaveBot] Current index before: " .. MTCCaveBot.config.currentIndex)
      
      if MTCCaveBot.config.loopEnabled == true then
        MTCCaveBot.config.currentIndex = 1
        -- IMPORTANTE: NÃO desabilita o enabled!
        print("[CaveBot] LOOP ACTIVATED - Resetting to waypoint 1")
        print("[CaveBot] Current index after: " .. MTCCaveBot.config.currentIndex)
        print("[CaveBot] Enabled status: " .. tostring(MTCCaveBot.config.enabled))
        -- Forca que enabled continue true
        MTCCaveBot.config.enabled = true
      else
        MTCCaveBot.config.enabled = false
        MTCCaveBot.config.currentIndex = 1
        print("[CaveBot] LOOP DISABLED - Bot stopped")
      end
      print("[CaveBot] ========================================")
    end
    
    MTCCaveBot.saveConfig()
    MTCCaveBot.refreshWaypointList()
  elseif result == false then
    -- Falhou completamente, pula para proximo waypoint
    print("[CaveBot] Waypoint " .. index .. " falhou, pulando para proximo")
    MTCCaveBot.retryCount = 0
    MTCCaveBot.stuckCount = 0
    MTCCaveBot.samePositionCount = 0
    MTCCaveBot.lastPosition = nil
    MTCCaveBot.config.currentIndex = MTCCaveBot.config.currentIndex + 1
    if MTCCaveBot.config.currentIndex > #MTCCaveBot.config.waypoints then
      if MTCCaveBot.config.loopEnabled then
        MTCCaveBot.config.currentIndex = 1
        MTCCaveBot.config.enabled = true -- Garante que continua enabled
        print("[CaveBot] Loop (after fail) - voltando ao waypoint 1")
      else
        MTCCaveBot.config.enabled = false
        MTCCaveBot.config.currentIndex = 1
      end
    end
    MTCCaveBot.saveConfig()
    MTCCaveBot.refreshWaypointList()
  end
  -- "retry" nao precisa fazer nada especial, a deteccao de stuck real esta no executeWalk
end

-- Verifica se tem monstros por perto para atacar
-- Conta quantos monstros estao por perto no mesmo andar
function MTCCaveBot.countMonstersNearby()
  local player = g_game.getLocalPlayer()
  if not player then return 0 end
  
  local playerPos = player:getPosition()
  if not playerPos then return 0 end
  
  -- Busca criaturas na tela
  local spectators = g_map.getSpectators(playerPos, false)
  if not spectators then return 0 end
  
  local count = 0
  for _, creature in ipairs(spectators) do
    if creature:isMonster() and not creature:isDead() then
      local creaturePos = creature:getPosition()
      if creaturePos and creaturePos.z == playerPos.z then
        local dist = math.max(math.abs(creaturePos.x - playerPos.x), math.abs(creaturePos.y - playerPos.y))
        if dist <= 8 then
          count = count + 1
        end
      end
    end
  end
  
  return count
end

-- Verifica se deve parar para atacar monstros
function MTCCaveBot.shouldStopForMonsters()
  local minMonsters = MTCCaveBot.config.minMonstersToStop or 1
  
  -- Se minMonsters = 0, nunca para para atacar
  if minMonsters <= 0 then
    return false
  end
  
  local monsterCount = MTCCaveBot.countMonstersNearby()
  
  -- Se nao tem monstros suficientes, nao para
  if monsterCount < minMonsters then
    MTCCaveBot.monsterStuckTime = nil
    return false
  end
  
  -- Tem monstros suficientes - verifica se esta atacando
  local attackedCreature = g_game.getAttackingCreature()
  if attackedCreature then
    -- Esta atacando, para o cavebot normalmente
    MTCCaveBot.monsterStuckTime = nil
    return true
  end
  
  -- Tem monstros MAS nao esta atacando nenhum
  -- Inicia ou verifica timer de stuck
  local now = g_clock.millis()
  
  if not MTCCaveBot.monsterStuckTime then
    MTCCaveBot.monsterStuckTime = now
  end
  
  -- Se ficou mais de 3 segundos vendo monstros mas sem atacar,
  -- significa que nao consegue alcancar - continua o cavebot!
  local stuckDuration = now - MTCCaveBot.monsterStuckTime
  if stuckDuration > 3000 then
    -- print("[CaveBot] Monstros na tela mas nao alcancaveis, continuando...")
    return false  -- Continua o cavebot
  end
  
  -- Ainda no periodo de espera - para e ve se vai atacar
  return true
end

-- Funcao principal de execucao (chamada pelo loop do bot)
function MTCCaveBot.execute()
  if not g_game.isOnline() then return end
  if not MTCCaveBot.config then return end
  if not MTCCaveBot.config.enabled then 
    return 
  end
  if #MTCCaveBot.config.waypoints == 0 then return end
  
  -- Pausa se tiver monstros suficientes E conseguir atacar
  if MTCCaveBot.shouldStopForMonsters() then
    return
  end
  
  MTCCaveBot.executeCurrentWaypoint()
end

-- Calcula offset baseado no emplacement
function MTCCaveBot.getEmplacementOffset()
  local offsets = {
    [MTCCaveBot.EmplacementTypes.CENTER] = {x = 0, y = 0},
    [MTCCaveBot.EmplacementTypes.NORTH] = {x = 0, y = -1},
    [MTCCaveBot.EmplacementTypes.SOUTH] = {x = 0, y = 1},
    [MTCCaveBot.EmplacementTypes.EAST] = {x = 1, y = 0},
    [MTCCaveBot.EmplacementTypes.WEST] = {x = -1, y = 0},
    [MTCCaveBot.EmplacementTypes.NORTHEAST] = {x = 1, y = -1},
    [MTCCaveBot.EmplacementTypes.NORTHWEST] = {x = -1, y = -1},
    [MTCCaveBot.EmplacementTypes.SOUTHEAST] = {x = 1, y = 1},
    [MTCCaveBot.EmplacementTypes.SOUTHWEST] = {x = -1, y = 1}
  }
  return offsets[MTCCaveBot.currentEmplacement] or {x = 0, y = 0}
end

-- Adiciona waypoint da posicao atual do player (com emplacement)
function MTCCaveBot.addCurrentPositionWaypoint(waypointType, extra)
  local pos = MTCCaveBot.getPlayerPosition()
  if not pos then return nil end
  
  -- Aplica offset do emplacement
  local offset = MTCCaveBot.getEmplacementOffset()
  local finalX = pos.x + offset.x
  local finalY = pos.y + offset.y
  
  print("[CaveBot] Adding waypoint at " .. finalX .. "," .. finalY .. "," .. pos.z .. " (Emplacement: " .. MTCCaveBot.currentEmplacement .. ")")
  
  return MTCCaveBot.addWaypoint(waypointType, finalX, finalY, pos.z, extra)
end

-- Toggle recording mode
function MTCCaveBot.toggleRecording()
  MTCCaveBot.recordingEnabled = not MTCCaveBot.recordingEnabled
  if MTCCaveBot.recordingEnabled then
    MTCCaveBot.lastRecordedPos = MTCCaveBot.getPlayerPosition()
    print("[CaveBot] Recording ENABLED - Walk around to record waypoints")
  else
    print("[CaveBot] Recording DISABLED")
  end
  return MTCCaveBot.recordingEnabled
end

-- Checa se deve gravar posicao (chamado quando player move)
function MTCCaveBot.checkRecording()
  if not MTCCaveBot.recordingEnabled then return end
  if not g_game.isOnline() then return end
  
  local currentPos = MTCCaveBot.getPlayerPosition()
  if not currentPos then return end
  
  -- Primeira posicao
  if not MTCCaveBot.lastRecordedPos then
    MTCCaveBot.lastRecordedPos = currentPos
    MTCCaveBot.lastKnownPos = {x = currentPos.x, y = currentPos.y, z = currentPos.z}
    MTCCaveBot.addWaypoint(MTCCaveBot.WaypointTypes.WALK, currentPos.x, currentPos.y, currentPos.z)
    MTCCaveBot.updateWaypointCount()
    return
  end
  
  -- Mudou de andar (escada/buraco)
  if currentPos.z ~= (MTCCaveBot.lastKnownPos and MTCCaveBot.lastKnownPos.z or MTCCaveBot.lastRecordedPos.z) then
    -- Usa lastKnownPos (posicao exata antes da escada) como waypoint STAIRS
    local stairPos = MTCCaveBot.lastKnownPos or MTCCaveBot.lastRecordedPos
    -- Se lastKnownPos eh diferente do ultimo waypoint gravado, adiciona WALK antes
    local distFromLastRec = MTCCaveBot.getDistance(stairPos, MTCCaveBot.lastRecordedPos)
    if distFromLastRec >= 2 then
      MTCCaveBot.addWaypoint(MTCCaveBot.WaypointTypes.WALK, stairPos.x, stairPos.y, stairPos.z)
    end
    -- Adiciona posicao exata da escada como STAIRS
    MTCCaveBot.addWaypoint(MTCCaveBot.WaypointTypes.STAIRS, stairPos.x, stairPos.y, stairPos.z)
    -- Adiciona nova posicao (apos subir/descer) como WALK
    MTCCaveBot.addWaypoint(MTCCaveBot.WaypointTypes.WALK, currentPos.x, currentPos.y, currentPos.z)
    MTCCaveBot.lastRecordedPos = currentPos
    MTCCaveBot.lastKnownPos = {x = currentPos.x, y = currentPos.y, z = currentPos.z}
    MTCCaveBot.updateWaypointCount()
    return
  end
  
  -- Atualiza posicao conhecida a cada tick
  MTCCaveBot.lastKnownPos = {x = currentPos.x, y = currentPos.y, z = currentPos.z}
  
  -- Andou longe o suficiente (3+ tiles)
  local distance = MTCCaveBot.getDistance(currentPos, MTCCaveBot.lastRecordedPos)
  if distance >= 3 then
    MTCCaveBot.addWaypoint(MTCCaveBot.WaypointTypes.WALK, currentPos.x, currentPos.y, currentPos.z)
    MTCCaveBot.lastRecordedPos = currentPos
    MTCCaveBot.updateWaypointCount()
  end
end

-- Cria UI do CaveBot
function MTCCaveBot.createUI(parent)
  -- Guarda referencia do parent
  MTCCaveBot.parentWidget = parent
  
  -- Loop sempre ativo por padrao
  MTCCaveBot.config.loopEnabled = true
  
  -- Titulo
  local titleLabel = g_ui.createWidget('Label', parent)
  titleLabel:setText('CaveBot')
  titleLabel:setTextAlign(AlignCenter)
  titleLabel:setFont('verdana-11px-rounded')
  titleLabel:setColor('#ff9900')
  titleLabel:setMarginTop(5)
  titleLabel:setMarginLeft(10)
  titleLabel:setMarginRight(10)

  -- ===== AUTO RECORD SECTION (TOPO) =====
  local arBtn = g_ui.createWidget('Button', parent)
  arBtn:setId('autoRecordBtn')
  arBtn:setHeight(28)
  arBtn:setMarginTop(6)
  arBtn:setMarginLeft(20)
  arBtn:setMarginRight(20)
  MTCCaveBot.autoRecordBtn = arBtn

  if MTCCaveBot.recordingEnabled then
    arBtn:setText('Auto Record: ON')
    arBtn:setColor('#00ff00')
  else
    arBtn:setText('Auto Record: OFF')
    arBtn:setColor('#ff4444')
  end

  arBtn.onClick = function()
    MTCCaveBot.toggleRecording()
    if MTCCaveBot.recordingEnabled then
      arBtn:setText('Auto Record: ON')
      arBtn:setColor('#00ff00')
    else
      arBtn:setText('Auto Record: OFF')
      arBtn:setColor('#ff4444')
    end
  end

  local arSeparator = g_ui.createWidget('Panel', parent)
  arSeparator:setHeight(1)
  arSeparator:setMarginTop(6)
  arSeparator:setMarginLeft(10)
  arSeparator:setMarginRight(10)
  arSeparator:setBackgroundColor('#444444')

  -- ===== EMPLACEMENT SECTION (PRIMEIRO) =====
  local emplLabel = g_ui.createWidget('Label', parent)
  emplLabel:setText('Emplacement:')
  emplLabel:setColor('#cccccc')
  emplLabel:setMarginTop(8)
  emplLabel:setMarginLeft(10)
  
  -- Label mostrando emplacement atual
  local emplValueLabel = g_ui.createWidget('Label', parent)
  emplValueLabel:setId('emplValueLabel')
  emplValueLabel:setText('[CENTER]')
  emplValueLabel:setColor('#00ffff')
  emplValueLabel:setTextAlign(AlignCenter)
  emplValueLabel:setMarginTop(2)
  emplValueLabel:setMarginLeft(10)
  emplValueLabel:setMarginRight(10)
  MTCCaveBot.emplValueLabel = emplValueLabel
  
  -- Grid 3x3 para direcoes
  MTCCaveBot.emplButtons = {}
  
  -- Linha 1: NW, N, NE
  local emplRow1 = g_ui.createWidget('Panel', parent)
  emplRow1:setHeight(24)
  emplRow1:setMarginTop(3)
  emplRow1:setMarginLeft(45)
  emplRow1:setMarginRight(45)
  
  local emplRow1Layout = UIHorizontalLayout.create(emplRow1)
  emplRow1Layout:setSpacing(2)
  emplRow1:setLayout(emplRow1Layout)
  
  local nwBtn = g_ui.createWidget('Button', emplRow1)
  nwBtn:setText('NW')
  nwBtn:setWidth(38)
  nwBtn:setHeight(20)
  MTCCaveBot.emplButtons[MTCCaveBot.EmplacementTypes.NORTHWEST] = nwBtn
  nwBtn.onClick = function()
    MTCCaveBot.setEmplacement(MTCCaveBot.EmplacementTypes.NORTHWEST)
  end
  
  local nBtn = g_ui.createWidget('Button', emplRow1)
  nBtn:setText('N')
  nBtn:setWidth(38)
  nBtn:setHeight(20)
  MTCCaveBot.emplButtons[MTCCaveBot.EmplacementTypes.NORTH] = nBtn
  nBtn.onClick = function()
    MTCCaveBot.setEmplacement(MTCCaveBot.EmplacementTypes.NORTH)
  end
  
  local neBtn = g_ui.createWidget('Button', emplRow1)
  neBtn:setText('NE')
  neBtn:setWidth(38)
  neBtn:setHeight(20)
  MTCCaveBot.emplButtons[MTCCaveBot.EmplacementTypes.NORTHEAST] = neBtn
  neBtn.onClick = function()
    MTCCaveBot.setEmplacement(MTCCaveBot.EmplacementTypes.NORTHEAST)
  end
  
  -- Linha 2: W, CENTER, E
  local emplRow2 = g_ui.createWidget('Panel', parent)
  emplRow2:setHeight(24)
  emplRow2:setMarginTop(2)
  emplRow2:setMarginLeft(45)
  emplRow2:setMarginRight(45)
  
  local emplRow2Layout = UIHorizontalLayout.create(emplRow2)
  emplRow2Layout:setSpacing(2)
  emplRow2:setLayout(emplRow2Layout)
  
  local wBtn = g_ui.createWidget('Button', emplRow2)
  wBtn:setText('W')
  wBtn:setWidth(38)
  wBtn:setHeight(20)
  MTCCaveBot.emplButtons[MTCCaveBot.EmplacementTypes.WEST] = wBtn
  wBtn.onClick = function()
    MTCCaveBot.setEmplacement(MTCCaveBot.EmplacementTypes.WEST)
  end
  
  local centerBtn = g_ui.createWidget('Button', emplRow2)
  centerBtn:setText('C')
  centerBtn:setWidth(38)
  centerBtn:setHeight(20)
  centerBtn:setColor('#00ffff')
  MTCCaveBot.emplButtons[MTCCaveBot.EmplacementTypes.CENTER] = centerBtn
  centerBtn.onClick = function()
    MTCCaveBot.setEmplacement(MTCCaveBot.EmplacementTypes.CENTER)
  end
  
  local eBtn = g_ui.createWidget('Button', emplRow2)
  eBtn:setText('E')
  eBtn:setWidth(38)
  eBtn:setHeight(20)
  MTCCaveBot.emplButtons[MTCCaveBot.EmplacementTypes.EAST] = eBtn
  eBtn.onClick = function()
    MTCCaveBot.setEmplacement(MTCCaveBot.EmplacementTypes.EAST)
  end
  
  -- Linha 3: SW, S, SE
  local emplRow3 = g_ui.createWidget('Panel', parent)
  emplRow3:setHeight(24)
  emplRow3:setMarginTop(2)
  emplRow3:setMarginLeft(45)
  emplRow3:setMarginRight(45)
  
  local emplRow3Layout = UIHorizontalLayout.create(emplRow3)
  emplRow3Layout:setSpacing(2)
  emplRow3:setLayout(emplRow3Layout)
  
  local swBtn = g_ui.createWidget('Button', emplRow3)
  swBtn:setText('SW')
  swBtn:setWidth(38)
  swBtn:setHeight(20)
  MTCCaveBot.emplButtons[MTCCaveBot.EmplacementTypes.SOUTHWEST] = swBtn
  swBtn.onClick = function()
    MTCCaveBot.setEmplacement(MTCCaveBot.EmplacementTypes.SOUTHWEST)
  end
  
  local sBtn = g_ui.createWidget('Button', emplRow3)
  sBtn:setText('S')
  sBtn:setWidth(38)
  sBtn:setHeight(20)
  MTCCaveBot.emplButtons[MTCCaveBot.EmplacementTypes.SOUTH] = sBtn
  sBtn.onClick = function()
    MTCCaveBot.setEmplacement(MTCCaveBot.EmplacementTypes.SOUTH)
  end
  
  local seBtn = g_ui.createWidget('Button', emplRow3)
  seBtn:setText('SE')
  seBtn:setWidth(38)
  seBtn:setHeight(20)
  MTCCaveBot.emplButtons[MTCCaveBot.EmplacementTypes.SOUTHEAST] = seBtn
  seBtn.onClick = function()
    MTCCaveBot.setEmplacement(MTCCaveBot.EmplacementTypes.SOUTHEAST)
  end
  
  -- ===== ADD WAYPOINT SECTION (SEGUNDO) =====
  local addLabel = g_ui.createWidget('Label', parent)
  addLabel:setText('Add Waypoint:')
  addLabel:setColor('#cccccc')
  addLabel:setMarginTop(8)
  addLabel:setMarginLeft(10)
  
  -- Primeira linha de botoes Add
  local addRow1 = g_ui.createWidget('Panel', parent)
  addRow1:setHeight(26)
  addRow1:setMarginTop(5)
  addRow1:setMarginLeft(10)
  addRow1:setMarginRight(10)
  
  local addRow1Layout = UIHorizontalLayout.create(addRow1)
  addRow1Layout:setSpacing(3)
  addRow1:setLayout(addRow1Layout)
  
  -- Botao WALK
  local walkBtn = g_ui.createWidget('Button', addRow1)
  walkBtn:setText('WALK')
  walkBtn:setWidth(55)
  walkBtn:setHeight(22)
  walkBtn:setColor('#00ff00')
  walkBtn.onClick = function()
    MTCCaveBot.addCurrentPositionWaypoint(MTCCaveBot.WaypointTypes.WALK)
    MTCCaveBot.updateWaypointCount()
  end
  
  -- Botao USE
  local useBtn = g_ui.createWidget('Button', addRow1)
  useBtn:setText('USE')
  useBtn:setWidth(45)
  useBtn:setHeight(22)
  useBtn:setColor('#ffaa00')
  useBtn.onClick = function()
    MTCCaveBot.addCurrentPositionWaypoint(MTCCaveBot.WaypointTypes.USE)
    MTCCaveBot.updateWaypointCount()
  end
  
  -- Botao ROPE
  local ropeBtn = g_ui.createWidget('Button', addRow1)
  ropeBtn:setText('ROPE')
  ropeBtn:setWidth(50)
  ropeBtn:setHeight(22)
  ropeBtn:setColor('#00aaff')
  ropeBtn.onClick = function()
    MTCCaveBot.addCurrentPositionWaypoint(MTCCaveBot.WaypointTypes.ROPE)
    MTCCaveBot.updateWaypointCount()
  end
  
  -- Botao SHOVEL
  local shovelBtn = g_ui.createWidget('Button', addRow1)
  shovelBtn:setText('SHOVEL')
  shovelBtn:setWidth(60)
  shovelBtn:setHeight(22)
  shovelBtn:setColor('#aa5500')
  shovelBtn.onClick = function()
    MTCCaveBot.addCurrentPositionWaypoint(MTCCaveBot.WaypointTypes.SHOVEL)
    MTCCaveBot.updateWaypointCount()
  end
  
  -- Segunda linha de botoes
  local addRow2 = g_ui.createWidget('Panel', parent)
  addRow2:setHeight(26)
  addRow2:setMarginTop(3)
  addRow2:setMarginLeft(10)
  addRow2:setMarginRight(10)
  
  local addRow2Layout = UIHorizontalLayout.create(addRow2)
  addRow2Layout:setSpacing(3)
  addRow2:setLayout(addRow2Layout)
  
  -- Botao STAND
  local standBtn = g_ui.createWidget('Button', addRow2)
  standBtn:setText('STAND')
  standBtn:setWidth(55)
  standBtn:setHeight(22)
  standBtn:setColor('#ff00ff')
  standBtn.onClick = function()
    MTCCaveBot.addCurrentPositionWaypoint(MTCCaveBot.WaypointTypes.STAND)
    MTCCaveBot.updateWaypointCount()
  end
  
  -- Botao STAIRS
  local stairsBtn = g_ui.createWidget('Button', addRow2)
  stairsBtn:setText('STAIRS')
  stairsBtn:setWidth(55)
  stairsBtn:setHeight(22)
  stairsBtn:setColor('#ffff00')
  stairsBtn.onClick = function()
    MTCCaveBot.addCurrentPositionWaypoint(MTCCaveBot.WaypointTypes.STAIRS)
    MTCCaveBot.updateWaypointCount()
  end
  
  -- Botao DEL
  local delBtn = g_ui.createWidget('Button', addRow2)
  delBtn:setText('DEL')
  delBtn:setWidth(45)
  delBtn:setHeight(22)
  delBtn:setColor('#ff4444')
  delBtn.onClick = function()
    MTCCaveBot.removeSelectedWaypoint()
  end
  
  -- Botao CLEAR
  local clearBtn = g_ui.createWidget('Button', addRow2)
  clearBtn:setText('CLEAR')
  clearBtn:setWidth(50)
  clearBtn:setHeight(22)
  clearBtn:setColor('#ff6666')
  clearBtn.onClick = function()
    MTCCaveBot.clearWaypoints()
  end
  
  -- ===== WAYPOINTS LIST (POR ULTIMO) =====
  -- Linha de configuracao de monstros
  local monsterRow = g_ui.createWidget('Panel', parent)
  monsterRow:setHeight(26)
  monsterRow:setMarginTop(10)
  monsterRow:setMarginLeft(10)
  monsterRow:setMarginRight(10)
  
  local monsterLayout = UIHorizontalLayout.create(monsterRow)
  monsterLayout:setSpacing(4)
  monsterRow:setLayout(monsterLayout)
  
  local monsterLabel = g_ui.createWidget('Label', monsterRow)
  monsterLabel:setText('Parar:')
  monsterLabel:setColor('#cccccc')
  monsterLabel:setWidth(40)
  monsterLabel:setHeight(22)
  
  local minusBtn = g_ui.createWidget('Button', monsterRow)
  minusBtn:setText('-')
  minusBtn:setWidth(24)
  minusBtn:setHeight(22)
  
  local monsterValue = g_ui.createWidget('Label', monsterRow)
  monsterValue:setText(tostring(MTCCaveBot.config.minMonstersToStop or 1))
  monsterValue:setColor('#00ff00')
  monsterValue:setTextAlign(AlignCenter)
  monsterValue:setWidth(20)
  monsterValue:setHeight(22)
  monsterValue:setBackgroundColor('#333333')
  MTCCaveBot.monsterValueLabel = monsterValue
  
  local plusBtn = g_ui.createWidget('Button', monsterRow)
  plusBtn:setText('+')
  plusBtn:setWidth(24)
  plusBtn:setHeight(22)
  
  local monsterLabel2 = g_ui.createWidget('Label', monsterRow)
  monsterLabel2:setText('mob(s) (0=off)')
  monsterLabel2:setColor('#888888')
  monsterLabel2:setWidth(80)
  monsterLabel2:setHeight(22)
  
  minusBtn.onClick = function()
    local current = MTCCaveBot.config.minMonstersToStop or 1
    current = math.max(0, current - 1)
    MTCCaveBot.config.minMonstersToStop = current
    MTCCaveBot.monsterValueLabel:setText(tostring(current))
    MTCCaveBot.monsterValueLabel:setColor(current == 0 and '#ff4444' or '#00ff00')
    MTCCaveBot.saveConfig()
  end
  
  plusBtn.onClick = function()
    local current = MTCCaveBot.config.minMonstersToStop or 1
    current = math.min(10, current + 1)
    MTCCaveBot.config.minMonstersToStop = current
    MTCCaveBot.monsterValueLabel:setText(tostring(current))
    MTCCaveBot.monsterValueLabel:setColor('#00ff00')
    MTCCaveBot.saveConfig()
  end
  
  if (MTCCaveBot.config.minMonstersToStop or 1) == 0 then
    monsterValue:setColor('#ff4444')
  end
  
  -- Label waypoints com botoes de scroll
  local wpRow = g_ui.createWidget('Panel', parent)
  wpRow:setHeight(20)
  wpRow:setMarginTop(8)
  wpRow:setMarginLeft(10)
  wpRow:setMarginRight(10)
  
  local wpLabel = g_ui.createWidget('Label', wpRow)
  wpLabel:setId('wpCountLabel')
  wpLabel:setText('Waypoints (' .. #MTCCaveBot.config.waypoints .. ')')
  wpLabel:setColor('#cccccc')
  wpLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  wpLabel:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
  MTCCaveBot.wpCountLabel = wpLabel
  
  local scrollDownBtn = g_ui.createWidget('Button', wpRow)
  scrollDownBtn:setText('v')
  scrollDownBtn:setWidth(22)
  scrollDownBtn:setHeight(18)
  scrollDownBtn:setColor('#888888')
  scrollDownBtn:addAnchor(AnchorRight, 'parent', AnchorRight)
  scrollDownBtn:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
  scrollDownBtn.onClick = function()
    MTCCaveBot.scrollDown()
  end
  
  local scrollUpBtn = g_ui.createWidget('Button', wpRow)
  scrollUpBtn:setText('^')
  scrollUpBtn:setWidth(22)
  scrollUpBtn:setHeight(18)
  scrollUpBtn:setColor('#888888')
  scrollUpBtn:addAnchor(AnchorRight, 'scrollDownBtn', AnchorLeft)
  scrollUpBtn:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
  scrollUpBtn:setMarginRight(2)
  scrollUpBtn.onClick = function()
    MTCCaveBot.scrollUp()
  end
  
  -- Container para lista
  local listContainer = g_ui.createWidget('Panel', parent)
  listContainer:setId('waypointContainer')
  listContainer:setHeight(100)
  listContainer:setMarginTop(5)
  listContainer:setMarginLeft(10)
  listContainer:setMarginRight(10)
  listContainer:setBackgroundColor('#1a1a1a')
  
  listContainer.onMouseWheel = function(self, mousePos, direction)
    if direction == MouseWheelUp then
      MTCCaveBot.scrollUp()
    else
      MTCCaveBot.scrollDown()
    end
    return true
  end
  
  -- Panel para waypoints
  local waypointList = g_ui.createWidget('Panel', listContainer)
  waypointList:setId('waypointList')
  waypointList:addAnchor(AnchorTop, 'parent', AnchorTop)
  waypointList:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  waypointList:addAnchor(AnchorRight, 'parent', AnchorRight)
  waypointList:addAnchor(AnchorBottom, 'parent', AnchorBottom)
  waypointList:setMarginTop(2)
  waypointList:setMarginBottom(2)
  waypointList:setMarginLeft(2)
  waypointList:setMarginRight(2)
  
  waypointList.onMouseWheel = function(self, mousePos, direction)
    if direction == MouseWheelUp then
      MTCCaveBot.scrollUp()
    else
      MTCCaveBot.scrollDown()
    end
    return true
  end
  
  local listLayout = UIVerticalLayout.create(waypointList)
  listLayout:setSpacing(1)
  waypointList:setLayout(listLayout)
  
  MTCCaveBot.waypointListWidget = waypointList
  MTCCaveBot.waypointContainer = listContainer
  
  -- Popula lista inicial
  MTCCaveBot.refreshWaypointList()
end

-- Atualiza contador de waypoints
function MTCCaveBot.updateWaypointCount()
  if MTCCaveBot.wpCountLabel then
    MTCCaveBot.wpCountLabel:setText('Waypoints (' .. #MTCCaveBot.config.waypoints .. ')')
  end
end

-- Retorna status do modulo
function MTCCaveBot.getStatus()
  if not MTCCaveBot.config then return "Not initialized" end
  if MTCCaveBot.recordingEnabled then return "Gravando..." end
  if not MTCCaveBot.config.enabled then return "Disabled" end
  
  local total = #MTCCaveBot.config.waypoints
  if total == 0 then return "No waypoints" end
  
  local current = MTCCaveBot.config.currentIndex
  return string.format("Running %d/%d", current, total)
end

-- (Auto Explore removido — substituido por Auto Record)



return MTCCaveBot
