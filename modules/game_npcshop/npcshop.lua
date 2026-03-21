local NPCSHOP_OPCODE = 219
local npcShopWindow = nil
local npcShopButton = nil
local selectedCategory = "potions"
local selectedTab = "buy"
local selectedItem = nil
local playerItems = {}
local tradeItems = {}
local taskItems = {} -- Items for Task tab
local playerTotalMoney = 0
local playerMysticTokens = 0 -- Player's current Mystic Token count

-- Sell All cooldown
local sellAllCooldownEnd = 0
local sellAllCooldownEvent = nil

rawset(_G, 'NpcShopSellPrices', rawget(_G, 'NpcShopSellPrices') or {})

local categories = {}
local shopItems = {}
local shopDataLoaded = false

function init()
    connect(g_game, {
        onGameStart = onGameStart,
        onGameEnd = onGameEnd
    })
    ProtocolGame.registerExtendedOpcode(NPCSHOP_OPCODE, parseOpcode)
    if g_game.isOnline() then
        onGameStart()
    end
end

function terminate()
    disconnect(g_game, {
        onGameStart = onGameStart,
        onGameEnd = onGameEnd
    })
    ProtocolGame.unregisterExtendedOpcode(NPCSHOP_OPCODE)
    destroyWindow()
    if npcShopButton then
        npcShopButton:destroy()
        npcShopButton = nil
    end
end

function onGameStart()
    createButton()
end

function onGameEnd()
    destroyWindow()
    if npcShopButton then
        npcShopButton:destroy()
        npcShopButton = nil
    end
    -- Reset shop data so it's fetched again on next login
    shopDataLoaded = false
    categories = {}
    shopItems = {}
end

function destroyWindow()
    if npcShopWindow then
        npcShopWindow:destroy()
        npcShopWindow = nil
    end
end

function createButton()
    -- [COMENTADO] Botao do NPC Shop desativado temporariamente
    -- Pode ser reativado no futuro removendo os comentarios abaixo
    --[[
    if npcShopButton then
        npcShopButton:destroy()
        npcShopButton = nil
    end
    
    -- Criar botão customizado com altura maior (28px ao invés de 20px)
    local panel = modules.game_mainpanel.getStorePanel and modules.game_mainpanel.getStorePanel()
    if not panel and modules.game_mainpanel.optionsController then
        panel = modules.game_mainpanel.optionsController.ui.onPanel.store
    end
    
    if panel then
        npcShopButton = g_ui.createWidget('UIButton')
        npcShopButton:setId('npcShopBtn')
        npcShopButton:setSize({width = 108, height = 28})
        npcShopButton:setImageSource('/modules/game_npcshop/images/npcshop_large')
        npcShopButton:setImageClip({x = 0, y = 0, width = 108, height = 28})
        npcShopButton:setImageSize({width = 108, height = 28})
        npcShopButton:setTooltip(tr('NPC Shop'))
        npcShopButton:setPhantom(false)
        
        -- Efeito de pressed (muda o clip da imagem)
        npcShopButton.onMousePress = function(widget, mousePos, mouseButton)
            if widget:containsPoint(mousePos) and mouseButton ~= MouseMidButton then
                widget:setImageClip({x = 0, y = 28, width = 108, height = 28})
            end
        end
        
        npcShopButton.onMouseRelease = function(widget, mousePos, mouseButton)
            widget:setImageClip({x = 0, y = 0, width = 108, height = 28})
            if widget:containsPoint(mousePos) and mouseButton ~= MouseMidButton then
                toggle()
                return true
            end
        end
        
        panel:addChild(npcShopButton)
    elseif modules.game_mainpanel and modules.game_mainpanel.addStoreButton then
        -- Fallback para botão padrão
        npcShopButton = modules.game_mainpanel.addStoreButton(
            'npcShopBtn',
            tr('NPC Shop'),
            '/modules/game_npcshop/images/npcshop_large',
            toggle,
            false
        )
    end
    --]]
end

function toggle()
    if not g_game.isOnline() then return end
    if npcShopWindow and npcShopWindow:isVisible() then
        hide()
    else
        show()
    end
end

function show()
    if not npcShopWindow then
        npcShopWindow = g_ui.displayUI('npcshop')
    end
    if npcShopWindow then
        npcShopWindow:setVisible(true)
        npcShopWindow:raise()
        npcShopWindow:focus()
        
        -- Always reset state and request fresh data when opening
        selectedItem = nil
        selectedTab = 'buy'
        playerMysticTokens = 0
        clearDetails()
        
        -- Always request fresh shop data from server
        requestShopData()
    end
    if npcShopButton then
        npcShopButton:setOn(true)
    end
