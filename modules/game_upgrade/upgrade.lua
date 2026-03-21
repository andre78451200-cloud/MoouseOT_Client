--[[
    Sistema de Upgrade Visual - Cliente OTClient
    Opcode: 218
    
    Interface visual para upgrade de equipamentos
    Similar ao sistema de Craft
]]

local upgradeWindow = nil
local transferWindow = nil
local upgradeButton = nil
local selectedEquipment = nil
local selectedBonus = nil
local selectedTransferBonuses = {}  -- Agora é uma lista de bônus selecionados
local selectedDestEquipment = nil
local UPGRADE_OPCODE = 218

-- Cache de dados do servidor
local serverItems = {}
local serverStoneId = 52215
local serverStoneName = "Upgrade Stone"
local serverStoneCount = 0

function init()
    connect(g_game, { onGameStart = onGameStart, onGameEnd = onGameEnd })
    ProtocolGame.registerExtendedOpcode(UPGRADE_OPCODE, parseOpcode)
    g_ui.importStyle('upgrade')
    if g_game.isOnline() then onGameStart() end
end

function terminate()
    disconnect(g_game, { onGameStart = onGameStart, onGameEnd = onGameEnd })
    ProtocolGame.unregisterExtendedOpcode(UPGRADE_OPCODE)
    destroyWindow()
    if upgradeButton then upgradeButton:destroy() upgradeButton = nil end
end

function destroyWindow()
    if upgradeWindow then
        upgradeWindow:destroy()
        upgradeWindow = nil
    end
    if transferWindow then
        transferWindow:destroy()
        transferWindow = nil
    end
    selectedEquipment = nil
    selectedBonus = nil
    selectedTransferBonus = nil
    selectedDestEquipment = nil
end

function onGameStart()
    if upgradeButton then upgradeButton:destroy() upgradeButton = nil end
    if modules.game_mainpanel and modules.game_mainpanel.addSpecialToggleButton then
        upgradeButton = modules.game_mainpanel.addSpecialToggleButton(
            'upgradeBtn', tr('Upgrade'), '/game_upgrade/images/upgrade_btn', toggle, false, 98
        )
    end
end

function onGameEnd()
    destroyWindow()
    if upgradeButton then upgradeButton:destroy() upgradeButton = nil end
    serverItems = {}
    selectedTransferBonuses = {}
    selectedDestEquipment = nil
end

function parseOpcode(protocol, opcode, buffer)
    local status, data = pcall(json.decode, buffer)
    if not status or not data then 
        return 
    end
    
    if data.action == "open" then
        -- Recebeu lista de itens upgradeáveis
        serverItems = data.items or {}
        serverStoneId = data.stoneId or 52215
        serverStoneName = data.stoneName or "Upgrade Stone"
        serverStoneCount = data.stoneCount or 0
        
        -- Garantir que a janela existe antes de carregar os itens
        if not upgradeWindow then
            upgradeWindow = g_ui.createWidget('UpgradeWindow', rootWidget)
        end
        
        if upgradeWindow then
            upgradeWindow:show()
            upgradeWindow:raise()
            upgradeWindow:focus()
            if upgradeButton then
                upgradeButton:setOn(true)
            end
            loadEquipmentList()
        end
        
    elseif data.action == "itemInfo" then
        -- Recebeu informações de bônus do item
        if data.bonuses then
            serverStoneCount = data.stoneCount or serverStoneCount
            loadBonusList(data.bonuses, data.currentLevel or 0)
        end
        
    elseif data.action == "updateStones" then
        -- Atualizar contagem de pedras
        serverStoneCount = data.count or 0
        updateCostDisplay()
        
    elseif data.action == "upgradeResult" then
        -- Resultado do upgrade
        if data.success then
            displayMessage("Upgrade realizado com sucesso!", "#00ff00")
        else
            displayMessage(data.message or "Falha no upgrade!", "#ff4444")
        end
        -- Solicitar atualização dos itens
        requestItems()
        
    elseif data.action == "transferResult" then
        -- Resultado da transferência
        if data.success then
            displayTransferMessage("Transferencia realizada com sucesso!", "#00ff00")
            -- Fechar janela de transferência e atualizar
            scheduleEvent(function()
                closeTransferMode()
                requestItems()
            end, 1500)
        else
            displayTransferMessage(data.message or "Falha na transferencia!", "#ff4444")
        end
        
    elseif data.action == "error" then
        displayMessage(data.message or "Erro!", "#ff4444")
    end
