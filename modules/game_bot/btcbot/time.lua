--[[
  BTC Bot - Modulo Time (Uso Temporizado de Itens)
  
  Permite configurar ate 5 itens para serem usados automaticamente
  em intervalos de tempo definidos pelo jogador.
  
  Exemplo: Usar food a cada 60s, usar um item especial a cada 120s, etc.
]]

BTCTime = BTCTime or {}

-- Configuracao padrao: 5 slots de item temporizado
BTCTime.defaultConfig = {
  enabled = false,
  slots = {
    { enabled = false, itemId = 0, interval = 60, name = "" },
    { enabled = false, itemId = 0, interval = 60, name = "" },
    { enabled = false, itemId = 0, interval = 60, name = "" },
    { enabled = false, itemId = 0, interval = 60, name = "" },
    { enabled = false, itemId = 0, interval = 60, name = "" },
  }
}

-- Timers de controle (ultimo uso de cada slot em milissegundos)
BTCTime.lastUseTime = { 0, 0, 0, 0, 0 }

-- Config atual
BTCTime.config = nil

-- Inicializa o modulo
function BTCTime.init()
  BTCTime.config = BTCTime.loadConfig()
  BTCTime.lastUseTime = { 0, 0, 0, 0, 0 }
end

-- Carrega configuracao salva ou usa padrao
function BTCTime.loadConfig()
  local saved = BTCConfig.get("time")
  if saved then
    -- Garantir que tem 5 slots
    if not saved.slots then
      saved.slots = BTCTime.defaultConfig.slots
    end
    while #saved.slots < 5 do
      table.insert(saved.slots, { enabled = false, itemId = 0, interval = 60, name = "" })
    end
    return saved
  end
  -- Retorna copia do default
  local cfg = {
    enabled = false,
    slots = {}
  }
  for i = 1, 5 do
    cfg.slots[i] = { enabled = false, itemId = 0, interval = 60, name = "" }
  end
  return cfg
end

-- Salva configuracao
function BTCTime.saveConfig()
  BTCConfig.set("time", BTCTime.config)
end

-- Encontra e usa um item pelo ID no inventario/containers do jogador
function BTCTime.useItemById(itemId)
  if not g_game.isOnline() then return false end
  local player = g_game.getLocalPlayer()
  if not player then return false end

  -- Tenta encontrar o item nos containers abertos
  for _, container in pairs(g_game.getContainers()) do
    for slot = 0, container:getSize() - 1 do
      local item = container:getItem(slot)
      if item and item:getId() == itemId then
        g_game.useInventoryItem(itemId)
        return true
      end
    end
  end

  -- Tenta usar direto como inventory item (slots de equipamento)
  g_game.useInventoryItem(itemId)
  return true
end

-- Loop de execucao principal (chamado pelo BTCBot.execute)
function BTCTime.execute()
  if not BTCTime.config or not BTCTime.config.enabled then return end
  if not g_game.isOnline() then return end

  local now = g_clock.millis()

  for i = 1, 5 do
    local slot = BTCTime.config.slots[i]
    if slot and slot.enabled and slot.itemId and slot.itemId > 0 and slot.interval and slot.interval > 0 then
      local intervalMs = slot.interval * 1000 -- Converter segundos para milissegundos
      local lastUse = BTCTime.lastUseTime[i] or 0

      if (now - lastUse) >= intervalMs then
        -- Tentar usar o item
        local success = BTCTime.useItemById(slot.itemId)
        if success then
          BTCTime.lastUseTime[i] = now
        end
      end
    end
  end
end

-- ===================== UI =====================

function BTCTime.createUI(parent)
  parent:destroyChildren()

  -- Descricao
  local descLabel = g_ui.createWidget('Label', parent)
  descLabel:setText('Use itens automaticamente em intervalos de tempo.')
  descLabel:setColor('#888888')
  descLabel:setHeight(16)
  descLabel:setMarginTop(5)
  descLabel:setMarginBottom(5)

  -- 5 slots de item
  for i = 1, 5 do
    BTCTime.createSlotUI(parent, i)
  end

  -- Dicas de IDs
  local tipsLabel = g_ui.createWidget('Label', parent)
  tipsLabel:setText('IDs: Brown Mushroom=3725 | Meat=3577 | Fish=3578 | Mana Potion=268')
  tipsLabel:setColor('#666666')
  tipsLabel:setHeight(16)
  tipsLabel:setMarginTop(10)