end

function hide()
    if npcShopWindow then
        npcShopWindow:setVisible(false)
    end
    if npcShopButton then
        npcShopButton:setOn(false)
    end
end

function setupWindow()
    if not npcShopWindow then return end
    local categoryBar = npcShopWindow:getChildById('categoryBar')
    if categoryBar then
        categoryBar:destroyChildren()
        for _, cat in ipairs(categories) do
            local widgetType = 'NPCCategoryTab'
            if cat.isTask then
                widgetType = 'NPCTaskTabButton'
            elseif cat.special then
                widgetType = 'NPCTradeTabButton'
            end
            local tab = g_ui.createWidget(widgetType, categoryBar)
            if tab then
                tab:setId('cat_' .. cat.id)
                tab:setText(cat.name)
                tab.categoryId = cat.id
                tab.onClick = function()
                    selectCategory(cat.id)
                end
            end
        end
    end
    scheduleEvent(function()
        selectCategory("trade")
    end, 50)
end

function selectCategory(catId)
    selectedCategory = catId
    selectedItem = nil
    if not npcShopWindow then return end
    local categoryBar = npcShopWindow:getChildById('categoryBar')
    if categoryBar then
        for _, child in ipairs(categoryBar:getChildren()) do
            if child.categoryId then
                child:setChecked(child.categoryId == catId)
            end
        end
    end
    
    local itemsLabel = npcShopWindow:getChildById('itemsLabel')
    local detailsPanel = npcShopWindow:getChildById('detailsPanel')
    local actionButton = detailsPanel and detailsPanel:getChildById('actionButton')
    local bottomPanel = npcShopWindow:getChildById('bottomPanel')
    local sellAllButton = bottomPanel and bottomPanel:getChildById('sellAllButton')
    local sellAllWarning = bottomPanel and bottomPanel:getChildById('sellAllWarning')
    local goldLabel = npcShopWindow:getChildById('goldLabel')
    
    if catId == "trade" then
        selectedTab = "trade"
        if itemsLabel then 
            itemsLabel:setText('Seus Itens Vendaveis:')
            itemsLabel:setColor('#e8c970')
        end
        if actionButton then actionButton:setText('Vender') end
        if sellAllButton then sellAllButton:setVisible(true) end
        if sellAllWarning then sellAllWarning:setVisible(true) end
        if goldLabel then 
            goldLabel:setText('Total: 0 gold')
            goldLabel:setColor('#ffcc00')
        end
        requestPlayerItems()
    elseif catId == "task" then
        selectedTab = "task"
        if itemsLabel then 
            itemsLabel:setText('Trocar por Mystic Tokens:')
            itemsLabel:setColor('#ff7700')
        end
        if actionButton then actionButton:setText('Trocar') end
        if sellAllButton then sellAllButton:setVisible(false) end
        if sellAllWarning then sellAllWarning:setVisible(false) end
        if goldLabel then 
            goldLabel:setVisible(true)
            goldLabel:setText('Mystic Tokens: ' .. playerMysticTokens)
            goldLabel:setColor('#ff7700')
        end
        requestTaskItems()
    else
        selectedTab = "buy"
        if itemsLabel then 
            itemsLabel:setText('Itens Disponiveis:')
            itemsLabel:setColor('#e8c970')
        end
        if actionButton then actionButton:setText('Comprar') end
        if sellAllButton then sellAllButton:setVisible(false) end
        if sellAllWarning then sellAllWarning:setVisible(false) end
        updateItemsList()
        updateGoldLabel()
    end
    clearDetails()
end

