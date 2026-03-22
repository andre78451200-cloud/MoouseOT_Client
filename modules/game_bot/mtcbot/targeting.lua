--[[
  MTC Bot - Sistema de Targeting
  
  Controla comportamento de movimento em relacao ao alvo:
  - Approach (ir para cima do monstro) - para Knights
  - Stand Still (ficar parado)
]]

MTCTargeting = MTCTargeting or {}

-- Configuracao padrao
MTCTargeting.defaultConfig = {
  enabled = false,
  -- Modo de movimento: "approach", "stand"
  moveMode = "stand",
  -- Apenas quando atacando
  onlyWhenAttacking = true,
  -- Diagonal permitido
  allowDiagonal = true,
}

-- Variaveis de controle
MTCTargeting.config = nil
MTCTargeting.lastMoveTime = 0
MTCTargeting.moveCooldown = 200  -- ms entre movimentos (mais rapido)

-- Inicializa o modulo
function MTCTargeting.init()
  MTCTargeting.config = MTCTargeting.loadConfig()
end

-- Carrega configuracao salva ou usa padrao
function MTCTargeting.loadConfig()
  local saved = MTCConfig.get("targeting")
  if saved then
    if saved.moveMode == nil then saved.moveMode = "stand" end
    if saved.onlyWhenAttacking == nil then saved.onlyWhenAttacking = true end
    if saved.allowDiagonal == nil then saved.allowDiagonal = true end
    -- Remove keepDistance se estava configurado
    if saved.moveMode == "keepDistance" then saved.moveMode = "stand" end
    return saved
  end
  return table.copy(MTCTargeting.defaultConfig)
end

-- Salva configuracao
function MTCTargeting.saveConfig()
  MTCConfig.set("targeting", MTCTargeting.config)
end

-- Calcula distancia entre duas posicoes
function MTCTargeting.getDistance(pos1, pos2)
  if not pos1 or not pos2 then return 999 end
  local dx = math.abs(pos1.x - pos2.x)
  local dy = math.abs(pos1.y - pos2.y)
  return math.max(dx, dy)
end

-- Verifica se pode mover
function MTCTargeting.canMove()
  local now = g_clock.millis()
  return (now - MTCTargeting.lastMoveTime) >= MTCTargeting.moveCooldown
end

-- Encontra posicao para ir para cima do monstro (com alternativas)
function MTCTargeting.findApproachPosition(playerPos, targetPos)
  if not playerPos or not targetPos then return nil end
  
  local currentDist = MTCTargeting.getDistance(playerPos, targetPos)
  
  -- Ja esta adjacente
  if currentDist <= 1 then return nil end
  
  -- Calcula direcao principal
  local dx = targetPos.x - playerPos.x
  local dy = targetPos.y - playerPos.y
  
  local moveX = 0
  local moveY = 0
  
  if dx > 0 then moveX = 1
  elseif dx < 0 then moveX = -1 end
  
  if dy > 0 then moveY = 1
  elseif dy < 0 then moveY = -1 end
  
  -- Lista de posicoes para tentar (em ordem de prioridade)
  local positions = {}
  
  -- 1. Diagonal direta (se ambos moveX e moveY != 0)
  if moveX ~= 0 and moveY ~= 0 then
    table.insert(positions, {x = playerPos.x + moveX, y = playerPos.y + moveY, z = playerPos.z})
  end
  
  -- 2. Horizontal direto
  if moveX ~= 0 then
    table.insert(positions, {x = playerPos.x + moveX, y = playerPos.y, z = playerPos.z})
  end
  
  -- 3. Vertical direto
  if moveY ~= 0 then
    table.insert(positions, {x = playerPos.x, y = playerPos.y + moveY, z = playerPos.z})
  end
  
  -- 4. Diagonais alternativas (para contornar obstaculos)
  if moveX ~= 0 then
    table.insert(positions, {x = playerPos.x + moveX, y = playerPos.y + 1, z = playerPos.z})
    table.insert(positions, {x = playerPos.x + moveX, y = playerPos.y - 1, z = playerPos.z})
  end
  if moveY ~= 0 then
    table.insert(positions, {x = playerPos.x + 1, y = playerPos.y + moveY, z = playerPos.z})
    table.insert(positions, {x = playerPos.x - 1, y = playerPos.y + moveY, z = playerPos.z})
  end
  
  -- Retorna a primeira posicao walkable
  for _, pos in ipairs(positions) do
    if MTCTargeting.isWalkable(pos) then
      return pos
    end
  end
  
  -- Se nenhuma posicao foi walkable, tenta a direcao principal mesmo assim
  -- O jogo vai bloquear se nao for possivel
  if moveX ~= 0 or moveY ~= 0 then
    return {x = playerPos.x + moveX, y = playerPos.y + moveY, z = playerPos.z}
  end
  
  return nil