end

function toggle()
    if upgradeWindow and upgradeWindow:isVisible() then
        hide()
    else
        show()
    end
end

function show()
    if not upgradeWindow then
        upgradeWindow = g_ui.createWidget('UpgradeWindow', rootWidget)
    end
    
    if upgradeWindow then
        upgradeWindow:show()
        upgradeWindow:raise()
        upgradeWindow:focus()
        requestItems()
    end
    
    if upgradeButton then
        upgradeButton:setOn(true)
    end
end

function hide()
    if upgradeWindow then
        upgradeWindow:hide()
    end
    if upgradeButton then
        upgradeButton:setOn(false)
    end
end

function requestItems()
    local proto = g_game.getProtocolGame()
    if proto then
        proto:sendExtendedOpcode(UPGRADE_OPCODE, json.encode({ action = "requestItems" }))
    end
end

function requestItemInfo(slotPath)
    local proto = g_game.getProtocolGame()
    if proto then
        proto:sendExtendedOpcode(UPGRADE_OPCODE, json.encode({ 
            action = "requestItemInfo",
            slotPath = slotPath
        }))
    end
end

function loadEquipmentList()
    if not upgradeWindow then 
        return 
    end
    
    local panel = upgradeWindow:recursiveGetChildById('equipmentPanel')
    if not panel then 
        return 
    end
    
    panel:destroyChildren()
    selectedEquipment = nil
    clearSelection()
    
    if #serverItems == 0 then
        -- Mostrar label de "sem equipamento"
        local noEquipLabel = upgradeWindow:recursiveGetChildById('noEquipmentLabel')
        if noEquipLabel then
            noEquipLabel:setVisible(true)
        end
        return
    else
        -- Esconder label de "sem equipamento"
        local noEquipLabel = upgradeWindow:recursiveGetChildById('noEquipmentLabel')
        if noEquipLabel then
            noEquipLabel:setVisible(false)
        end
    end
    
    for i, itemData in ipairs(serverItems) do
        local widget = g_ui.createWidget('EquipmentItem', panel)
        if not widget then
            return
        end
        
        widget.itemData = itemData
        
        local itemWidget = widget:getChildById('item')
        if itemWidget then
            itemWidget:setItemId(itemData.itemId)
        end
        
        local nameLabel = widget:getChildById('nameLabel')
        if nameLabel then
            nameLabel:setText(itemData.name)
        end
        
        local levelLabel = widget:getChildById('levelLabel')
        if levelLabel then
            if itemData.level and itemData.level > 0 then
                levelLabel:setText("+" .. itemData.level)
            else
                levelLabel:setText("")
            end
        end
        
        widget.onClick = function(self)
            selectEquipment(self)
        end
    end
end

function selectEquipment(widget)
    if not upgradeWindow then return end
    
    -- Desmarcar anterior
    local panel = upgradeWindow:recursiveGetChildById('equipmentPanel')
    if panel then
        for _, child in ipairs(panel:getChildren()) do
            if child.setChecked then
                child:setChecked(false)
            end
        end
    end
    
    -- Marcar novo
    widget:setChecked(true)
    selectedEquipment = widget.itemData
    selectedBonus = nil
    
    -- Atualizar painel direito
    updateSelectedItemDisplay()
    
    -- Solicitar informações de bônus do servidor usando slotPath
    if selectedEquipment and selectedEquipment.slotPath then
        requestItemInfo(selectedEquipment.slotPath)
    end