function setTab(tabName)
    selectedTab = tabName
    selectedItem = nil
    if not npcShopWindow then return end
    
    local tabBar = npcShopWindow:getChildById('tabBar')
    if not tabBar then return end
    local buyTab = tabBar:getChildById('buyTab')
    local sellTab = tabBar:getChildById('sellTab')
    local tradeTab = tabBar:getChildById('tradeTab')
    local detailsPanel = npcShopWindow:getChildById('detailsPanel')
    local actionButton = detailsPanel and detailsPanel:getChildById('actionButton')
    local categoryBar = npcShopWindow:getChildById('categoryBar')
    local itemsLabel = npcShopWindow:getChildById('itemsLabel')
    
    if buyTab then buyTab:setChecked(tabName == 'buy') end
    if sellTab then sellTab:setChecked(tabName == 'sell') end
    if tradeTab then tradeTab:setChecked(tabName == 'trade') end
    
    if actionButton then
        if tabName == 'buy' then
            actionButton:setText('Comprar')
        elseif tabName == 'sell' then
            actionButton:setText('Vender')
        else
            actionButton:setText('Vender')
        end
    end
    
    local catLabel = npcShopWindow:getChildById('categoryLabel')
    
    if itemsLabel then
        if tabName == 'trade' then
            itemsLabel:setText('Seus Itens Vendaveis:')
        else
            itemsLabel:setText('Itens Disponiveis:')
        end
    end
    
    local bottomPanel = npcShopWindow:getChildById('bottomPanel')
    local sellAllButton = bottomPanel and bottomPanel:getChildById('sellAllButton')
    local sellAllWarning = bottomPanel and bottomPanel:getChildById('sellAllWarning')
    if sellAllButton then
        sellAllButton:setVisible(tabName == 'trade')
    end
    if sellAllWarning then
        sellAllWarning:setVisible(tabName == 'trade')
    end
    
    if tabName == 'trade' then
        requestPlayerItems()
    else
        updateItemsList()
    end
    clearDetails()
end

function updateItemsList()
    if not npcShopWindow then return end
    local itemsList = npcShopWindow:getChildById('itemsList')
    if not itemsList then return end
    itemsList:destroyChildren()
    
    local items = {}
    if selectedTab == 'trade' then
        items = playerItems
    else
        items = shopItems[selectedCategory] or {}
    end
    
    for _, item in ipairs(items) do
        local price = 0
        if selectedTab == 'buy' then
            price = item.buyPrice or 0
        elseif selectedTab == 'sell' then
            price = item.sellPrice or 0
        else
            price = item.sellPrice or 0
        end
        
        if price and price > 0 then
            local widget = g_ui.createWidget('NPCShopItem', itemsList)
            if widget then
                local itemBg = widget:getChildById('itemBg')
                local itemWidget = itemBg and itemBg:getChildById('itemWidget')
                if itemWidget then
                    itemWidget:setItemId(item.id)
                    if item.count and item.count > 1 then
                        itemWidget:setItemCount(item.count)
                    end
                end
                local nameLabel = widget:getChildById('nameLabel')
                if nameLabel then
                    local displayName = item.name
                    if selectedTab == 'trade' and item.count and item.count > 1 then
                        displayName = item.name .. ' x' .. item.count
                    end
                    nameLabel:setText(displayName)
                end
                local priceLabel = widget:getChildById('priceLabel')
                if priceLabel then
                    if selectedTab == 'trade' and item.count and item.count > 1 then
                        priceLabel:setText(formatGold(price * item.count) .. ' gp')
                    else
                        priceLabel:setText(formatGold(price) .. ' gp')
                    end
                end
                widget.itemData = item
                widget.onClick = function()
                    selectItem(item)
                end
            end
        end
    end
end

-- Helper function to get sale price - SAME as Analyser:getSalePrice()
local function getAnalyserPrice(itemId, serverPrice)
    -- Handle coins specially - they have intrinsic value
    if itemId == 3031 then -- gold coin
        return 1
    elseif itemId == 3035 then -- platinum coin
        return 100
    elseif itemId == 3043 then -- crystal coin
        return 10000
    end
    
    -- Try to access Analyser's salePriceTable directly (already cached prices)
    local analyserModule = modules.game_analyser
    if analyserModule then
        local analyser = analyserModule.Analyser
        if analyser and analyser.salePriceTable and analyser.salePriceTable[itemId] then
            return analyser.salePriceTable[itemId]
        end
        -- Try calling getSalePrice if table doesn't have it
        if analyser and analyser.getSalePrice then
            local itemPtr = Item.create(itemId, 1)
            if itemPtr then
                local price = analyser:getSalePrice(itemPtr, itemId)
                if price and price > 0 then
                    return price
                end
            end
        end
    end
    
    -- Fallback: Try to create item and get price directly
    local itemPtr = Item.create(itemId, 1)
    if itemPtr then
        -- Try getMeanSalePrice first
        if itemPtr.getMeanSalePrice then
            local price = itemPtr:getMeanSalePrice() or 0
            if price > 0 then
                return price
            end
        end
        
        -- Fallback to getMeanPrice
        if itemPtr.getMeanPrice then
            local price = itemPtr:getMeanPrice() or 0
            if price > 0 then
                return price
            end
        end
    end
    
    -- Try g_things.getThingType for NPC data
    local internalData = g_things.getThingType(itemId, ThingCategoryItem)
    if internalData and internalData.getNpcSaleData then
        local npcData = internalData:getNpcSaleData()
        if npcData and npcData[1] then
            local data = npcData[1]
            if data.salePrice and data.salePrice > 0 then
                return data.salePrice
            end
            if data.buyPrice and data.buyPrice > 0 then
                return data.buyPrice
            end
        end
    end
    
    -- No price found
    return 0
