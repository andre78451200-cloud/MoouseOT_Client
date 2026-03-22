--[[
  MTC Bot - Sistema de Equipment (Ring/Amulet)
  
  Equipa automaticamente rings e amulets baseado em HP/MP:
  - Quando HP/MP <= threshold% -> EQUIPA o item
  - Quando HP/MP > threshold% -> REMOVE o item (move para backpack)
  
  Exemplo: threshold = 80%
  - HP cai para 75% -> Equipa Energy Ring
  - HP sobe para 85% -> Remove Energy Ring
]]

MTCEquipment = MTCEquipment or {}

-- Configuracao padrao
MTCEquipment.defaultConfig = {
  enabled = false,
  slots = {
    {
      enabled = false,
      itemId = 0,
      type = "ring",
      condition = "life",
      threshold = 80,
    },
    {
      enabled = false,
      itemId = 0,
      type = "ring",
      condition = "life",
      threshold = 50,
    },
    {
      enabled = false,
      itemId = 0,
      type = "amulet",
      condition = "life",
      threshold = 80,
    },
    {
      enabled = false,
      itemId = 0,
      type = "amulet",
      condition = "mana",
      threshold = 50,
    },
  }
}

-- Slots do inventario (InventorySlot enum)
MTCEquipment.SLOT_HEAD = 1
MTCEquipment.SLOT_NECKLACE = 2      -- AMULET slot correto
MTCEquipment.SLOT_BACKPACK = 3
MTCEquipment.SLOT_ARMOR = 4
MTCEquipment.SLOT_RIGHT = 5
MTCEquipment.SLOT_LEFT = 6
MTCEquipment.SLOT_LEGS = 7
MTCEquipment.SLOT_FEET = 8
MTCEquipment.SLOT_FINGER = 9        -- RING slot correto
MTCEquipment.SLOT_AMMO = 10

-- Variaveis de controle
MTCEquipment.config = nil
MTCEquipment.lastActionTime = {}
MTCEquipment.actionCooldown = 500   -- Cooldown entre acoes (equip/unequip)

-- Inicializa o modulo
function MTCEquipment.init()
  MTCEquipment.config = MTCEquipment.loadConfig()
end

-- Carrega configuracao
function MTCEquipment.loadConfig()
  local saved = MTCConfig.get("equipment")
  if saved then
    return saved
  end
  return table.copy(MTCEquipment.defaultConfig)
end

-- Salva configuracao
function MTCEquipment.saveConfig()
  MTCConfig.set("equipment", MTCEquipment.config)
end

-- Retorna porcentagem de vida
function MTCEquipment.getHealthPercent()
  if not g_game.isOnline() then return 100 end
  local player = g_game.getLocalPlayer()
  if not player then return 100 end
  
  local health = player:getHealth()
  local maxHealth = player:getMaxHealth()
  if maxHealth == 0 then return 100 end
  
  return math.floor((health / maxHealth) * 100)
end

-- Retorna porcentagem de mana
function MTCEquipment.getManaPercent()
  if not g_game.isOnline() then return 100 end
  local player = g_game.getLocalPlayer()
  if not player then return 100 end
  
  local mana = player:getMana()
  local maxMana = player:getMaxMana()
  if maxMana == 0 then return 100 end
  
  return math.floor((mana / maxMana) * 100)
end

-- Retorna o valor atual da condicao (life ou mana)
function MTCEquipment.getCurrentValue(condition)
  if condition == "life" then
    return MTCEquipment.getHealthPercent()
  elseif condition == "mana" then
    return MTCEquipment.getManaPercent()
  end
  return 100
end

-- Verifica cooldown para acao
function MTCEquipment.canAct(slotIndex)
  local now = g_clock.millis()
  local lastAction = MTCEquipment.lastActionTime[slotIndex] or 0
  return (now - lastAction) >= MTCEquipment.actionCooldown
end

-- Atualiza cooldown
function MTCEquipment.updateCooldown(slotIndex)
  MTCEquipment.lastActionTime[slotIndex] = g_clock.millis()
end

-- Retorna o slot de inventario correto para o tipo
function MTCEquipment.getInventorySlot(slotType)
  if slotType == "ring" then
    return MTCEquipment.SLOT_FINGER
  elseif slotType == "amulet" then
    return MTCEquipment.SLOT_NECKLACE
  end
  return nil
end

-- Procura item nos containers (backpacks)
function MTCEquipment.findItemInContainers(itemId)
  if not itemId or itemId == 0 then return nil, nil end
  
  local containers = g_game.getContainers()
  for _, container in pairs(containers) do
    for slot = 0, container:getItemsCount() - 1 do
      local item = container:getItem(slot)
      if item and item:getId() == itemId then
        return item, container
      end
    end
  end
  
  return nil, nil
end

-- Encontra o primeiro container aberto (para mover item para la)
function MTCEquipment.findOpenContainer()
  local containers = g_game.getContainers()
  for _, container in pairs(containers) do
    if container:getItemsCount() < container:getCapacity() then
      return container
    end
  end
  -- Se todos estao cheios, retorna o primeiro mesmo
  for _, container in pairs(containers) do
    return container
  end
  return nil