end

function updateSelectedItemDisplay()
    if not upgradeWindow then return end
    
    local itemWidget = upgradeWindow:recursiveGetChildById('selectedItem')
    local nameLabel = upgradeWindow:recursiveGetChildById('selectedItemName')
    local levelLabel = upgradeWindow:recursiveGetChildById('selectedItemLevel')
    local bonusPanel = upgradeWindow:recursiveGetChildById('bonusPanel')
    local costPanel = upgradeWindow:recursiveGetChildById('costPanel')
    local chanceLabel = upgradeWindow:recursiveGetChildById('chanceLabel')
    local upgradeBtn = upgradeWindow:recursiveGetChildById('upgradeBtn')
    
    if selectedEquipment then
        if itemWidget then
            itemWidget:setItemId(selectedEquipment.itemId)
        end
        if nameLabel then
            nameLabel:setText(selectedEquipment.name)
        end
        if levelLabel then
            local lvl = selectedEquipment.level or 0
            if lvl > 0 then
                levelLabel:setText("Nivel atual: +" .. lvl)
            else
                levelLabel:setText("Sem upgrades")
            end
        end
    else
        if itemWidget then
            itemWidget:setItemId(0)
        end
        if nameLabel then
            nameLabel:setText("Selecione um equipamento")
        end
        if levelLabel then
            levelLabel:setText("")
        end
    end
    
    -- Limpar painéis
    if bonusPanel then
        bonusPanel:destroyChildren()
    end
    if costPanel then
        costPanel:destroyChildren()
    end
    if chanceLabel then
        chanceLabel:setText("")
    end
    if upgradeBtn then
        upgradeBtn:setEnabled(false)
    end
end

function loadBonusList(bonuses, currentLevel)
    if not upgradeWindow then return end
    
    -- Atualizar o label de nível com o valor recebido do servidor
    local levelLabel = upgradeWindow:recursiveGetChildById('selectedItemLevel')
    if levelLabel then
        if currentLevel and currentLevel > 0 then
            levelLabel:setText("Nivel atual: +" .. currentLevel)
        else
            levelLabel:setText("Sem upgrades")
        end
    end
    
    -- Atualizar o nível no selectedEquipment para manter sincronizado
    if selectedEquipment then
        selectedEquipment.level = currentLevel or 0
    end
    
    local bonusPanel = upgradeWindow:recursiveGetChildById('bonusPanel')
    if not bonusPanel then return end
    
    bonusPanel:destroyChildren()
    selectedBonus = nil
    
    -- Verificar se tem algum bônus para transferir
    local hasTransferableBonus = false
    
    for _, bonus in ipairs(bonuses) do
        local widget = g_ui.createWidget('BonusItem', bonusPanel)
        widget.bonusData = bonus
        
        local nameLabel = widget:getChildById('nameLabel')
        if nameLabel then
            nameLabel:setText(bonus.label)
        end
        
        local levelLabel = widget:getChildById('levelLabel')
        if levelLabel then
            local current = bonus.current or 0
            local cap = bonus.cap or 10
            levelLabel:setText(current .. "/" .. cap)
            
            -- Verificar se pode transferir (tem algum ponto)
            if current > 0 then
                hasTransferableBonus = true
            end
            
            -- Cor baseada no progresso
            if current >= cap then
                levelLabel:setColor('#ffaa00') -- Máximo
                widget:setEnabled(false)
                widget:setOpacity(0.6)
            elseif current > 0 then
                levelLabel:setColor('#00ff00') -- Tem algum
            else
                levelLabel:setColor('#cccccc') -- Zero
            end
        end
        
        widget.onClick = function(self)
            if self.bonusData.current < self.bonusData.cap then
                selectBonus(self)
            end
        end
    end
    
    -- Habilitar/desabilitar botão de transferência
    local transferBtn = upgradeWindow:recursiveGetChildById('transferBtn')
    if transferBtn then
        transferBtn:setEnabled(hasTransferableBonus)
    end