end

function calculateTotalTradeValue()
    local total = 0
    if playerItems and #playerItems > 0 then
        for _, item in ipairs(playerItems) do
            local itemId = tonumber(item.id)
            local serverPrice = tonumber(item.sellPrice) or 0
            -- Use same price source as Loot Analyser, fallback to server
            local price = getAnalyserPrice(itemId, serverPrice)
            local count = tonumber(item.count) or 1
            total = total + (price * count)
        end
    end
    return total
end

function updateGoldLabel()
    if not npcShopWindow then return end
    local goldLabel = npcShopWindow:getChildById('goldLabel')
    if not goldLabel then return end
    
    if selectedCategory == "trade" then
        local totalValue = calculateTotalTradeValue()
        if totalValue > 0 then
            goldLabel:setText('Total: ' .. formatGold(totalValue) .. ' gold')
            goldLabel:setColor('#00ff00')
        else
            goldLabel:setText('Total: 0 gold')
            goldLabel:setColor('#ffcc00')
        end
    else
        goldLabel:setText('')
        goldLabel:setColor('#ffcc00')
    end
end

function updateTradeItemsList()
    if not npcShopWindow then return end
    local itemsList = npcShopWindow:getChildById('itemsList')
    if not itemsList then return end
    itemsList:destroyChildren()
    
    local totalValue = 0
    
    for _, item in ipairs(playerItems) do
        local itemId = tonumber(item.id)
        local serverPrice = tonumber(item.sellPrice) or 0
        -- Use same price source as Loot Analyser, fallback to server
        local price = getAnalyserPrice(itemId, serverPrice)
        local count = tonumber(item.count) or 1
        if price > 0 then
            totalValue = totalValue + (price * count)
            local widget = g_ui.createWidget('NPCShopItem', itemsList)
            if widget then
                local itemBg = widget:getChildById('itemBg')
                local itemWidget = itemBg and itemBg:getChildById('itemWidget')
                if itemWidget then
                    itemWidget:setItemId(item.id)
                    if count > 1 then
                        itemWidget:setItemCount(count)
                    end
                end
                local nameLabel = widget:getChildById('nameLabel')
                if nameLabel then
                    local displayName = item.name
                    if count > 1 then
                        displayName = item.name .. ' x' .. count
                    end
                    nameLabel:setText(displayName)
                end
                local priceLabel = widget:getChildById('priceLabel')
                if priceLabel then
                    local totalPrice = price * count
                    priceLabel:setText(formatGold(totalPrice) .. ' gp')
                end
                widget.itemData = item
                widget.onClick = function()
                    selectItem(item)
                end
            end
        end
    end
    
    local goldLabel = npcShopWindow:getChildById('goldLabel')
    if goldLabel then
        local txt = 'Total: '
        if totalValue >= 1000000 then
            txt = txt .. string.format('%.1fM', totalValue / 1000000)
        elseif totalValue >= 1000 then
            txt = txt .. string.format('%.1fK', totalValue / 1000)
        else
            txt = txt .. tostring(totalValue)
        end
        txt = txt .. ' gold'
        goldLabel:setText(txt)
        goldLabel:setColor('#00ff00')
    end
end