end

-- Retorna o item equipado no slot especificado
function MTCEquipment.getEquippedItem(slotType)
  if not g_game.isOnline() then return nil end
  local player = g_game.getLocalPlayer()
  if not player then return nil end
  
  local inventorySlot = MTCEquipment.getInventorySlot(slotType)
  if not inventorySlot then return nil end
  
  return player:getInventoryItem(inventorySlot)
end

-- Verifica se o item especificado esta equipado
function MTCEquipment.isItemEquipped(itemId, slotType)
  local equippedItem = MTCEquipment.getEquippedItem(slotType)
  return equippedItem and equippedItem:getId() == itemId
end

-- EQUIPA um item da backpack para o slot
function MTCEquipment.equipItem(slotIndex, slot)
  if not g_game.isOnline() then return false end
  if not MTCEquipment.canAct(slotIndex) then return false end
  
  -- Ja esta equipado?
  if MTCEquipment.isItemEquipped(slot.itemId, slot.type) then
    return false
  end
  
  -- Procura o item na backpack
  local item, container = MTCEquipment.findItemInContainers(slot.itemId)
  if not item then
    return false
  end
  
  -- Move para o slot de equipamento
  local inventorySlot = MTCEquipment.getInventorySlot(slot.type)
  if not inventorySlot then return false end
  
  local destPos = {x = 65535, y = inventorySlot, z = 0}
  g_game.move(item, destPos, 1)
  
  MTCEquipment.updateCooldown(slotIndex)
  return true
end

-- REMOVE um item equipado e move para a backpack
function MTCEquipment.unequipItem(slotIndex, slot)
  if not g_game.isOnline() then return false end
  if not MTCEquipment.canAct(slotIndex) then return false end
  
  -- Verifica se o item esta equipado
  if not MTCEquipment.isItemEquipped(slot.itemId, slot.type) then
    return false
  end
  
  local equippedItem = MTCEquipment.getEquippedItem(slot.type)
  if not equippedItem then return false end
  
  -- Encontra um container para mover
  local container = MTCEquipment.findOpenContainer()
  if not container then
    return false
  end
  
  -- Move o item para o container
  local destPos = container:getSlotPosition(container:getItemsCount())
  g_game.move(equippedItem, destPos, 1)
  
  MTCEquipment.updateCooldown(slotIndex)
  return true
end

-- Funcao principal de execucao
function MTCEquipment.execute()
  if not g_game.isOnline() then return end
  if not MTCEquipment.config or not MTCEquipment.config.enabled then return end
  
  local player = g_game.getLocalPlayer()
  if not player then return end
  
  for i, slot in ipairs(MTCEquipment.config.slots) do
    if slot.enabled and slot.itemId and slot.itemId > 0 then
      local currentValue = MTCEquipment.getCurrentValue(slot.condition)
      local threshold = slot.threshold or 80
      
      if currentValue <= threshold then
        -- HP/MP baixo -> EQUIPAR
        MTCEquipment.equipItem(i, slot)
      else
        -- HP/MP alto -> REMOVER (se estiver equipado)
        MTCEquipment.unequipItem(i, slot)
      end
    end
  end
end

-- Cria a interface
function MTCEquipment.createUI(parent)
  parent:destroyChildren()
  
  local titleLabel = g_ui.createWidget('Label', parent)
  titleLabel:setText('Auto Ring/Amulet - Equipa quando HP/MP baixo')
  titleLabel:setColor('#00ff88')
  titleLabel:setHeight(20)
  titleLabel:setMarginBottom(3)
  
  local descLabel = g_ui.createWidget('Label', parent)
  descLabel:setText('Equipa quando <= threshold, remove quando > threshold')
  descLabel:setColor('#888888')
  descLabel:setHeight(16)
  descLabel:setMarginBottom(8)
  
  for i = 1, 4 do
    MTCEquipment.createSlotUI(parent, i)
  end
  
  -- Dicas de IDs comuns
  local tipsLabel = g_ui.createWidget('Label', parent)
  tipsLabel:setText('IDs: Energy Ring=3051 | Might Ring=3048 | SSA=3081 | Stone Skin Amulet=3083')
  tipsLabel:setColor('#666666')
  tipsLabel:setHeight(16)
  tipsLabel:setMarginTop(10)
end