end

function selectBonus(widget)
    if not upgradeWindow then return end
    
    -- Desmarcar anterior
    local bonusPanel = upgradeWindow:recursiveGetChildById('bonusPanel')
    if bonusPanel then
        for _, child in ipairs(bonusPanel:getChildren()) do
            if child.setChecked then
                child:setChecked(false)
            end
        end
    end
    
    -- Marcar novo
    widget:setChecked(true)
    selectedBonus = widget.bonusData
    
    -- Atualizar display de custo
    updateCostDisplay()
end

function updateCostDisplay()
    if not upgradeWindow then return end
    
    local costPanel = upgradeWindow:recursiveGetChildById('costPanel')
    local chanceLabel = upgradeWindow:recursiveGetChildById('chanceLabel')
    local upgradeBtn = upgradeWindow:recursiveGetChildById('upgradeBtn')
    
    if not costPanel then return end
    
    costPanel:destroyChildren()
    
    if not selectedBonus then
        if chanceLabel then
            chanceLabel:setText("Selecione um atributo para ver o custo")
        end
        if upgradeBtn then
            upgradeBtn:setEnabled(false)
        end
        return
    end
    
    local stonesRequired = selectedBonus.stonesRequired or 0
    local chance = selectedBonus.chance or 0
    
    -- Criar widget de material
    local materialWidget = g_ui.createWidget('MaterialItem', costPanel)
    
    local itemBg = materialWidget:getChildById('itemBg')
    if itemBg then
        local itemWidget = itemBg:getChildById('item')
        if itemWidget then
            itemWidget:setItemId(serverStoneId)
        end
    end
    
    local nameLabel = materialWidget:getChildById('nameLabel')
    if nameLabel then
        nameLabel:setText(serverStoneName)
    end
    
    local qtyLabel = materialWidget:getChildById('qty')
    if qtyLabel then
        qtyLabel:setText(serverStoneCount .. "/" .. stonesRequired)
        if serverStoneCount >= stonesRequired then
            qtyLabel:setColor('#00ff00')
        else
            qtyLabel:setColor('#ff4444')
        end
    end
    
    -- Chance
    if chanceLabel then
        chanceLabel:setText("Chance de sucesso: " .. chance .. "%")
        if chance >= 80 then
            chanceLabel:setColor('#00ff00')
        elseif chance >= 50 then
            chanceLabel:setColor('#ffff00')
        else
            chanceLabel:setColor('#ff8800')
        end
    end
    
    -- Habilitar botão se tiver recursos
    if upgradeBtn then
        upgradeBtn:setEnabled(serverStoneCount >= stonesRequired)
    end
end

function clearSelection()
    if not upgradeWindow then return end
    
    local itemWidget = upgradeWindow:recursiveGetChildById('selectedItem')
    local nameLabel = upgradeWindow:recursiveGetChildById('selectedItemName')
    local levelLabel = upgradeWindow:recursiveGetChildById('selectedItemLevel')
    local bonusPanel = upgradeWindow:recursiveGetChildById('bonusPanel')
    local costPanel = upgradeWindow:recursiveGetChildById('costPanel')
    local chanceLabel = upgradeWindow:recursiveGetChildById('chanceLabel')
    local upgradeBtn = upgradeWindow:recursiveGetChildById('upgradeBtn')
    
    if itemWidget then itemWidget:setItemId(0) end
    if nameLabel then nameLabel:setText("Selecione um equipamento") end
    if levelLabel then levelLabel:setText("") end
    if bonusPanel then bonusPanel:destroyChildren() end
    if costPanel then costPanel:destroyChildren() end
    if chanceLabel then chanceLabel:setText("") end
    if upgradeBtn then upgradeBtn:setEnabled(false) end
end