function selectItem(item)
    if not item then return end
    selectedItem = item
    if not npcShopWindow then return end
    local detailsPanel = npcShopWindow:getChildById('detailsPanel')
    if not detailsPanel then return end
    
    local selectedItemBg = detailsPanel:getChildById('selectedItemBg')
    local selectedItemWidget = selectedItemBg and selectedItemBg:getChildById('selectedItemWidget')
    local selectedItemName = detailsPanel:getChildById('selectedItemName')
    local selectedItemPrice = detailsPanel:getChildById('selectedItemPrice')
    local infoLabelPrice = detailsPanel:getChildById('infoLabelPrice')
    local infoLabelMoney = detailsPanel:getChildById('infoLabelMoney')
    local playerMoneyLabel = detailsPanel:getChildById('playerMoneyLabel')
    local quantityScroll = detailsPanel:getChildById('quantityScroll')
    local actionButton = detailsPanel:getChildById('actionButton')
    
    -- Show elements
    if selectedItemBg then selectedItemBg:setVisible(true) end
    if infoLabelPrice then infoLabelPrice:setVisible(true) end
    if selectedItemPrice then selectedItemPrice:setVisible(true) end
    if infoLabelMoney then infoLabelMoney:setVisible(selectedTab == 'buy') end
    if playerMoneyLabel then playerMoneyLabel:setVisible(selectedTab == 'buy') end
    if quantityScroll then quantityScroll:setVisible(true) end
    if actionButton then actionButton:setVisible(true) end
    
    -- Set item
    if selectedItemWidget then
        selectedItemWidget:setItemId(item.id)
    end
    if selectedItemName then
        selectedItemName:setText(item.name)
    end
    
    -- Get price
    local price = 0
    if selectedTab == 'buy' then
        price = item.buyPrice or 0
    else
        local itemId = tonumber(item.id)
        local serverPrice = tonumber(item.sellPrice) or 0
        price = getAnalyserPrice(itemId, serverPrice)
    end
    
    -- Update money label
    if playerMoneyLabel then
        playerMoneyLabel:setText(formatGold(playerTotalMoney) .. ' gold')
    end
    
    if actionButton then
        actionButton:setEnabled(true)
    end
    
    -- Calculate max quantity
    if quantityScroll then
        local maxQty = 100
        if selectedTab == 'trade' then
            -- For selling, limit to the amount the player has
            local itemCount = tonumber(item.count) or 1
            maxQty = math.max(1, itemCount)
        elseif selectedTab == 'buy' and price > 0 then
            -- For buying, limit by money
            local maxByMoney = math.floor(playerTotalMoney / price)
            maxQty = math.max(1, math.min(100, maxByMoney))
        end
        quantityScroll:setMinimum(1)
        quantityScroll:setMaximum(math.max(1, maxQty))
        quantityScroll:setValue(1)
    end
    
    -- Update total price display
    onQuantityChange(1)
end

function onQuantityChange(value)
    if not selectedItem or not npcShopWindow then return end
    
    -- If in task tab, use task-specific handler
    if selectedTab == 'task' then
        onTaskQuantityChange(value)
        return
    end
    
    local detailsPanel = npcShopWindow:getChildById('detailsPanel')
    if not detailsPanel then return end
    
    local selectedItemPrice = detailsPanel:getChildById('selectedItemPrice')
    
    local price = 0
    if selectedTab == 'buy' then
        price = selectedItem.buyPrice or 0
    else
        local itemId = tonumber(selectedItem.id)
        local serverPrice = tonumber(selectedItem.sellPrice) or 0
        price = getAnalyserPrice(itemId, serverPrice)
    end
    
    local totalPrice = price * value
    if selectedItemPrice then
        selectedItemPrice:setText(formatGold(totalPrice) .. ' gold')
    end
end

function clearDetails()
    selectedItem = nil
    if not npcShopWindow then return end
    local detailsPanel = npcShopWindow:getChildById('detailsPanel')
    if not detailsPanel then return end
    
    local selectedItemBg = detailsPanel:getChildById('selectedItemBg')
    local selectedItemWidget = selectedItemBg and selectedItemBg:getChildById('selectedItemWidget')
    local selectedItemName = detailsPanel:getChildById('selectedItemName')
    local selectedItemPrice = detailsPanel:getChildById('selectedItemPrice')
    local infoLabelPrice = detailsPanel:getChildById('infoLabelPrice')
    local infoLabelMoney = detailsPanel:getChildById('infoLabelMoney')
    local playerMoneyLabel = detailsPanel:getChildById('playerMoneyLabel')
    local quantityScroll = detailsPanel:getChildById('quantityScroll')
    local actionButton = detailsPanel:getChildById('actionButton')
    local rewardPanel = detailsPanel:getChildById('rewardPanel')
    
    if selectedItemBg then selectedItemBg:setVisible(false) end
    if infoLabelPrice then infoLabelPrice:setVisible(false) end
    if selectedItemPrice then selectedItemPrice:setVisible(false) end
    if infoLabelMoney then infoLabelMoney:setVisible(false) end
    if playerMoneyLabel then playerMoneyLabel:setVisible(false) end
    if quantityScroll then quantityScroll:setVisible(false) end
    if actionButton then actionButton:setVisible(false) end
    if rewardPanel then rewardPanel:setVisible(false) end
    
    if selectedItemWidget then selectedItemWidget:setItemId(0) end
    if selectedItemName then 
        selectedItemName:setText('Clique em um item para ver detalhes')
    end
end

function doAction()
    if not selectedItem then return end
    local detailsPanel = npcShopWindow:getChildById('detailsPanel')
    local quantityScroll = detailsPanel and detailsPanel:getChildById('quantityScroll')
    local quantity = quantityScroll and quantityScroll:getValue() or 1
    
    local data = {
        action = selectedTab,
        itemId = selectedItem.id,
        quantity = quantity,
        category = selectedCategory
    }
    
    if selectedTab == 'trade' then
        data.action = 'sell'
    elseif selectedTab == 'task' then
        data.action = 'taskSell'
    end
    
    sendToServer(data)