-- Cria UI de um slot
function MTCEquipment.createSlotUI(parent, slotIndex)
  local slot = MTCEquipment.config.slots[slotIndex]
  if not slot then return end
  
  -- Container do slot
  local slotPanel = g_ui.createWidget('Panel', parent)
  slotPanel:setLayout(UIVerticalLayout.create(slotPanel))
  slotPanel:setHeight(75)
  slotPanel:setMarginTop(5)
  slotPanel:setBackgroundColor('#1a1a1a')
  slotPanel:setPadding(5)
  
  -- Linha 1: Checkbox + Tipo + Item Icon
  local row1 = g_ui.createWidget('Panel', slotPanel)
  row1:setLayout(UIHorizontalLayout.create(row1))
  row1:setHeight(26)
  
  local enableCheck = g_ui.createWidget('CheckBox', row1)
  enableCheck:setText('Slot ' .. slotIndex)
  enableCheck:setChecked(slot.enabled)
  enableCheck:setWidth(65)
  
  enableCheck.onCheckChange = function(widget, checked)
    MTCEquipment.config.slots[slotIndex].enabled = checked
    MTCEquipment.saveConfig()
  end
  
  local typeCombo = g_ui.createWidget('ComboBox', row1)
  typeCombo:setWidth(75)
  typeCombo:addOption('Ring')
  typeCombo:addOption('Amulet')
  typeCombo:setCurrentOption(slot.type == "ring" and "Ring" or "Amulet")
  typeCombo:setMarginLeft(10)
  
  typeCombo.onOptionChange = function(widget, option)
    MTCEquipment.config.slots[slotIndex].type = option:lower()
    MTCEquipment.saveConfig()
  end
  
  -- Item Icon (preview)
  local itemPreview = g_ui.createWidget('UIItem', row1)
  itemPreview:setSize({width = 24, height = 24})
  itemPreview:setMarginLeft(10)
  itemPreview:setVirtual(true)
  if slot.itemId and slot.itemId > 0 then
    itemPreview:setItemId(slot.itemId)
  end
  
  local itemIdInput = g_ui.createWidget('TextEdit', row1)
  itemIdInput:setWidth(60)
  itemIdInput:setText(slot.itemId and slot.itemId > 0 and tostring(slot.itemId) or "")
  itemIdInput:setMarginLeft(5)
  
  itemIdInput.onTextChange = function(widget, text)
    local id = tonumber(text) or 0
    MTCEquipment.config.slots[slotIndex].itemId = id
    MTCEquipment.saveConfig()
    -- Atualiza preview
    if id > 0 then
      itemPreview:setItemId(id)
    else
      itemPreview:setItemId(0)
    end
  end
  
  -- Linha 2: Condicao
  local row2 = g_ui.createWidget('Panel', slotPanel)
  row2:setLayout(UIHorizontalLayout.create(row2))
  row2:setHeight(22)
  row2:setMarginTop(3)
  
  local whenLabel = g_ui.createWidget('Label', row2)
  whenLabel:setText('Equipar quando')
  whenLabel:setColor('#888888')
  whenLabel:setWidth(95)
  
  local condCombo = g_ui.createWidget('ComboBox', row2)
  condCombo:setWidth(60)
  condCombo:addOption('Life')
  condCombo:addOption('Mana')
  condCombo:setCurrentOption(slot.condition == "life" and "Life" or "Mana")
  condCombo:setMarginLeft(5)
  
  condCombo.onOptionChange = function(widget, option)
    MTCEquipment.config.slots[slotIndex].condition = option:lower()
    MTCEquipment.saveConfig()
  end
  
  local lessLabel = g_ui.createWidget('Label', row2)
  lessLabel:setText('<=')
  lessLabel:setColor('#ffaa00')
  lessLabel:setWidth(20)
  lessLabel:setMarginLeft(5)
  
  local thresholdInput = g_ui.createWidget('TextEdit', row2)
  thresholdInput:setWidth(40)
  thresholdInput:setText(tostring(slot.threshold or 80))
  thresholdInput:setMarginLeft(5)
  
  thresholdInput.onTextChange = function(widget, text)
    local value = tonumber(text) or 80
    if value < 0 then value = 0 end
    if value > 100 then value = 100 end
    MTCEquipment.config.slots[slotIndex].threshold = value
    MTCEquipment.saveConfig()
  end
  
  local percentLabel = g_ui.createWidget('Label', row2)
  percentLabel:setText('%')
  percentLabel:setColor('#888888')
  percentLabel:setWidth(20)
  percentLabel:setMarginLeft(2)
  
  -- Linha 3: Info sobre remocao
  local row3 = g_ui.createWidget('Panel', slotPanel)
  row3:setLayout(UIHorizontalLayout.create(row3))
  row3:setHeight(16)
  row3:setMarginTop(2)
  
  local removeInfo = g_ui.createWidget('Label', row3)
  removeInfo:setText('(Remove automaticamente quando > ' .. tostring(slot.threshold or 80) .. '%)')
  removeInfo:setColor('#666666')
  removeInfo:setWidth(250)
  
  -- Atualiza texto quando threshold muda
  thresholdInput.onTextChange = function(widget, text)
    local value = tonumber(text) or 80
    if value < 0 then value = 0 end
    if value > 100 then value = 100 end
    MTCEquipment.config.slots[slotIndex].threshold = value
    MTCEquipment.saveConfig()
    removeInfo:setText('(Remove automaticamente quando > ' .. tostring(value) .. '%)')
  end
end

return MTCEquipment