end

-- Verifica se tile e walkable
function MTCTargeting.isWalkable(pos)
  if not pos then return false end
  
  local tile = g_map.getTile(pos)
  if not tile then return true end  -- Se nao tem tile carregado, assume que pode andar
  
  -- Verifica se o tile base eh walkable (ignora criaturas)
  return tile:isWalkable(true)
end

-- Move para posicao usando direcao
function MTCTargeting.moveTo(pos)
  if not pos then return false end
  
  local player = g_game.getLocalPlayer()
  if not player then return false end
  
  -- Verifica se player esta andando
  if player:isWalking() then return false end
  
  local playerPos = player:getPosition()
  if not playerPos then return false end
  
  -- Calcula direcao
  local dx = pos.x - playerPos.x
  local dy = pos.y - playerPos.y
  
  local dir = nil
  
  if dx == 0 and dy == -1 then dir = North
  elseif dx == 1 and dy == -1 then dir = NorthEast
  elseif dx == 1 and dy == 0 then dir = East
  elseif dx == 1 and dy == 1 then dir = SouthEast
  elseif dx == 0 and dy == 1 then dir = South
  elseif dx == -1 and dy == 1 then dir = SouthWest
  elseif dx == -1 and dy == 0 then dir = West
  elseif dx == -1 and dy == -1 then dir = NorthWest
  end
  
  if dir then
    -- Se nao permite diagonal, converte para cardinal
    if not MTCTargeting.config.allowDiagonal then
      if dir == NorthEast then 
        dir = math.abs(dx) >= math.abs(dy) and East or North
      elseif dir == NorthWest then 
        dir = math.abs(dx) >= math.abs(dy) and West or North
      elseif dir == SouthEast then 
        dir = math.abs(dx) >= math.abs(dy) and East or South
      elseif dir == SouthWest then 
        dir = math.abs(dx) >= math.abs(dy) and West or South
      end
    end
    
    g_game.walk(dir)
    MTCTargeting.lastMoveTime = g_clock.millis()
    return true
  end
  
  return false
end

-- Funcao principal de execucao
function MTCTargeting.execute()
  if not g_game.isOnline() then return end
  -- Targeting funciona quando Attack esta ON (nao precisa de enabled proprio)
  if not MTCTargeting.config then return end
  if MTCTargeting.config.moveMode == "stand" then return end
  -- Verifica se Attack esta ativo
  if not MTCAttack or not MTCAttack.config or not MTCAttack.config.enabled then return end
  if not MTCTargeting.canMove() then return end
  
  local player = g_game.getLocalPlayer()
  if not player then return end
  
  -- Nao move se ja esta andando
  if player:isWalking() then return end
  
  -- IMPORTANTE: Se o CaveBot esta ativo e NAO esta parado para monstros,
  -- o Targeting NAO deve interferir no movimento!
  if MTCCaveBot and MTCCaveBot.config and MTCCaveBot.config.enabled then
    if not MTCCaveBot.shouldStopForMonsters() then
      -- CaveBot esta andando, nao interfere
      return
    end
  end
  
  -- Verifica se esta atacando (se configurado)
  local target = g_game.getAttackingCreature()
  if MTCTargeting.config.onlyWhenAttacking and not target then return end
  
  if not target then return end
  if target:isDead() then return end
  
  local playerPos = player:getPosition()
  local targetPos = target:getPosition()
  
  if not playerPos or not targetPos then return end
  if playerPos.z ~= targetPos.z then return end
  
  local newPos = nil
  
  if MTCTargeting.config.moveMode == "approach" then
    -- Ir para cima do monstro
    newPos = MTCTargeting.findApproachPosition(playerPos, targetPos)
  end
  
  if newPos then
    MTCTargeting.moveTo(newPos)
  end
end