function displayMessage(message, color)
    if not upgradeWindow then return end
    
    local chanceLabel = upgradeWindow:recursiveGetChildById('chanceLabel')
    if chanceLabel then
        chanceLabel:setText(message)
        chanceLabel:setColor(color or '#ffffff')
    end
end

function doUpgrade()
    if not selectedEquipment or not selectedBonus then
        displayMessage("Selecione um equipamento e um atributo!", "#ff4444")
        return
    end
    
    local proto = g_game.getProtocolGame()
    if proto then
        proto:sendExtendedOpcode(UPGRADE_OPCODE, json.encode({
            action = "doUpgrade",
            slotPath = selectedEquipment.slotPath,
            bonusKey = selectedBonus.key
        }))
    end
end

-- =============================================================================
-- FUNÇÕES DE TRANSFERÊNCIA
-- =============================================================================

-- Cache dos bônus do item origem para a janela de transferência
local sourceItemBonuses = {}

function openTransferMode()
    if not selectedEquipment then
        displayMessage("Selecione um equipamento primeiro!", "#ff4444")
        return
    end
    
    -- Verificar se o item tem bônus para transferir
    local bonusPanel = upgradeWindow:recursiveGetChildById('bonusPanel')
    if not bonusPanel then return end
    
    local hasBonus = false
    sourceItemBonuses = {}
    
    for _, child in ipairs(bonusPanel:getChildren()) do
        if child.bonusData and child.bonusData.current and child.bonusData.current > 0 then
            hasBonus = true
            table.insert(sourceItemBonuses, child.bonusData)
        end
    end
    
    if not hasBonus then
        displayMessage("Este item não tem bônus para transferir!", "#ff4444")
        return
    end
    
    -- Criar janela de transferência
    if not transferWindow then
        transferWindow = g_ui.createWidget('TransferWindow', rootWidget)
    end
    
    if transferWindow then
        transferWindow:show()
        transferWindow:raise()
        transferWindow:focus()
        
        -- Configurar item origem
        setupSourceItem()
        
        -- Carregar lista de destinos compatíveis
        loadDestinationList()
        
        -- Reset seleções
        selectedTransferBonuses = {}
        selectedDestEquipment = nil
        updateTransferButton()
    end
end

function closeTransferMode()
    if transferWindow then
        transferWindow:hide()
        -- Limpar displays
        clearTransferWindow()
    end
    selectedTransferBonuses = {}
    selectedDestEquipment = nil
    sourceItemBonuses = {}
end

function clearTransferWindow()
    if not transferWindow then return end
    
    -- Limpar item origem
    local sourceItem = transferWindow:recursiveGetChildById('sourceItem')
    local sourceItemName = transferWindow:recursiveGetChildById('sourceItemName')
    if sourceItem then sourceItem:setItemId(0) end
    if sourceItemName then sourceItemName:setText("") end
    
    -- Limpar item destino
    local destItem = transferWindow:recursiveGetChildById('destItem')
    local destItemName = transferWindow:recursiveGetChildById('destItemName')
    local destItemBg = transferWindow:recursiveGetChildById('destItemBg')
    if destItem then destItem:setItemId(0) end
    if destItemName then 
        destItemName:setText("Selecione o destino")
        destItemName:setColor('#888888')
    end
    if destItemBg then destItemBg:setBorderColor('#555555') end
    
    -- Limpar painéis
    local transferBonusPanel = transferWindow:recursiveGetChildById('transferBonusPanel')
    local destEquipmentPanel = transferWindow:recursiveGetChildById('destEquipmentPanel')
    if transferBonusPanel then transferBonusPanel:destroyChildren() end
    if destEquipmentPanel then destEquipmentPanel:destroyChildren() end
    
    -- Limpar mensagem
    local bottomPanel = transferWindow:recursiveGetChildById('bottomPanel')
    if bottomPanel then
        local msgLabel = bottomPanel:getChildById('transferMessage')
        if msgLabel then msgLabel:destroy() end
    end
    
    -- Desabilitar botão
    local confirmBtn = transferWindow:recursiveGetChildById('confirmTransferBtn')
    if confirmBtn then confirmBtn:setEnabled(false) end