end

local function updateSellAllButton()
    if not npcShopWindow then return end
    local bottomPanel = npcShopWindow:getChildById('bottomPanel')
    local sellAllButton = bottomPanel and bottomPanel:getChildById('sellAllButton')
    if not sellAllButton then return end
    
    local currentTime = os.time()
    local remaining = sellAllCooldownEnd - currentTime
    
    if remaining > 0 then
        sellAllButton:setText('Aguarde: ' .. remaining .. 's')
        sellAllButton:setEnabled(false)
        sellAllButton:setColor('#ff4444')
        sellAllButton:setBackgroundColor('#442222')
        
        -- Schedule next update
        if sellAllCooldownEvent then
            removeEvent(sellAllCooldownEvent)
        end
        sellAllCooldownEvent = scheduleEvent(updateSellAllButton, 1000)
    else
        sellAllButton:setText('Sell All')
        sellAllButton:setEnabled(true)
        sellAllButton:setColor('#ffcc00')
        sellAllButton:setBackgroundColor('#3d3520')
        sellAllCooldownEnd = 0
        if sellAllCooldownEvent then
            removeEvent(sellAllCooldownEvent)
            sellAllCooldownEvent = nil
        end
    end
end

local function startSellAllCooldown(seconds)
    sellAllCooldownEnd = os.time() + seconds
    updateSellAllButton()
end

function doSellAll()
    -- Check if on cooldown
    local currentTime = os.time()
    local remaining = sellAllCooldownEnd - currentTime
    if remaining > 0 then
        modules.game_textmessage.displayFailureMessage('Aguarde ' .. remaining .. ' segundos para usar Sell All novamente.')
        return
    end
    
    if #playerItems == 0 then
        modules.game_textmessage.displayFailureMessage('Nenhum item para vender!')
        return
    end
    
    -- Use same total calculation as displayed (Analyser prices)
    local totalValue = calculateTotalTradeValue()
    local totalItemCount = 0
    for _, item in ipairs(playerItems) do
        totalItemCount = totalItemCount + (item.count or 1)
    end
    
    local confirmMsg = 'Vender TODOS os ' .. totalItemCount .. ' itens por aproximadamente ' .. formatGold(totalValue) .. ' gold?\n\n'
    confirmMsg = confirmMsg .. '[!] Cooldown: 1 minuto entre vendas.'
    
    local function doConfirmSellAll()
        sendToServer({ action = "sellAll" })
    end
    
    if modules.game_messageBox then
        local mbox = modules.game_messageBox.displayGeneralBox(
            'Confirmar Venda - Sell All',
            confirmMsg,
            { { text = 'Sim, Vender!', callback = function() doConfirmSellAll() end },
              { text = 'Cancelar', callback = function() end } },
            doConfirmSellAll,
            nil,
            nil
        )
    else
        doConfirmSellAll()
    end
end

function requestPlayerItems()
    sendToServer({ action = "getPlayerItems" })
end

function requestTaskItems()
    sendToServer({ action = "getTaskItems" })
end

function requestShopData()
    sendToServer({ action = "getShopData" })
end

-- Update Task items list (items player has that can be exchanged for tokens)
function updateTaskItemsList()
    if not npcShopWindow then return end
    local itemsList = npcShopWindow:getChildById('itemsList')
    if not itemsList then return end
    itemsList:destroyChildren()
    
    local totalTokens = 0
    
    for _, item in ipairs(taskItems) do
        local tokenPrice = tonumber(item.tokenPrice) or 0
        local count = tonumber(item.count) or 1
        if tokenPrice > 0 then
            totalTokens = totalTokens + (tokenPrice * count)
            local widget = g_ui.createWidget('NPCTaskShopItem', itemsList)
            if widget then
                local itemBg = widget:getChildById('itemBg')
                local itemWidget = itemBg and itemBg:getChildById('itemWidget')
                if itemWidget then
                    itemWidget:setItemId(item.id)
                    if count > 1 then
                        itemWidget:setItemCount(count)
                    end
                end
                local nameLabel = widget:getChildById('nameLabel')
                if nameLabel then
                    local displayName = item.name
                    if count > 1 then
                        displayName = item.name .. ' x' .. count
                    end
                    nameLabel:setText(displayName)
                end
                local priceLabel = widget:getChildById('priceLabel')
                if priceLabel then
                    local totalPrice = tokenPrice * count
                    if totalPrice > 1 then
                        priceLabel:setText(totalPrice .. ' tokens')
                    else
                        priceLabel:setText(totalPrice .. ' token')
                    end
                end
                widget.itemData = item
                widget.onClick = function()
                    selectTaskItem(item)
                end
            end
        end
    end
    
    local goldLabel = npcShopWindow:getChildById('goldLabel')
    if goldLabel then
        goldLabel:setVisible(true)
        goldLabel:setText('Mystic Tokens: ' .. playerMysticTokens)
        goldLabel:setColor('#ff7700')
    end
