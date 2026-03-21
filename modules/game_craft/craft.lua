--[[
    Sistema de Craft - Cliente OTClient
    
    IMPORTANTE: As receitas são carregadas DINAMICAMENTE do servidor!
    Você só precisa editar no servidor (craft_visual.lua)
    O cliente recebe automaticamente as receitas atualizadas.
]]

local craftWindow = nil
local craftButton = nil
local selectedRecipe = nil
local selectedCategory = nil
local CRAFT_OPCODE = 217

-- Cache de dados do servidor (receitas e contagens)
local serverItemCounts = {}
local serverRecipes = {}      -- Receitas carregadas do servidor
local serverCategories = {}   -- Categorias carregadas do servidor

-- Funcao para obter contagem de item (usa cache do servidor)
local function getItemCount(itemId)
    if serverItemCounts[itemId] then
        return serverItemCounts[itemId]
    end
    return 0
end

function init()
    connect(g_game, { onGameStart = onGameStart, onGameEnd = onGameEnd })
    ProtocolGame.registerExtendedOpcode(CRAFT_OPCODE, parseOpcode)
    g_ui.importStyle('craft')
    if g_game.isOnline() then onGameStart() end
end

function terminate()
    disconnect(g_game, { onGameStart = onGameStart, onGameEnd = onGameEnd })
    ProtocolGame.unregisterExtendedOpcode(CRAFT_OPCODE)
    if craftWindow then craftWindow:destroy() craftWindow = nil end
    if craftButton then craftButton:destroy() craftButton = nil end
end

function onGameStart()
    if craftButton then craftButton:destroy() craftButton = nil end
    if modules.game_mainpanel and modules.game_mainpanel.addSpecialToggleButton then
        craftButton = modules.game_mainpanel.addSpecialToggleButton(
            'craftBtn', tr('Craft'), '/game_craft/images/craft_icon', toggleWindow, false, 98
        )
    end
end

function onGameEnd()
    if craftWindow then craftWindow:destroy() craftWindow = nil end
    if craftButton then craftButton:destroy() craftButton = nil end
    selectedRecipe = nil
    serverRecipes = {}
    serverCategories = {}
    serverItemCounts = {}
end

-- Processa mensagens do servidor
function parseOpcode(protocol, opcode, buffer)
    local ok, data = pcall(function() return json.decode(buffer) end)
    if not ok or not data then return end
    
    if data.action == "recipes" then
        -- Servidor enviou lista de receitas e categorias
        if data.categories then
            serverCategories = data.categories
        end
        if data.recipes then
            serverRecipes = data.recipes
        end
        -- Recarregar interface com dados do servidor
        loadCategoriesFromServer()
        
    elseif data.action == "itemCounts" then
        -- Servidor enviou contagens de itens
        if data.counts then
            for _, item in ipairs(data.counts) do
                serverItemCounts[item.itemId] = item.count
            end
            scheduleEvent(function() updateMaterials() end, 50)
        end
        
    elseif data.action == "result" then
        if data.success then
            if modules.game_textmessage then
                modules.game_textmessage.displayStatusMessage(data.message or "Item criado!")
            end
            requestItemCounts()
        else
            if modules.game_textmessage then
                modules.game_textmessage.displayFailureMessage(data.message or "Falha!")
            end
        end
    end
end

-- Solicita receitas ao servidor
function requestRecipes()
    local proto = g_game.getProtocolGame()
    if proto then
        proto:sendExtendedOpcode(CRAFT_OPCODE, json.encode({ action = "requestRecipes" }))
    end
end

-- Solicitar contagens de itens ao servidor
function requestItemCounts()
    if not selectedRecipe then return end
    
    local proto = g_game.getProtocolGame()
    if proto then
        local itemIds = {}
        for _, mat in ipairs(selectedRecipe.required) do
            table.insert(itemIds, mat.itemId)
        end
        proto:sendExtendedOpcode(CRAFT_OPCODE, json.encode({ action = "requestItemCounts", itemIds = itemIds }))
    end
end

function toggleWindow()
    if craftWindow and craftWindow:isVisible() then
        hide()
    else
        show()
    end
end

function show()
    if not craftWindow then
        craftWindow = g_ui.createWidget('CraftWindow', rootWidget)
    end
    if craftWindow then
        -- Limpar cache e solicitar dados frescos do servidor
        serverItemCounts = {}
        serverRecipes = {}
        serverCategories = {}
        
        -- Mostrar mensagem de carregamento
        local panel = craftWindow:recursiveGetChildById('recipePanel')
        if panel then
            panel:destroyChildren()
        end
        local statusLabel = craftWindow:recursiveGetChildById('statusLabel')
        if statusLabel then
            statusLabel:setText("Carregando receitas...")
            statusLabel:setColor('#ffff00')
        end
        
        craftWindow:show()
        craftWindow:raise()
        craftWindow:focus()
        
        -- Solicitar receitas do servidor
        requestRecipes()
    end
end

function hide()
    if craftWindow then craftWindow:hide() end
end

-- Carrega categorias recebidas do servidor
function loadCategoriesFromServer()
    if not craftWindow then return end
    
    local tabsPanel = craftWindow:recursiveGetChildById('tabsPanel')
    if tabsPanel then
        tabsPanel:destroyChildren()
        
        for _, cat in ipairs(serverCategories) do
            local tab = g_ui.createWidget('CraftTabButton', tabsPanel)
            tab:setText(cat.name)
            tab.categoryId = cat.id
            tab.onClick = function(w)
                onSelectCategory(w)
            end
        end
        
        -- Selecionar primeira categoria
        local firstTab = tabsPanel:getChildByIndex(1)
        if firstTab then
            scheduleEvent(function() onSelectCategory(firstTab) end, 50)
        end
    end