end

function setupSourceItem()
    if not transferWindow or not selectedEquipment then return end
    
    local sourceItem = transferWindow:recursiveGetChildById('sourceItem')
    local sourceItemName = transferWindow:recursiveGetChildById('sourceItemName')
    
    if sourceItem then
        sourceItem:setItemId(selectedEquipment.itemId)
    end
    
    if sourceItemName then
        local lvl = selectedEquipment.level or 0
        if lvl > 0 then
            sourceItemName:setText(selectedEquipment.name .. " +" .. lvl)
        else
            sourceItemName:setText(selectedEquipment.name)
        end
    end
    
    -- Carregar bônus transferíveis
    loadTransferBonusList()
end

function loadTransferBonusList()
    if not transferWindow then return end
    
    local bonusPanel = transferWindow:recursiveGetChildById('transferBonusPanel')
    if not bonusPanel then return end
    
    bonusPanel:destroyChildren()
    selectedTransferBonuses = {}
    
    for _, bonus in ipairs(sourceItemBonuses) do
        if bonus.current and bonus.current > 0 then
            local widget = g_ui.createWidget('BonusItem', bonusPanel)
            widget.bonusData = bonus
            widget.isSelected = false
            
            local nameLabel = widget:getChildById('nameLabel')
            if nameLabel then
                nameLabel:setText(bonus.label)
            end
            
            local levelLabel = widget:getChildById('levelLabel')
            if levelLabel then
                levelLabel:setText(bonus.current .. "/" .. bonus.cap)
                levelLabel:setColor('#00ff00')
            end
            
            -- Clique alterna seleção (toggle)
            widget.onClick = function(self)
                toggleTransferBonus(self)
            end
        end
    end
end

function toggleTransferBonus(widget)
    if not transferWindow then return end
    
    widget.isSelected = not widget.isSelected
    widget:setChecked(widget.isSelected)
    
    if widget.isSelected then
        -- Adicionar à lista
        table.insert(selectedTransferBonuses, widget.bonusData)
    else
        -- Remover da lista
        for i, bonus in ipairs(selectedTransferBonuses) do
            if bonus.key == widget.bonusData.key then
                table.remove(selectedTransferBonuses, i)
                break
            end
        end
    end
    
    updateTransferButton()
end

function selectTransferBonus(widget)
    -- Mantido para compatibilidade, mas agora usa toggle
    toggleTransferBonus(widget)
end

function loadDestinationList()
    if not transferWindow then return end
    
    local destPanel = transferWindow:recursiveGetChildById('destEquipmentPanel')
    if not destPanel then return end
    
    destPanel:destroyChildren()
    selectedDestEquipment = nil
    
    -- Filtrar itens compatíveis (mesma categoria, excluindo o item origem)
    local sourceCategory = selectedEquipment.category
    
    for _, itemData in ipairs(serverItems) do
        -- Não mostrar o item origem como destino
        if itemData.itemId ~= selectedEquipment.itemId or itemData.name ~= selectedEquipment.name then
            -- Verificar se é da mesma categoria (mesmo tipo de equipamento pode receber)
            if itemData.category == sourceCategory then
                local widget = g_ui.createWidget('EquipmentItem', destPanel)
                widget.itemData = itemData
                
                local itemWidget = widget:getChildById('item')
                if itemWidget then
                    itemWidget:setItemId(itemData.itemId)
                end
                
                local nameLabel = widget:getChildById('nameLabel')
                if nameLabel then
                    nameLabel:setText(itemData.name)
                end
                
                local levelLabel = widget:getChildById('levelLabel')
                if levelLabel then
                    if itemData.level and itemData.level > 0 then
                        levelLabel:setText("+" .. itemData.level)
                    else
                        levelLabel:setText("")
                    end
                end
                
                widget.onClick = function(self)
                    selectDestEquipment(self)
                end
            end
        end
    end
    
    -- Mensagem se não houver destinos
    if #destPanel:getChildren() == 0 then
        local label = g_ui.createWidget('Label', destPanel)
        label:setText("Nenhum item\ncompativel encontrado")
        label:setColor('#888888')
        label:setTextAlign(AlignCenter)
    end