end

-- Select item in Task tab
function selectTaskItem(item)
    if not item then return end
    selectedItem = item
    if not npcShopWindow then return end
    local detailsPanel = npcShopWindow:getChildById('detailsPanel')
    if not detailsPanel then return end
    
    local selectedItemBg = detailsPanel:getChildById('selectedItemBg')
    local selectedItemWidget = selectedItemBg and selectedItemBg:getChildById('selectedItemWidget')
    local selectedItemName = detailsPanel:getChildById('selectedItemName')
    local selectedItemPrice = detailsPanel:getChildById('selectedItemPrice')
    local infoLabelPrice = detailsPanel:getChildById('infoLabelPrice')
    local infoLabelMoney = detailsPanel:getChildById('infoLabelMoney')
    local playerMoneyLabel = detailsPanel:getChildById('playerMoneyLabel')
    local quantityScroll = detailsPanel:getChildById('quantityScroll')
    local actionButton = detailsPanel:getChildById('actionButton')
    local rewardPanel = detailsPanel:getChildById('rewardPanel')
    local rewardItemBg = rewardPanel and rewardPanel:getChildById('rewardItemBg')
    local rewardItemWidget = rewardItemBg and rewardItemBg:getChildById('rewardItemWidget')
    local rewardCountLabel = rewardPanel and rewardPanel:getChildById('rewardCountLabel')
    
    -- Show elements
    if selectedItemBg then selectedItemBg:setVisible(true) end
    if infoLabelPrice then 
        infoLabelPrice:setVisible(true) 
        infoLabelPrice:setText('Mystic Tokens:')
    end
    if selectedItemPrice then 
        selectedItemPrice:setVisible(true) 
        selectedItemPrice:setColor('#ff7700')
    end
    if infoLabelMoney then 
        infoLabelMoney:setVisible(true) 
        infoLabelMoney:setText('Seus Mystic:')
    end
    if playerMoneyLabel then 
        playerMoneyLabel:setVisible(true)
        playerMoneyLabel:setText(playerMysticTokens .. ' tokens')
        playerMoneyLabel:setColor('#ff7700')
    end
    if quantityScroll then quantityScroll:setVisible(true) end
    if actionButton then 
        actionButton:setVisible(true)
        actionButton:setText('Trocar')
        actionButton:setEnabled(true)
    end
    
    -- Show reward panel with Mystic Token sprite
    if rewardPanel then rewardPanel:setVisible(true) end
    if rewardItemWidget then
        rewardItemWidget:setItemId(51962) -- Task Token ID
    end
    
    -- Set item
    if selectedItemWidget then
        selectedItemWidget:setItemId(item.id)
    end
    if selectedItemName then
        selectedItemName:setText(item.name)
    end
    
    -- Calculate max quantity
    if quantityScroll then
        local itemCount = tonumber(item.count) or 1
        local maxQty = math.max(1, itemCount)
        quantityScroll:setMinimum(1)
        quantityScroll:setMaximum(maxQty)
        quantityScroll:setValue(1)
    end
    
    -- Update total tokens display
    onTaskQuantityChange(1)
end

-- Handle quantity change in Task tab
function onTaskQuantityChange(value)
    if not selectedItem or not npcShopWindow then return end
    local detailsPanel = npcShopWindow:getChildById('detailsPanel')
    if not detailsPanel then return end
    
    local selectedItemPrice = detailsPanel:getChildById('selectedItemPrice')
    local tokenPrice = tonumber(selectedItem.tokenPrice) or 1
    local total = tokenPrice * value
    
    if selectedItemPrice then
        if total > 1 then
            selectedItemPrice:setText(total .. ' tokens')
        else
            selectedItemPrice:setText(total .. ' token')
        end
    end
    
    -- Update reward count label with total tokens to receive
    -- Try to find the label using recursive search
    local rewardCountLabel = detailsPanel:getChildById('rewardPanel') and detailsPanel:getChildById('rewardPanel'):getChildById('rewardCountLabel')
    if not rewardCountLabel then
        -- Fallback: try recursive search
        rewardCountLabel = detailsPanel:recursiveGetChildById('rewardCountLabel')
    end
    if rewardCountLabel then
        rewardCountLabel:setText('x' .. tostring(total))
    end
