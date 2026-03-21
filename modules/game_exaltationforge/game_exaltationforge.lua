Forge = {}


Forge.resourceTypes = {
    ["money"] = 0,
	["dust"] = 70,
	["sliver"] = 71,
	["core"] = 72 
}


Forge.colors = {
    enough = "#C0C0C0",
	missing = "#D33C3C"
}

ACTION_FUSION_TYPE = 0
ACTION_TRANSFER_TYPE = 1
ACTION_DUST_TO_SILVER = 2
ACTION_SILVER_TO_CORE = 3
ACTION_INCREASE_DUST_LIMIT = 4

local Fusion = nil
local Transfer = nil
local Conversion = nil
local History = nil
function init()
    -- Inicializar dustLevel com valor padrão (será atualizado quando usar a Forge física)
    if not Forge.dustLevel then
        Forge.dustLevel = 0  -- Será atualizado pelo servidor quando abrir a Forge física
    end
    
    Forge.mainButton = modules.game_mainpanel.addToggleButton("forgeButton", tr("Exaltation Forge"),
            "/images/options/forge", function() Forge:displayPreview() end, false, 17)

    Forge.mainButton:setOn(false)
		
    Forge.mainWindow = g_ui.displayUI("game_exaltationforge")
	Forge.mainWindow:setId("forge")
	Forge.mainWindow:setVisible(false)
	Forge.firstTooltip = Forge.mainWindow:getChildById('firstTooltip')
	Forge.secondTooltip = Forge.mainWindow:getChildById('secondTooltip')
	Forge.goldBalancePanel = Forge.mainWindow:getChildById('goldBalancePanel')
	Forge.goldBalanceValue = Forge.goldBalancePanel:getChildById('value')
	Forge.dustBalancePanel = Forge.mainWindow:getChildById('dustBalancePanel')
	Forge.dustBalanceValue = Forge.dustBalancePanel:getChildById('value')
	Forge.sliverBalancePanel = Forge.mainWindow:getChildById('sliverBalancePanel')
	Forge.sliverBalanceValue = Forge.sliverBalancePanel:getChildById('value')	
	Forge.coreBalancePanel = Forge.mainWindow:getChildById('coreBalancePanel')
	Forge.coreBalanceValue = Forge.coreBalancePanel:getChildById('value')
	
	local closeWidget = Forge.mainWindow:getChildById('close')
    closeWidget.onClick = function(self)
	    Forge.mainWindow:setVisible(false)
		Forge.mainButton:setOn(false)
	end
	
	Fusion = Forge.Fusion:get()
	Transfer = Forge.Transfer:get()
	Conversion = Forge.Conversion:get()
	History = Forge.History:get()
	
	
	Forge.Fusion:createButton()
	Forge.Transfer:createButton()
	Forge.Conversion:createButton()
	Forge.History:createButton()
	
	
	
	connect(g_game, {
        onOpenExaltationForge = onOpenExaltationForge,
		onResultExaltationForge = onResultExaltationForge,
		onItemClasses = onPlayerResourcesChange,
		onForgeHistory = onForgeHistory,
		onResourceBalance = onResourceBalance,
		onGameEnd = function() Forge:close() end
    })
end

function onResourceBalance(resourceType, value)
    -- Atualiza os recursos quando recebe do servidor
    -- resourceType 70 = FORGE_DUST, 71 = SLIVER, 72 = CORES
    Forge:updateResources()
    
    -- Se a janela de Conversion estiver visível, atualiza ela também
    if Conversion and Conversion.mainWindow and Conversion.mainWindow:isVisible() then
        -- Força atualização dos widgets de conversion baseado nos recursos atuais
        if Forge.data and Forge.data.config then
            Conversion:parseResourcesChange(Forge.data)
        end
    end
end

function Forge:updateResources()
    self.goldBalanceValue:setText(self:formatNumber(self:getResourceBalance('money')))
	local dustLevel = self.dustLevel or 0
	self.dustBalanceValue:setText(self:getResourceBalance('dust') .. "/" .. dustLevel)
    self.sliverBalanceValue:setText(self:getResourceBalance('sliver'))
	self.coreBalanceValue:setText(self:getResourceBalance('core'))
end

function Forge:close()
    self.mainWindow:setVisible(false)
	self.mainButton:setOn(false)
	if self.resultWindow then
	    self.resultWindow:setVisible(false)
		
	end
end

function Forge:get()
    return self
end

function Forge:displayPreview()
    -- Se a janela já está visível, fecha ela
    if self.mainWindow:isVisible() then
        self.mainWindow:setVisible(false)
        self.mainButton:setOn(false)
    else
        -- Envia comando ao servidor para abrir a Forge
        g_game.talk("/openforge")
    end