-- Cria a UI do modulo
function MTCTargeting.createUI(container)
  if not container then return end
  
  container:destroyChildren()
  
  -- Titulo
  local title = g_ui.createWidget("Label", container)
  title:setText("Targeting & Movement")
  title:setTextAlign(AlignCenter)
  title:setFont("verdana-11px-rounded")
  title:setColor("#9B59B6")
  title:setHeight(20)
  title:setMarginBottom(10)
  
  -- === MODO DE MOVIMENTO ===
  local modeLabel = g_ui.createWidget("Label", container)
  modeLabel:setText("Modo de Movimento:")
  modeLabel:setColor("#ffffff")
  modeLabel:setMarginBottom(5)
  
  -- Botoes de modo (horizontais)
  local modeRow = g_ui.createWidget("Panel", container)
  modeRow:setHeight(30)
  modeRow:setMarginBottom(10)
  
  local modeLayout = UIHorizontalLayout.create(modeRow)
  modeLayout:setSpacing(5)
  modeRow:setLayout(modeLayout)
  
  -- Funcao para atualizar visual dos botoes
  local modeButtons = {}
  local function updateModeButtons()
    for mode, btn in pairs(modeButtons) do
      if MTCTargeting.config.moveMode == mode then
        btn:setColor('#00ff00')
      else
        btn:setColor('#888888')
      end
    end
  end
  
  -- Botao STAND (parado)
  local standBtn = g_ui.createWidget("Button", modeRow)
  standBtn:setText("Parado")
  standBtn:setWidth(60)
  standBtn:setHeight(26)
  modeButtons["stand"] = standBtn
  
  standBtn.onClick = function()
    MTCTargeting.config.moveMode = "stand"
    MTCTargeting.saveConfig()
    updateModeButtons()
  end
  
  -- Botao APPROACH (ir para cima - Knight)
  local approachBtn = g_ui.createWidget("Button", modeRow)
  approachBtn:setText("Approach")
  approachBtn:setWidth(70)
  approachBtn:setHeight(26)
  approachBtn:setTooltip("Ir para cima do monstro (Knight)")
  modeButtons["approach"] = approachBtn
  
  approachBtn.onClick = function()
    MTCTargeting.config.moveMode = "approach"
    MTCTargeting.saveConfig()
    updateModeButtons()
  end
  
  updateModeButtons()
  
  -- Separador
  local sep1 = g_ui.createWidget("HorizontalSeparator", container)
  sep1:setMarginTop(5)
  sep1:setMarginBottom(10)
  
  -- === OPCOES ===
  local optTitle = g_ui.createWidget("Label", container)
  optTitle:setText("Opcoes:")
  optTitle:setColor("#aaaaaa")
  optTitle:setMarginBottom(8)
  
  -- Checkbox: Apenas quando atacando
  local onlyAttackRow = g_ui.createWidget("Panel", container)
  onlyAttackRow:setHeight(26)
  onlyAttackRow:setMarginBottom(5)
  
  local onlyAttackBtn = g_ui.createWidget("Button", onlyAttackRow)
  onlyAttackBtn:setText(MTCTargeting.config.onlyWhenAttacking and "[X]" or "[ ]")
  onlyAttackBtn:setWidth(28)
  onlyAttackBtn:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  onlyAttackBtn:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
  
  local onlyAttackLabel = g_ui.createWidget("Label", onlyAttackRow)
  onlyAttackLabel:setText("Apenas quando atacando")
  onlyAttackLabel:setColor("#cccccc")
  onlyAttackLabel:addAnchor(AnchorLeft, 'prev', AnchorRight)
  onlyAttackLabel:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
  onlyAttackLabel:setMarginLeft(5)
  
  onlyAttackBtn.onClick = function()
    MTCTargeting.config.onlyWhenAttacking = not MTCTargeting.config.onlyWhenAttacking
    onlyAttackBtn:setText(MTCTargeting.config.onlyWhenAttacking and "[X]" or "[ ]")
    MTCTargeting.saveConfig()
  end
  
  -- Checkbox: Permitir diagonal
  local diagRow = g_ui.createWidget("Panel", container)
  diagRow:setHeight(26)
  diagRow:setMarginBottom(5)
  
  local diagBtn = g_ui.createWidget("Button", diagRow)
  diagBtn:setText(MTCTargeting.config.allowDiagonal and "[X]" or "[ ]")
  diagBtn:setWidth(28)
  diagBtn:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  diagBtn:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
  
  local diagLabel = g_ui.createWidget("Label", diagRow)
  diagLabel:setText("Permitir movimento diagonal")
  diagLabel:setColor("#cccccc")
  diagLabel:addAnchor(AnchorLeft, 'prev', AnchorRight)
  diagLabel:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
  diagLabel:setMarginLeft(5)
  
  diagBtn.onClick = function()
    MTCTargeting.config.allowDiagonal = not MTCTargeting.config.allowDiagonal
    diagBtn:setText(MTCTargeting.config.allowDiagonal and "[X]" or "[ ]")
    MTCTargeting.saveConfig()
  end
  
  -- Info
  local infoLabel = g_ui.createWidget("Label", container)
  infoLabel:setMarginTop(15)
  infoLabel:setText("Parado = Nao move automaticamente\nApproach = Vai para cima do monstro")
  infoLabel:setColor("#666666")
  infoLabel:setFont("verdana-11px-rounded")
end

-- Retorna status do modulo
function MTCTargeting.getStatus()
  if not MTCTargeting.config then
    return "OFF"
  end
  local modes = {
    stand = "Parado",
    approach = "Approach"
  }
  return modes[MTCTargeting.config.moveMode] or "ON"
end

-- Inicializa
MTCTargeting.init()