end

local function syncAnalyserPrices()
    local serverPrices = rawget(_G, 'NpcShopSellPrices') or {}
    if Analyser and Analyser.priceTable then
        for itemId, price in pairs(serverPrices) do
            if price > 0 then
                Analyser.priceTable[itemId] = price
            end
        end
    end
end

function parseOpcode(protocol, opcode, buffer)
    local status, data = pcall(function() return json.decode(buffer) end)
    if not status or not data then return end
    
    local serverPrices = rawget(_G, 'NpcShopSellPrices') or {}
    
    if data.action == 'shopData' then
        -- Receive categories and items from server
        categories = data.categories or {}
        shopItems = data.items or {}
        playerTotalMoney = data.playerMoney or 0
        playerMysticTokens = data.playerMysticTokens or 0 -- Update token count
        shopDataLoaded = true
        -- Setup window after receiving data
        if npcShopWindow then
            setupWindow()
            if selectedTab == 'trade' then
                requestPlayerItems()
            elseif selectedTab == 'task' then
                requestTaskItems()
            else
                updateItemsList()
            end
        end
    elseif data.action == 'playerItems' then
        playerItems = data.items or {}
        for _, item in ipairs(playerItems) do
            if item.id and item.sellPrice then
                serverPrices[item.id] = item.sellPrice
            end
        end
        rawset(_G, 'NpcShopSellPrices', serverPrices)
        syncAnalyserPrices()
        if selectedTab == 'trade' then
            updateTradeItemsList()
        end
    elseif data.action == 'taskItems' then
        -- Receive task sellable items
        taskItems = data.items or {}
        playerMysticTokens = data.playerTokens or 0
        if selectedTab == 'task' then
            updateTaskItemsList()
        end
    elseif data.action == 'taskResult' then
        -- Handle task sell result
        if data.success then
            modules.game_textmessage.displayStatusMessage(data.message or 'Troca realizada!')
            playerMysticTokens = data.playerTokens or playerMysticTokens
            if data.items then
                taskItems = data.items
                if selectedTab == 'task' then
                    updateTaskItemsList()
                    clearDetails()
                end
            end
        else
            modules.game_textmessage.displayFailureMessage(data.message or 'Falha na troca!')
        end
    elseif data.action == 'tradeList' then
        tradeItems = data.items or {}
        for _, item in ipairs(tradeItems) do
            if item.id and item.sellPrice then
                serverPrices[item.id] = item.sellPrice
            end
        end
        rawset(_G, 'NpcShopSellPrices', serverPrices)
        syncAnalyserPrices()
    elseif data.action == 'result' then
        if data.success then
            modules.game_textmessage.displayStatusMessage(data.message or 'Transacao realizada!')
            
            -- Update player money if server sent new balance
            if data.playerMoney then
                playerTotalMoney = data.playerMoney
            end
            
            -- Start cooldown timer if server sent cooldown info
            if data.cooldown and data.cooldown > 0 then
                startSellAllCooldown(data.cooldown)
            end
            
            if data.items then
                playerItems = data.items
                for _, item in ipairs(playerItems) do
                    if item.id and item.sellPrice then
                        serverPrices[item.id] = item.sellPrice
                    end
                end
                rawset(_G, 'NpcShopSellPrices', serverPrices)
                syncAnalyserPrices()
                if selectedTab == 'trade' then
                    updateTradeItemsList()
                    clearDetails()
                end
            end
            
            -- Re-select item to update max quantity slider
            if selectedItem and selectedTab == 'buy' then
                selectItem(selectedItem)
            end
        else
            modules.game_textmessage.displayFailureMessage(data.message or 'Falha na transacao!')
            
            -- Start cooldown if server sent remaining time
            if data.cooldown and data.cooldown > 0 then
                startSellAllCooldown(data.cooldown)
            end
        end
    end
end

function sendToServer(data)
    local protocolGame = g_game.getProtocolGame()
    if protocolGame then
        protocolGame:sendExtendedOpcode(NPCSHOP_OPCODE, json.encode(data))
    end
end

function formatGold(value)
    if not value then return '0' end
    value = tonumber(value) or 0
    if value >= 1000000 then
        return string.format('%.1fM', value / 1000000)
    elseif value >= 1000 then
        return string.format('%.1fK', value / 1000)
    end
    return tostring(math.floor(value))
end