end

function selectDestEquipment(widget)
    if not transferWindow then return end
    
    -- Desmarcar anterior
    local destPanel = transferWindow:recursiveGetChildById('destEquipmentPanel')
    if destPanel then
        for _, child in ipairs(destPanel:getChildren()) do
            if child.setChecked then
                child:setChecked(false)
            end
        end
    end
    
    -- Marcar novo
    widget:setChecked(true)
    selectedDestEquipment = widget.itemData
    
    -- Atualizar display do destino
    local destItem = transferWindow:recursiveGetChildById('destItem')
    local destItemName = transferWindow:recursiveGetChildById('destItemName')
    local destItemBg = transferWindow:recursiveGetChildById('destItemBg')
    
    if destItem then
        destItem:setItemId(selectedDestEquipment.itemId)
    end
    
    if destItemName then
        local lvl = selectedDestEquipment.level or 0
        if lvl > 0 then
            destItemName:setText(selectedDestEquipment.name .. " +" .. lvl)
        else
            destItemName:setText(selectedDestEquipment.name)
        end
        destItemName:setColor('#ffffff')
    end
    
    if destItemBg then
        destItemBg:setBorderColor('#c8a020')
    end
    
    updateTransferButton()
end

function updateTransferButton()
    if not transferWindow then return end
    
    local confirmBtn = transferWindow:recursiveGetChildById('confirmTransferBtn')
    if confirmBtn then
        local canTransfer = #selectedTransferBonuses > 0 and selectedDestEquipment ~= nil
        confirmBtn:setEnabled(canTransfer)
        
        -- Atualizar texto do botão com quantidade
        if #selectedTransferBonuses > 1 then
            confirmBtn:setText("Transferir " .. #selectedTransferBonuses .. " Atributos")
        else
            confirmBtn:setText("Confirmar Transferencia")
        end
    end
end

function displayTransferMessage(message, color)
    if not transferWindow then return end
    
    -- Criar ou atualizar mensagem na janela de transferência
    local bottomPanel = transferWindow:recursiveGetChildById('bottomPanel')
    if bottomPanel then
        local msgLabel = bottomPanel:getChildById('transferMessage')
        if not msgLabel then
            msgLabel = g_ui.createWidget('Label', bottomPanel)
            msgLabel:setId('transferMessage')
            msgLabel:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
            msgLabel:addAnchor(AnchorTop, 'parent', AnchorTop)
            msgLabel:setMarginTop(5)
            msgLabel:setFont('verdana-11px-rounded')
        end
        msgLabel:setText(message)
        msgLabel:setColor(color or '#ffffff')
    end
end

function doTransfer()
    if not selectedEquipment or #selectedTransferBonuses == 0 or not selectedDestEquipment then
        displayTransferMessage("Selecione os atributos e o item destino!", "#ff4444")
        return
    end
    
    -- Criar lista de keys dos bônus selecionados
    local bonusKeys = {}
    for _, bonus in ipairs(selectedTransferBonuses) do
        table.insert(bonusKeys, bonus.key)
    end
    
    local proto = g_game.getProtocolGame()
    if proto then
        proto:sendExtendedOpcode(UPGRADE_OPCODE, json.encode({
            action = "doTransfer",
            sourceSlotPath = selectedEquipment.slotPath,
            destSlotPath = selectedDestEquipment.slotPath,
            bonusKeys = bonusKeys  -- Agora envia lista de keys
        }))
    end
end