end

function onSelectCategory(widget)
    if not widget or not widget.categoryId then return end
    
    -- Desmarcar todas as tabs
    local tabsPanel = craftWindow:recursiveGetChildById('tabsPanel')
    if tabsPanel then
        for _, child in ipairs(tabsPanel:getChildren()) do
            child:setChecked(false)
        end
    end
    
    widget:setChecked(true)
    selectedCategory = widget.categoryId
    
    -- Carregar receitas da categoria
    loadRecipesByCategory(selectedCategory)
end

function loadRecipesByCategory(categoryId)
    if not craftWindow then return end
    local panel = craftWindow:recursiveGetChildById('recipePanel')
    if not panel then return end
    panel:destroyChildren()
    selectedRecipe = nil
    
    -- Usar receitas do servidor
    for _, r in ipairs(serverRecipes) do
        if r.category == categoryId then
            local btn = g_ui.createWidget('RecipeItem', panel)
            local itemWidget = btn:getChildById('item')
            if itemWidget then
                itemWidget:setItemId(r.result.itemId)
            end
            local nameLabel = btn:getChildById('nameLabel')
            if nameLabel then
                nameLabel:setText(r.name)
            end
            btn.recipe = r
            btn.onClick = function(w)
                onSelectRecipe(w)
            end
        end
    end
    
    -- Seleciona primeiro item
    local first = panel:getChildByIndex(1)
    if first then
        scheduleEvent(function() onSelectRecipe(first) end, 50)
    else
        -- Limpar painel direito se nao tem receitas
        local resultItem = craftWindow:recursiveGetChildById('resultItem')
        local resultName = craftWindow:recursiveGetChildById('resultName')
        local materialsPanel = craftWindow:recursiveGetChildById('materialsPanel')
        local statusLabel = craftWindow:recursiveGetChildById('statusLabel')
        local craftBtn = craftWindow:recursiveGetChildById('craftBtn')
        
        if resultItem then resultItem:setItemId(0) end
        if resultName then resultName:setText("Nenhuma receita") end
        if materialsPanel then materialsPanel:destroyChildren() end
        if statusLabel then statusLabel:setText("") end
        if craftBtn then craftBtn:setEnabled(false) end
    end
end

function onSelectRecipe(widget)
    if not widget or not widget.recipe then return end
    
    -- Desmarcar todos
    local panel = craftWindow:recursiveGetChildById('recipePanel')
    if panel then
        for _, child in ipairs(panel:getChildren()) do
            child:setChecked(false)
        end
    end
    
    widget:setChecked(true)
    selectedRecipe = widget.recipe
    
    local resultItem = craftWindow:recursiveGetChildById('resultItem')
    local resultName = craftWindow:recursiveGetChildById('resultName')
    
    if resultItem then
        resultItem:setItemId(selectedRecipe.result.itemId)
    end
    if resultName then
        resultName:setText(selectedRecipe.name)
    end
    
    -- Solicitar contagens atualizadas do servidor
    requestItemCounts()
    
    -- Atualizar com dados locais enquanto espera
    updateMaterials()
end

function updateMaterials()
    if not craftWindow or not selectedRecipe then return end
    
    local panel = craftWindow:recursiveGetChildById('materialsPanel')
    if not panel then return end
    panel:destroyChildren()
    
    local canCraft = true
    
    for _, mat in ipairs(selectedRecipe.required) do
        local w = g_ui.createWidget('MaterialItem', panel)
        local itemBg = w:getChildById('itemBg')
        local item = itemBg and itemBg:getChildById('item') or w:getChildById('item')
        local nameLabel = w:getChildById('nameLabel')
        local qty = w:getChildById('qty')
        
        if item then item:setItemId(mat.itemId) end
        
        -- Usar contagem do servidor
        local has = getItemCount(mat.itemId)
        
        -- Usar nome enviado pelo servidor (se disponível) ou buscar localmente
        local itemName = mat.name or ("Item #" .. mat.itemId)
        if not mat.name or mat.name == "" then
            local itemType = g_things.getThingType(mat.itemId, ThingCategoryItem)
            if itemType then
                local marketData = itemType:getMarketData()
                if marketData and marketData.name and marketData.name ~= "" then
                    itemName = marketData.name
                end
            end
        end
        
        if nameLabel then
            nameLabel:setText(itemName)
        end
        
        if qty then
            local qtyText = tostring(has) .. " / " .. tostring(mat.count)
            qty:setText(qtyText)
            if has >= mat.count then
                qty:setColor('#00ff00')
            else
                qty:setColor('#ff4444')
                canCraft = false
            end
        end
        
        -- Tooltip
        local tooltipText = itemName .. "\nNecessario: " .. mat.count
        if item then
            item:setTooltip(tooltipText)
        end
        w:setTooltip(tooltipText)
    end
    
    local craftBtn = craftWindow:recursiveGetChildById('craftBtn')
    local statusLabel = craftWindow:recursiveGetChildById('statusLabel')
    
    if craftBtn then craftBtn:setEnabled(canCraft) end
    if statusLabel then
        if canCraft then
            statusLabel:setText("Pronto para criar!")
            statusLabel:setColor('#00ff00')
        else
            statusLabel:setText("Faltam materiais")
            statusLabel:setColor('#ff4444')
        end
    end
end

function doCraft()
    if not selectedRecipe then return end
    local proto = g_game.getProtocolGame()
    if proto then
        proto:sendExtendedOpcode(CRAFT_OPCODE, json.encode({ action = "craft", recipeId = selectedRecipe.id }))
    end
end