end

function Forge:formatNumber(n)
    if n >= 1000000000 then
        -- miliardy i więcej → w "kk"
        local value = math.floor(n / 1000000)  -- dzielimy przez milion
        local str = tostring(value)
        local result = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
        if result:sub(1,1) == "," then
            result = result:sub(2)
        end
        return result .. " kk"
    else
        -- poniżej miliarda → normalne formatowanie z przecinkami
        local str = tostring(n)
        local result = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
        if result:sub(1,1) == "," then
            result = result:sub(2)
        end
        return result
    end
end

function Forge:updateWidget(resourceType, widget, value, _disabled)
    local balance = Forge:getResourceBalance(resourceType)	
	value = tonumber(value)
	
	if balance >= value then
	    widget:setColor(Forge.colors.enough)
		if _disabled then
		    widget:setEnabled(false)
		end
	else
	    widget:setColor(Forge.colors.missing)
		if _disabled then
		    widget:setEnabled(true)
		end
	end
end

function Forge:setWidget(widget, value, boolean)
    widget:setText(value)
	if boolean then 
	    widget:setColor(Forge.colors.enough)
	else
	    widget:setColor(Forge.colors.missing)
	end
end

function Forge:getResourceBalance(str)
    local t = self.resourceTypes[str]
	if not t then
	    return 0
	end
	
	local player = g_game.getLocalPlayer()
	if not player then
	    return 0
    end
	
	if str == "money" then
	    return player:getTotalMoney()
	end		
	return player:getResourceBalance(t)
end

function Forge:ProcessFlash(item, widget, times, delay, startDelay, item2, widget2, descWidget, description, success)
	-- Sistema de animação do resultado do Forge
	-- Baseado no sistema do Mehah OTClient
	
	local eventCount = 0
	local maxEvents = 6
	local eventDelay = 750  -- 750ms entre cada evento (igual ao Mehah)
	
	-- Pega os widgets das setas
	local arrow1 = self.resultWindow:recursiveGetChildById('arrowsIcon1')
	local arrow2 = self.resultWindow:recursiveGetChildById('arrowsIcon2')
	local arrow3 = self.resultWindow:recursiveGetChildById('arrowsIcon3')
	
	local arrowEmpty = '/images/game/forge/icon-arrow-rightlarge'
	local arrowFilled = '/images/game/forge/icon-arrow-rightlarge-filled'
	
	-- Função para atualizar as setas baseado no eventCount
	local function updateArrows(count)
		if count == 1 then
			arrow1:setImageSource(arrowFilled)
			arrow2:setImageSource(arrowEmpty)
			arrow3:setImageSource(arrowEmpty)
		elseif count == 2 then
			arrow1:setImageSource(arrowFilled)
			arrow2:setImageSource(arrowFilled)
			arrow3:setImageSource(arrowEmpty)
		elseif count == 3 then
			arrow1:setImageSource(arrowFilled)
			arrow2:setImageSource(arrowFilled)
			arrow3:setImageSource(arrowFilled)
		elseif count == 4 then
			arrow1:setImageSource(arrowEmpty)
			arrow2:setImageSource(arrowFilled)
			arrow3:setImageSource(arrowFilled)
		elseif count == 5 then
			arrow1:setImageSource(arrowEmpty)
			arrow2:setImageSource(arrowEmpty)
			arrow3:setImageSource(arrowFilled)
		elseif count == 6 then
			arrow1:setImageSource(arrowEmpty)
			arrow2:setImageSource(arrowEmpty)
			arrow3:setImageSource(arrowEmpty)
		end
	end
	
	-- Função principal de animação
	local function runAnimation()
		eventCount = eventCount + 1
		
		if eventCount <= maxEvents then
			updateArrows(eventCount)
			
			-- Se chegou no evento 6, mostra o resultado
			if eventCount == 6 then
				-- Esconde o item da esquerda (donor)
				widget:setVisible(false)
				
				-- Mostra a mensagem de resultado
				descWidget:setColoredText(description)
				descWidget:setVisible(true)
				
				-- Efeito no item da direita baseado no sucesso/falha
				if success then
					-- Sucesso: mantém o item visível com cor normal
					widget2:setColor("white")
				else
					-- Falha: esconde o item após um delay
					widget2:setColor("#D33C3C")  -- Vermelho
					scheduleEvent(function()
						widget2:setVisible(false)
					end, 1000)
				end
			else
				-- Continua a animação
				scheduleEvent(runAnimation, eventDelay)
			end
		end
	end
	
	-- Inicia a animação após um pequeno delay
	scheduleEvent(function()
		runAnimation()
	end, 200)