end

function BTCTime.createSlotUI(parent, slotIndex)
  local slot = BTCTime.config.slots[slotIndex]
  if not slot then return end

  -- Painel de fundo escuro para cada slot
  local slotPanel = g_ui.createWidget('Panel', parent)
  slotPanel:setLayout(UIVerticalLayout.create(slotPanel))
  slotPanel:setHeight(60)
  slotPanel:setMarginTop(5)
  slotPanel:setBackgroundColor('#1a1a1a')
  slotPanel:setPadding(5)

  -- Linha 1: Checkbox + Icone do Item + Input de ID
  local row1 = g_ui.createWidget('Panel', slotPanel)
  row1:setLayout(UIHorizontalLayout.create(row1))
  row1:setHeight(26)

  local enableCheck = g_ui.createWidget('CheckBox', row1)
  enableCheck:setText('Slot ' .. slotIndex)
  enableCheck:setChecked(slot.enabled)
  enableCheck:setWidth(60)
  enableCheck.onCheckChange = function(widget, checked)
    BTCTime.config.slots[slotIndex].enabled = checked
    BTCTime.saveConfig()
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
  itemIdInput:setWidth(65)
  itemIdInput:setText(slot.itemId and slot.itemId > 0 and tostring(slot.itemId) or "")
  itemIdInput:setMarginLeft(5)

  itemIdInput.onTextChange = function(widget, text)
    local id = tonumber(text) or 0
    BTCTime.config.slots[slotIndex].itemId = id
    BTCTime.saveConfig()
    -- Atualiza preview do icone
    if id > 0 then
      itemPreview:setItemId(id)
    else
      itemPreview:setItemId(0)
    end
  end

  -- Label "a cada"
  local everyLabel = g_ui.createWidget('Label', row1)
  everyLabel:setText(' a cada')
  everyLabel:setColor('#888888')
  everyLabel:setWidth(45)
  everyLabel:setMarginLeft(8)

  -- Input de tempo em segundos
  local timeInput = g_ui.createWidget('TextEdit', row1)
  timeInput:setWidth(45)
  timeInput:setText(tostring(slot.interval))
  timeInput:setMarginLeft(3)

  -- Label "seg"
  local secLabel = g_ui.createWidget('Label', row1)
  secLabel:setText('seg')
  secLabel:setColor('#888888')
  secLabel:setWidth(25)
  secLabel:setMarginLeft(3)

  timeInput.onTextChange = function(widget, text)
    local newInterval = tonumber(text) or 60
    if newInterval < 1 then newInterval = 1 end
    BTCTime.config.slots[slotIndex].interval = newInterval
    BTCTime.saveConfig()
    -- Atualiza info de tempo
    local mins = math.floor(newInterval / 60)
    local secs = newInterval % 60
    if mins > 0 then
      timeInfoLabel:setText('(' .. tostring(mins) .. 'min ' .. tostring(secs) .. 's)')
    else
      timeInfoLabel:setText('(' .. tostring(secs) .. 's)')
    end
  end

  -- Linha 2: Info de tempo formatado
  local row2 = g_ui.createWidget('Panel', slotPanel)
  row2:setLayout(UIHorizontalLayout.create(row2))
  row2:setHeight(16)
  row2:setMarginTop(2)

  timeInfoLabel = g_ui.createWidget('Label', row2)
  timeInfoLabel:setColor('#666666')
  timeInfoLabel:setWidth(250)
  local mins = math.floor(slot.interval / 60)
  local secs = slot.interval % 60
  if mins > 0 then
    timeInfoLabel:setText('Usa automaticamente a cada ' .. tostring(mins) .. 'min ' .. tostring(secs) .. 's')
  else
    timeInfoLabel:setText('Usa automaticamente a cada ' .. tostring(secs) .. 's')
  end
end

return BTCTime