end

function Forge:displayResult(actionType, convergence, success, leftItemId, rightItemId, leftTier, rightTier)
	if self.resultWindow then
	    self.resultWindow:destroy()
		self.resultWindow = nil
	end
    self.resultWindow = g_ui.displayUI("result")
	self.resultWindow:setVisible(false)
	local resultWindow = self.resultWindow
	
	local closeWidget = resultWindow:getChildById('close')
	closeWidget.onClick = function(widget)
	    resultWindow:setVisible(false)
		self.mainWindow:setVisible(true)
		if actionType == ACTION_TRANSFER_TYPE then
            Transfer:showWindow()	
        end			
	end
	
	if actionType == ACTION_FUSION_TYPE then
	    if convergence == 1 then
		    resultWindow:setText("Convergence Fusion Result")
		else
            resultWindow:setText("Fusion Result")
		end
		
		--success = false
		
		local text = "Your fusion attempt was {succesfull, #44AD25}."
		if not success then
		    text = "Your fusion attempt was {failed, #D33C3C}."
		end
		local descWidget = resultWindow:recursiveGetChildById('resultText')
		--descWidget:setColoredText(text)
		--descWidget:setVisible(true)
		
		local rightItem = Item.create(rightItemId)
		local rightWidget = resultWindow:recursiveGetChildById('previewItem2')
		rightItem:setTier(rightTier)
		rightWidget:setItem(rightItem)
		ItemsDatabase.setTier(rightWidget, rightItem)
		rightWidget:setColor("black")
		
		local leftWidget = resultWindow:recursiveGetChildById('previewItem1')
		local leftItem = Item.create(leftItemId)
		leftItem:setTier(leftTier)
        leftWidget:setItem(leftItem)
		ItemsDatabase.setTier(leftWidget, leftItem)
		
	    scheduleEvent(function() 
		    self:ProcessFlash(leftItem, leftWidget, 7, 200, false, rightItem, rightWidget, descWidget, text, success)
		end, 200)		       
	elseif actionType == ACTION_TRANSFER_TYPE then
	    if convergence == 1 then
		    resultWindow:setText("Convergence Tier Transfer Result")
		else
            resultWindow:setText("Transfer Result")
		end
		
		--success = false
		
		local text = "Your transfer was {succesfull, #44AD25}."
		if not success then
		    text = "Your transfer was {failed, #D33C3C}."
		end
		local descWidget = resultWindow:recursiveGetChildById('resultText')
		--descWidget:setColoredText(text)
		--descWidget:setVisible(true)
		
		local rightItem = Item.create(rightItemId)
		local rightWidget = resultWindow:recursiveGetChildById('previewItem2')
		rightItem:setTier(rightTier)
		rightWidget:setItem(rightItem)
		ItemsDatabase.setTier(rightWidget, rightItem)
		rightWidget:setColor("black")
		
		local leftWidget = resultWindow:recursiveGetChildById('previewItem1')
		local leftItem = Item.create(leftItemId)
		leftItem:setTier(leftTier)
        leftWidget:setItem(leftItem)
		ItemsDatabase.setTier(leftWidget, leftItem)
		
	    scheduleEvent(function() 
		    self:ProcessFlash(leftItem, leftWidget, 7, 200, false, rightItem, rightWidget, descWidget, text, success)
		end, 200)		
	end
	--self.mainWindow:setVisible(false)
	--self.mainWindow:setVisible(false)
    self.resultWindow:setVisible(true)
end

function onOpenExaltationForge(data)
    Forge.preview = false
	Forge.dustLevel = data.dustLevel
    Fusion:parseData(data)
	Transfer:parseData(data)
	Forge.mainButton:setOn(true)
	Forge:updateResources()
end

function onPlayerResourcesChange(data)
    Forge.data = data
	Forge:updateResources()
    Fusion:parseResourcesChange(data)
	Conversion:parseResourcesChange(data)	
end

function onResultExaltationForge(data)
    local success = nil
	if data.success == 1 then
	    success = true
	end
	
	scheduleEvent(function()
       Forge.mainWindow:setVisible(false)
    end, 10)
	
    Forge:displayResult(data.actionType, data.convergence, success, data.leftItemId, data.rightItemId, data.leftTier, data.rightTier)
	if data.actionType == ACTION_FUSION_TYPE then
	    Fusion:parseResult(data)
		return
	end
	if data.actionType == ACTION_TRANSFER_TYPE then
	    Transfer:parseResult(data)
	end
	return
end

function onForgeHistory(currentPage, lastPage, data)
    History:parse(currentPage, lastPage, data)
end

function terminate()
end