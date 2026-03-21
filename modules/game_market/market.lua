Market = {}

local protocol = runinsandbox('marketprotocol')

marketWindow = nil
mainTabBar = nil
displaysTabBar = nil
offersTabBar = nil
selectionTabBar = nil

marketOffersPanel = nil
browsePanel = nil
overviewPanel = nil
itemOffersPanel = nil
itemDetailsPanel = nil
itemStatsPanel = nil
myOffersPanel = nil
currentOffersPanel = nil
offerHistoryPanel = nil
marketHistoryPanel = nil
historySellList = nil
historyBuyList = nil
sellOffersLabel = nil
buyOffersLabel = nil
sellCancelOfferButton = nil
buyCancelOfferButton = nil
lastSelectedMySellWidget = nil
lastSelectedMyBuyWidget = nil
itemsPanel = nil
selectedOffer = {}
selectedMyOffer = {}
lastKnownTab = nil
lastOfferTab = nil

nameLabel = nil
feeLabel = nil
balanceLabel = nil
coinsLabel = nil

-- Obtém saldo de Tibia Coins NORMAIS a partir do Store UI ou do player
local function getNormalCoins()
  -- 1) Tenta via player resources
  local player = g_game.getLocalPlayer()
  if player and player.getResourceBalance then
    local v = player:getResourceBalance(ResourceTypes.COIN_NORMAL)
    if type(v) == 'number' and v >= 0 then
      return v
    end
  end

  -- 2) Fallback: lê do label de coins do store, se o UI estiver carregado
  if controllerShop and controllerShop.ui and controllerShop.ui.lblCoins then
    local lblCoins = controllerShop.ui.lblCoins.lblTibiaCoins
    if lblCoins and lblCoins.getText then
      local text = lblCoins:getText()
      if type(text) == 'string' and text ~= '' then
        local numberStr = text:match('%d[%d,]*')
        if numberStr then
          local cleanNumber = numberStr:gsub('[^%d]', '')
          local val = tonumber(cleanNumber)
          if val then return val end
        end
      end
    end
  end

  return 0
end

local function updateCoinsLabel()
  if not coinsLabel or not coinsLabel.setText then return end
  local normalCoins = getNormalCoins()
  coinsLabel:setText(convertGold(normalCoins or 0, true))
  if coinsLabel.resizeToText then coinsLabel:resizeToText() end
end

-- Reflete atualizações da Store no Market quando o label muda
local function attachStoreCoinsListener()
  if controllerShop and controllerShop.ui and controllerShop.ui.lblCoins then
    local lblCoins = controllerShop.ui.lblCoins.lblTibiaCoins
    if lblCoins and not lblCoins.__marketCoinsHooked then
      lblCoins.__marketCoinsHooked = true
      lblCoins.onTextChange = function()
        updateCoinsLabel()
      end
    end
  end
end
totalPriceEdit = nil
piecePriceEdit = nil
amountEdit = nil
searchEdit = nil
radioItemSet = nil
selectedItem = nil
offerTypeList = nil
categoryList = nil
subCategoryList = nil
slotFilterList = nil
createOfferButton = nil
buyButton = nil
sellButton = nil
anonymous = nil
filterButtons = {}

buyOfferTable = nil
sellOfferTable = nil
detailsTable = nil
buyStatsTable = nil
sellStatsTable = nil

buyCancelButton = nil
sellCancelButton = nil
buyMyOfferTable = nil
sellMyOfferTable = nil

buyMyHistoryTable = nil
sellMyHistoryTable = nil

refreshTimeout = 0
updateEvent = nil
offerExhaust = {}
marketOffers = {}
marketItems = {}
information = {}
currentItems = {}
lastCreatedOffer = 0
fee = 0
averagePrice = 0

-- Buffer de ofertas recebidas via streaming (onMarketReadOffer)
-- No backup/market.lua isso é inicializado para evitar erros ao usar table.insert.
-- Sem essa inicialização, a primeira oferta lida gera erro e nenhuma lista é preenchida.
MarketOffers2 = {}
-- Buffer para ofertas em leitura streaming


-- Track last auto-browsed item to avoid duplicate requests
lastAutoBrowseItemId = 0

loaded = false

-- Compat (t_market.lua): lembrar último item/tier navegados
local lastItemID = 0
local lastItemTier = 0

-- Actions for new create-offer UI
local currentActionType = 0 -- 0: Buy, 1: Sell

local function getMainMarket()
    if not marketWindow then return nil end
    -- Priorize explicit main container ids
    local main = marketWindow:recursiveGetChildById('mainMarket')
        or marketWindow:recursiveGetChildById('MarketMainWindow')
    if main then return main end
    -- Fallback para layout novo: painel principal é 'contentPanel'
    local content = marketWindow:recursiveGetChildById('contentPanel')
    if content then
        -- Log para confirmar caminho em UIs sem 'mainMarket'
        return content
    end
    return nil
end

local function initMarketHistoryUI()
    if not marketWindow then return end
    marketHistoryPanel = marketWindow:recursiveGetChildById('MarketHistory')
    if not marketHistoryPanel then return end

    local currentOffers = marketHistoryPanel:getChildById('currentOffers')
    if not currentOffers then return end

    historySellList = currentOffers:recursiveGetChildById('sellOffersList')
    historyBuyList = currentOffers:recursiveGetChildById('buyOffersList')
    sellOffersLabel = currentOffers:getChildById('sellOffersLabel')
    buyOffersLabel = currentOffers:getChildById('buyOffersLabel')
    sellCancelOfferButton = currentOffers:getChildById('sellCancelOffer')
    buyCancelOfferButton = currentOffers:getChildById('buyCancelOffer')

    if sellCancelOfferButton then
        sellCancelOfferButton:setEnabled(false)
        sellCancelOfferButton.onClick = function()
            cancelMyOffer(MarketAction.Sell)
        end
    end
    if buyCancelOfferButton then
        buyCancelOfferButton:setEnabled(false)
        buyCancelOfferButton.onClick = function()
            cancelMyOffer(MarketAction.Buy)
        end
    end

    -- Selection helpers using per-widget click handlers; safer across UI implementations
    local function selectSellWidget(w)
        if not w then return end
        if lastSelectedMySellWidget then
            lastSelectedMySellWidget:setBackgroundColor(lastSelectedMySellWidget:getId())
            for _, cid in ipairs({'piecePrice','totalPrice','name','amount','endAt'}) do
                local cw = lastSelectedMySellWidget:getChildById(cid)
                if cw then cw:setColor('#c0c0c0') end
            end
        end
        lastSelectedMySellWidget = w
        w:setBackgroundColor('#585858')
        for _, cid in ipairs({'piecePrice','totalPrice','name','amount','endAt'}) do
            local cw = w:getChildById(cid)
            if cw then cw:setColor('#f4f4f4') end
        end
        selectedMyOffer[MarketAction.Sell] = w.offer
        if sellCancelOfferButton then sellCancelOfferButton:setEnabled(true) end
    end

    local function selectBuyWidget(w)
        if not w then return end
        if lastSelectedMyBuyWidget then
            lastSelectedMyBuyWidget:setBackgroundColor(lastSelectedMyBuyWidget:getId())
            for _, cid in ipairs({'piecePrice','totalPrice','name','amount','endAt'}) do
                local cw = lastSelectedMyBuyWidget:getChildById(cid)
                if cw then cw:setColor('#c0c0c0') end
            end
        end
        lastSelectedMyBuyWidget = w
        w:setBackgroundColor('#585858')
        for _, cid in ipairs({'piecePrice','totalPrice','name','amount','endAt'}) do
            local cw = w:getChildById(cid)
            if cw then cw:setColor('#f4f4f4') end
        end
        selectedMyOffer[MarketAction.Buy] = w.offer
        if buyCancelOfferButton then buyCancelOfferButton:setEnabled(true) end
    end

    -- expose selectors for use when creating widgets
    Market.selectSellWidget = selectSellWidget
    Market.selectBuyWidget = selectBuyWidget
end

-- Handlers to support new OTUI create-offer widgets
function changeOfferType(widget, primary)
    local main = getMainMarket()
    if not main or not widget then return end
    -- Enforce mutual exclusivity: always set one and unset the other
    if primary then
        local sellCheck = main:getChildById('createOfferSell')
        if sellCheck then sellCheck:setChecked(true) end
        local buyCheck = main:getChildById('createOfferBuy')
        if buyCheck then buyCheck:setChecked(false) end
        currentActionType = 1
        local gp = main:getChildById('grossProfit')
        if gp then gp:setText(tr('Gross Profit:')) end
        local pl = main:getChildById('profitLabel')
        if pl then pl:setText(tr('Total Profit:')) end
    else
        local sellCheck = main:getChildById('createOfferSell')
        if sellCheck then sellCheck:setChecked(false) end
        local buyCheck = main:getChildById('createOfferBuy')
        if buyCheck then buyCheck:setChecked(true) end
        currentActionType = 0
        local gp = main:getChildById('grossProfit')
        if gp then gp:setText(tr('Price:')) end
        local pl = main:getChildById('profitLabel')
        if pl then pl:setText(tr('Total Price:')) end
    end

    local priceEdit = main:getChildById('piecePriceCreate')
    if priceEdit and priceEdit.clearText then priceEdit:clearText() end
    local btn = main:getChildById('createButton')
    if btn then btn:setEnabled(false) end
end

function updateCreateCount(widget, value)
    local main = getMainMarket()
    if not main then return end
    local step = 1
    if widget and widget.getStep then step = widget:getStep() end
    if step and step > 1 then
        value = math.max(step, math.floor(value / step + 0.5) * step)
    end
    local amtLabel = main:getChildById('createOfferAmount')
    if amtLabel then amtLabel:setText('Amount: ' .. value) end
    -- Avoid recursion: compute totals directly based on current price text
    local priceEdit = main:getChildById('piecePriceCreate')
    local text = priceEdit and priceEdit:getText() or ''
    local currentText = text:gsub('[^%d]', '')
    local numericValue = tonumber(currentText)
    if not numericValue or numericValue <= 0 or value <= 0 then
        local grossAmount = main:getChildById('grossAmount')
        if grossAmount then grossAmount:setText('0'); grossAmount.value = 0 end
        local profitAmount = main:getChildById('profitAmount')
        if profitAmount then profitAmount:setText('0') end
        local feeAmount = main:getChildById('feeAmount')
        if feeAmount then feeAmount:setText('0') end
        local btn = main:getChildById('createButton')
        if btn then btn:setEnabled(false) end
        return
    end

    local feeLocal = math.ceil((numericValue / 100) * value)
    if feeLocal < 20 then
        feeLocal = 20
    elseif feeLocal > 1000 then
        feeLocal = 1000
    end

    local grossProfit = numericValue * value
    local grossAmount = main:getChildById('grossAmount')
    local profitAmount = main:getChildById('profitAmount')
    local feeAmount = main:getChildById('feeAmount')
    if grossAmount then
        grossAmount:setText(convertGold(grossProfit, true))
        grossAmount.value = numericValue
    end
    if currentActionType == 0 then
        if profitAmount then profitAmount:setText(convertGold(grossProfit + feeLocal, true)) end
    else
        if profitAmount then profitAmount:setText(convertGold(grossProfit - feeLocal, true)) end
    end
    if feeAmount then feeAmount:setText(convertGold(feeLocal)) end
    local btn = main:getChildById('createButton')
    if btn then btn:setEnabled(true) end
end

function onPiecePriceEdit(widget)
    local main = getMainMarket()
    if not main or not widget then return end
    if not Market.isItemSelected() then
        -- Seleção automática do primeiro item visível na lista
        local list = marketWindow and marketWindow:recursiveGetChildById('itemList') or nil
        local first = list and list.getFirstChild and list:getFirstChild() or nil
        if first and first.item then
            updateSelectedItem(first)
        else
            return
        end
    end

    local text = widget:getText() or ''
    if #text == 0 then
        local grossAmount = main:getChildById('grossAmount')
        if grossAmount then grossAmount:setText('0'); grossAmount.value = 0 end
        local profitAmount = main:getChildById('profitAmount')
        if profitAmount then profitAmount:setText('0') end
        local feeAmount = main:getChildById('feeAmount')
        if feeAmount then feeAmount:setText('0') end
        local btn = main:getChildById('createButton')
        if btn then btn:setEnabled(false) end
        local scroll = main:getChildById('amountCreateScrollBar')
        if scroll then scroll:setStep(1); scroll:setRange(0, 0) end
        return
    end

    local currentText = text:gsub('[^%d]', '')
    if currentText ~= text then widget:setText(currentText) end
    if #currentText > 12 then
        currentText = currentText:sub(1, -2)
        widget:setText(currentText)
    end
    local numericValue = tonumber(currentText)
    if not numericValue then return end
    if numericValue >= 999999999999 then
        currentText = '999999999999'
        widget:setText(currentText)
        numericValue = tonumber(currentText)
    end

    local scroll = main:getChildById('amountCreateScrollBar')
    local amount = scroll and scroll:getValue() or 0

    local feeLocal = math.ceil((numericValue / 50) * amount)
    if feeLocal < 20 then
        feeLocal = 20
    elseif feeLocal > 1000000 then
        feeLocal = 1000000
    end

    local itemId = selectedItem.item.marketData.tradeAs
    local thing = g_things.getThingType(itemId)
    local stackable = thing and thing:isStackable() or false
    local maxCount = stackable and 64000 or 2000
    local maxValue = 999999999999
    if numericValue * amount >= maxValue then
        local newAmount = math.floor(maxValue / numericValue)
        amount = newAmount
        if scroll then scroll:setValue(amount) end
        maxCount = newAmount
    end

    local isTibiaCoin = itemId == 22118
    local step = isTibiaCoin and 25 or 1
    if scroll then
        scroll:setStep(step)
        if currentActionType == 0 then
            local player = g_game.getLocalPlayer()
            local balance = player and player:getTotalMoney() or 0
            local barCount = 0
            if isTibiaCoin then
                barCount = math.floor(balance / (numericValue * 25))
                if scroll:getValue() <= 1 then scroll:setValue(25) end
                if barCount > 0 then
                    scroll:setRange(25, barCount * 25)
                else
                    scroll:setRange(0, 0)
                end
            else
                if balance >= numericValue then
                    barCount = math.min(maxCount, math.floor(balance / numericValue))
                end
                if barCount > 0 then
                    scroll:setRange(1, barCount)
                    if scroll:getValue() < 1 then scroll:setValue(1) end
                    amount = scroll:getValue()
                    updateCreateCount(scroll, amount)
                else
                    scroll:setRange(0, 0)
                end
            end
        else
            local itemCount = isTibiaCoin and g_game.getTransferableTibiaCoins() or Market.getDepotCount(itemId)
            if itemCount > 0 then
                if isTibiaCoin and itemCount < 25 then
                    scroll:setValue(0)
                else
                    local minVal = isTibiaCoin and 25 or 1
                    scroll:setRange(minVal, math.min(maxCount, itemCount))
                    if scroll:getValue() < minVal then scroll:setValue(minVal) end
                    amount = scroll:getValue()
                    updateCreateCount(scroll, amount)
                    local btn = main:getChildById('createButton')
                    if btn then btn:setEnabled(true) end
                end
            else
                scroll:setRange(0, 0)
            end
        end
    end

    local grossProfit = numericValue * amount
    local grossAmount = main:getChildById('grossAmount')
    local profitAmount = main:getChildById('profitAmount')
    local feeAmount = main:getChildById('feeAmount')
    if grossAmount then
        grossAmount:setText(convertGold(grossProfit, true))
        grossAmount.value = numericValue
    end
    if currentActionType == 0 then
        if profitAmount then profitAmount:setText(convertGold(grossProfit + feeLocal, true)) end
    else
        if profitAmount then profitAmount:setText(convertGold(grossProfit - feeLocal, true)) end
    end
    if feeAmount then feeAmount:setText(convertGold(feeLocal)) end
    local btn = main:getChildById('createButton')
    if btn then btn:setEnabled(amount > 0 and numericValue > 0) end
    -- Debug: confirmar cálculo e habilitação
end

function createMarketOffer()
    if not Market.isItemSelected() then return end
    local main = getMainMarket()
    if not main then return end
    local amountTextWidget = main:getChildById('createOfferAmount')
    local ntext = amountTextWidget and amountTextWidget:getText() or 'Amount: 0'
    local amount = tonumber((ntext:gsub('%D',''))) or 0
    local ga = main:getChildById('grossAmount')
    local piecePrice = ga and ga.value or 0

    -- Determine action type
    local actionType = (currentActionType == 1) and MarketAction.Sell or MarketAction.Buy

    -- Compute fee using legacy logic to match server expectations
    local feeLocal = math.ceil((piecePrice / 100) * amount)
    if feeLocal < 20 then
        feeLocal = 20
    elseif feeLocal > 1000 then
        feeLocal = 1000
    end

    -- Error checks similar to Market.createNewOffer
    local errorMsg = ''
    local balance = information and information.balance or (g_game.getLocalPlayer() and g_game.getLocalPlayer():getTotalMoney() or 0)
    if actionType == MarketAction.Buy then
        if balance < ((piecePrice * amount) + feeLocal) then
            errorMsg = errorMsg .. 'Not enough balance to create this offer.\n'
        end
    else
        if balance < feeLocal then
            errorMsg = errorMsg .. 'Not enough balance to create this offer.\n'
        end
        local spriteIdCheck = selectedItem.item.marketData.tradeAs
        if Market.getDepotCount(spriteIdCheck) < amount then
            errorMsg = errorMsg .. 'Not enough items in your depot to create this offer.\n'
        end
    end

    -- Prevent excessive totals
    if amount * piecePrice > MarketMaxPrice then
        errorMsg = errorMsg .. 'Total price is too high.\n'
    end

    local timeCheck = os.time() - lastCreatedOffer
    if timeCheck < offerExhaust[actionType] then
        local waitTime = math.ceil(offerExhaust[actionType] - timeCheck)
        errorMsg = errorMsg .. 'You must wait ' .. waitTime .. ' seconds before creating a new offer.\n'
    end

    if errorMsg ~= '' then
        Market.displayMessage(errorMsg)
        return
    end

    local scroll = main:getChildById('amountCreateScrollBar')
    if scroll then
        scroll:setRange(0, 0)
        scroll:setValue(0)
    end
    local btn = main:getChildById('createButton')
    if btn then btn:setEnabled(false) end
    if ga then ga:setText('0'); ga.value = 0 end
    local pa = main:getChildById('profitAmount')
    if pa then pa:setText('0') end
    local fa = main:getChildById('feeAmount')
    if fa then fa:setText('0') end
    local pe = main:getChildById('piecePriceCreate')
    if pe then pe:clearText() end

    local itemId = selectedItem.item.marketData.tradeAs
    -- Determine tier/classification consistent with legacy flow
    local itemTier = 0
    if g_game.getFeature and g_game.getFeature(GameThingUpgradeClassification) then
        -- Sempre derive o tier a partir do filtro de UI quando aplicável.
        -- Evita enviar tiers implícitos baseados em classificação.
        local it = Item.create(itemId)
        local cls = (it and it.getClassification) and tonumber(it:getClassification()) or 0
        local selectedTier = 0
        if tierFilterCombo and tierFilterCombo.getCurrentOption then
            local opt = tierFilterCombo:getCurrentOption()
            local text = opt and opt.text or ''
            local num = text:match('%d+')
            selectedTier = tonumber(num or 0) or 0
        end
        if actionType == MarketAction.Sell then
            -- Para venda: se houver tier selecionado e item classificável, use-o; caso contrário, 0.
            if cls > 0 and selectedTier > 0 then
                itemTier = selectedTier
            else
                itemTier = 0
            end
        else
            -- Para compra: use estritamente o tier selecionado quando item for classificável.
            -- Caso UI esteja em "Tier 0/All" ou item não classificável, envie 0.
            if cls > 0 and selectedTier > 0 then
                itemTier = selectedTier
            else
                itemTier = 0
            end
        end
    end
    local anonymousWidget = main:getChildById('anonymous')
    local anonymousFlag = (anonymousWidget and anonymousWidget.isChecked and anonymousWidget:isChecked()) and 1 or 0
    print(string.format('[Market] createMarketOffer: action=%s itemId=%d tier=%d amount=%d price=%d anonymous=%d',
        (actionType == MarketAction.Sell) and 'Sell' or 'Buy', tonumber(itemId or 0), tonumber(itemTier or 0), tonumber(amount or 0), tonumber(piecePrice or 0), tonumber(anonymousFlag or 0)))
    g_game.createMarketOffer(actionType, itemId, itemTier, amount, piecePrice, anonymousFlag)
    lastCreatedOffer = os.time()
    -- After creating, refresh lists to show the new offer
    Market.refreshOffers()
    Market.refreshMyOffers()
end

-- Scrollbar value handlers for accept-offer sections (new UI)
function updateSellCount(widget, value)
    local main = getMainMarket()
    if not main then return end
    local step = 1
    if widget and widget.getStep then step = widget:getStep() end
    if step and step > 1 then
        value = math.max(step, math.floor(value / step + 0.5) * step)
    end

    local amountLabel = main:getChildById('amountSell')
    if amountLabel then amountLabel:setText(value) end

    local offer = selectedOffer[MarketAction.Buy]
    local total = 0
    if offer and offer.getPrice then total = offer:getPrice() * value end
    local totalLabel = main:getChildById('totalValue')
    if totalLabel then totalLabel:setText(comma_value(total)) end
end

function updateBuyCount(widget, value)
    local main = getMainMarket()
    if not main then return end
    local step = 1
    if widget and widget.getStep then step = widget:getStep() end
    if step and step > 1 then
        value = math.max(step, math.floor(value / step + 0.5) * step)
    end

    local amountLabel = main:getChildById('amountBuy')
    if amountLabel then amountLabel:setText(value) end

    local offer = selectedOffer[MarketAction.Sell]
    local total = 0
    if offer and offer.getPrice then total = offer:getPrice() * value end
    local totalLabel = main:getChildById('totalSellValue')
    if totalLabel then totalLabel:setText(comma_value(total)) end
end

-- New UI filter controls
local vocButton = nil
local oneButton = nil
local twoButton = nil
local tierFilterCombo = nil
local classFilterCombo = nil
local levelButton = nil
local lockerOnlyButton = nil
local categoryScroll = nil
-- Evento para debouncing do filtro de Tier
local tierUpdateEvent = nil
-- Suprimir auto-browse no layout legado durante atualizações de filtro
local suppressLegacyAutoBrowse = false

-- Estados dos filtros (como os botões não são checkboxes)
local vocFilterActive = false
local levelFilterActive = false
local oneFilterActive = false
local twoFilterActive = false

local function isItemValid(item, category, searchFilter)
    if not item or not item.marketData then
        return false
    end

    if not category then
        category = MarketCategory.All
    end
    if item.marketData.category ~= category and category ~= MarketCategory.All then
        return false
    end

    -- filter item (legacy + new UI)
    local slotFilter = false
    if slotFilterList and slotFilterList.isEnabled and slotFilterList:isEnabled() then
        slotFilter = getMarketSlotFilterId(slotFilterList:getCurrentOption().text)
    end
    local marketData = item.marketData

    local filterVocationLegacy = filterButtons[MarketFilters.Vocation] and filterButtons[MarketFilters.Vocation]:isChecked() or false
    local filterLevelLegacy = filterButtons[MarketFilters.Level] and filterButtons[MarketFilters.Level]:isChecked() or false
    local filterDepotLegacy = filterButtons[MarketFilters.Depot] and filterButtons[MarketFilters.Depot]:isChecked() or false
    local filterVocationNew = vocFilterActive
    local filterVocation = filterVocationLegacy or filterVocationNew
    -- Volta a filtrar pelo nível quando levelButton estiver marcado (além do legado)
    local filterLevel = (levelFilterActive) or filterLevelLegacy
    local filterDepot = (lockerOnlyButton and lockerOnlyButton:isChecked() or false) or filterDepotLegacy

    if slotFilter then
        if slotFilter ~= 255 and item.thingType:getClothSlot() ~= slotFilter then
            return false
        end
    end

    local player = g_game.getLocalPlayer()
    if filterLevel and marketData.requiredLevel and player and player:getLevel() < marketData.requiredLevel then
        return false
    end

    if filterVocation and marketData.restrictVocation and marketData.restrictVocation > 0 then
        local demotedVoc = information.vocation > 10 and (information.vocation - 10) or information.vocation
        local vocBitMask = Bit.bit(demotedVoc)
        if not Bit.hasBit(marketData.restrictVocation, vocBitMask) then
            return false
        end
    end

    if filterDepot and Market.getDepotCount(item.marketData.tradeAs) <= 0 then
        return false
    end

    -- 1H / 2H filters (new UI)
    local h1 = oneFilterActive
    local h2 = twoFilterActive
    if h1 and item.thingType:getClothSlot() ~= 6 then
        return false
    end
    if h2 and item.thingType:getClothSlot() ~= 0 then
        return false
    end

    -- Tier filter (new UI): se Tier > 0, mostrar apenas itens classificáveis
    if tierFilterCombo and tierFilterCombo.getCurrentOption then
        local opt = tierFilterCombo:getCurrentOption()
        local text = opt and opt.text or nil
        local tierNum = text and text:match('%d+')
        tierNum = tierNum and tonumber(tierNum) or 0
        if tierNum > 0 then
            local classification = item.thingType and item.thingType.getClassification and tonumber(item.thingType:getClassification()) or 0
            if (not classification) or classification <= 0 then
                return false
            end
        end
    end

    -- Class filter (new UI): se Classe selecionada > 0, filtrar por classificação
    if classFilterCombo and classFilterCombo.getCurrentOption then
        local opt = classFilterCombo:getCurrentOption()
        local text = opt and opt.text or nil
        local classNum = text and text:match('%d+')
        classNum = classNum and tonumber(classNum) or 0
        if classNum > 0 then
            local classification = item.thingType and item.thingType.getClassification and tonumber(item.thingType:getClassification()) or 0
            if classification ~= classNum then
                return false
            end
        end
    end

    -- Search filter
    if searchFilter and searchFilter ~= '' then
        if not marketData.name:lower():find(searchFilter:lower()) then
            return false
        end
    end

    return true
end

local function clearItems()
    currentItems = {}
    Market.refreshItemsWidget()
    -- Reset item list vertical scrollbar when items are cleared
    local root = marketWindow or getMainMarket()
    if root and root.recursiveGetChildById then
        -- Use new UI scrollbar id if available, fallback to old id
        local vItems = root:recursiveGetChildById('itemsPanelListScrollBar') or root:recursiveGetChildById('itemListScroll')
        if vItems and vItems.setRange then vItems:setRange(0, 0) end
        if vItems and vItems.setValue then vItems:setValue(0) end
        if vItems and vItems.setVirtualChilds then vItems:setVirtualChilds(0) end
        if vItems and vItems.setVisibleItems then vItems:setVisibleItems(0) end
    end
end

local function clearOffers()
    marketOffers[MarketAction.Buy] = {}
    marketOffers[MarketAction.Sell] = {}
    if buyOfferTable and buyOfferTable.clearData then buyOfferTable:clearData() else if buyOfferTable then buyOfferTable:destroyChildren() end end
    if sellOfferTable and sellOfferTable.clearData then sellOfferTable:clearData() else if sellOfferTable then sellOfferTable:destroyChildren() end end
    -- Reset vertical scrollbars so the knob doesn't stay tiny when empty
    local root = getMainMarket() or marketWindow
    if root and root.recursiveGetChildById then
        local vSell = root:recursiveGetChildById('sellOffersListScroll')
        local vBuy  = root:recursiveGetChildById('buyOffersListScroll')
        if vSell and vSell.setRange then vSell:setRange(0, 0) end
        if vSell and vSell.setValue then vSell:setValue(0) end
        if vBuy and vBuy.setRange then vBuy:setRange(0, 0) end
        if vBuy and vBuy.setValue then vBuy:setValue(0) end
    end
end

local function clearMyOffers()
    marketOffers[MarketAction.Buy] = {}
    marketOffers[MarketAction.Sell] = {}
    if buyMyOfferTable and buyMyOfferTable.clearData then buyMyOfferTable:clearData() else if buyMyOfferTable then buyMyOfferTable:destroyChildren() end end
    if sellMyOfferTable and sellMyOfferTable.clearData then sellMyOfferTable:clearData() else if sellMyOfferTable then sellMyOfferTable:destroyChildren() end end
    if historySellList then historySellList:destroyChildren() end
    if historyBuyList then historyBuyList:destroyChildren() end
    if sellOffersLabel then sellOffersLabel:setText(tr('Sell Offers (0):')) end
    if buyOffersLabel then buyOffersLabel:setText(tr('Buy Offers (0):')) end
end

local function clearMyHistory()
    marketOffers[MarketAction.Buy] = {}
    marketOffers[MarketAction.Sell] = {}
    if buyMyHistoryTable and buyMyHistoryTable.clearData then buyMyHistoryTable:clearData() else if buyMyHistoryTable then buyMyHistoryTable:destroyChildren() end end
    if sellMyHistoryTable and sellMyHistoryTable.clearData then sellMyHistoryTable:clearData() else if sellMyHistoryTable then sellMyHistoryTable:destroyChildren() end end
end
local function clearFilters()
    for _, filter in pairs(filterButtons) do
        if filter and filter:isChecked() ~= filter.default then
            filter:setChecked(filter.default)
        end
    end
end

local function clearFee()
    if feeLabel then feeLabel:setText('') end
    fee = 20
end

local function refreshTypeList()
    if not offerTypeList then return end
    offerTypeList:clearOptions()
    offerTypeList:addOption('Buy')

    if Market.isItemSelected() then
        if Market.getDepotCount(selectedItem.item.marketData.tradeAs) > 0 then
            offerTypeList:addOption('Sell')
        end
    end
    -- definir padrão: 'Sell' se disponível; senão 'Buy'
    if offerTypeList.setCurrentOption then
        -- tentar selecionar 'Sell' primeiro
        offerTypeList:setCurrentOption('Sell')
        -- se não existir, ficará em 'Buy'
        if offerTypeList.getCurrentOption then
            local opt = offerTypeList:getCurrentOption()
            if not opt or opt.text ~= 'Sell' then
                offerTypeList:setCurrentOption('Buy')
            end
        end
    end
end

local function addOffer(offer, offerType)
    if not offer then
        return false
    end
    local id = offer:getId()
    local player = offer:getPlayer()
    local amount = offer:getAmount()
    local price = offer:getPrice()
    local timestamp = offer:getTimeStamp()
    local itemName = offer:getItem():getMarketData().name
    local action = offer:getState()
    local preBc = buyOfferTable and buyOfferTable.getChildCount and buyOfferTable:getChildCount() or -1
    local preSc = sellOfferTable and sellOfferTable.getChildCount and sellOfferTable:getChildCount() or -1

    -- Only toggle sorting if widget supports it (legacy Table widget)
    if buyOfferTable and buyOfferTable.toggleSorting then buyOfferTable:toggleSorting(false) end
    if sellOfferTable and sellOfferTable.toggleSorting then sellOfferTable:toggleSorting(false) end

    if buyMyOfferTable and buyMyOfferTable.toggleSorting then buyMyOfferTable:toggleSorting(false) end
    if sellMyOfferTable and sellMyOfferTable.toggleSorting then sellMyOfferTable:toggleSorting(false) end

    if buyMyHistoryTable and buyMyHistoryTable.toggleSorting then buyMyHistoryTable:toggleSorting(false) end
    if sellMyHistoryTable and sellMyHistoryTable.toggleSorting then sellMyHistoryTable:toggleSorting(false) end

    if amount < 1 then
        return false
    end
    if offerType == MarketAction.Buy then
        if offer.warn then
            if buyOfferTable and buyOfferTable.setColumnStyle then
                buyOfferTable:setColumnStyle('OfferTableWarningColumn', true)
            end
        end

        local row = nil
        if offer.var == MarketRequest.MyOffers then
            -- Direciona ofertas pessoais de compra para a tabela dedicada
            if buyMyOfferTable and buyMyOfferTable.addRow then
                row = buyMyOfferTable:addRow({{
                    text = itemName
                }, {
                    text = amount
                }, {
                    text = price * amount
                }, {
                    text = price
                }, {
                    text = string.gsub(os.date('%c', timestamp), ' ', '  ')
                }})
            else
                -- UI sem tabela dedicada: não misturar com listas principais
                return true
            end
        elseif offer.var == MarketRequest.MyHistory and buyMyHistoryTable and buyMyHistoryTable.addRow then
            row = buyMyHistoryTable:addRow({{
                text = itemName
            }, {
                text = price * amount
            }, {
                text = price
            }, {
                text = amount
            }, {
                text = MarketOfferStateString[action],
                sortvalue = timestamp
            }})
        elseif offer.var == MarketRequest.MyOffers or offer.var == MarketRequest.MyHistory then
            -- UI may not include 'My Offers'/'History' tables; skip gracefully
            return true
        else
            if buyOfferTable and buyOfferTable.addRow then
                -- Legacy table-based UI
                row = buyOfferTable:addRow({{
                    text = player
                }, {
                    text = amount
                }, {
                    text = price * amount
                }, {
                    text = price
                }, {
                    text = string.gsub(os.date('%c', timestamp), ' ', '  ')
                }})
            else
                -- New list-based UI: use MarketOfferWidget for main lists, MarketCurrentWidget for history lists
                local isHistoryList = (historyBuyList and buyOfferTable == historyBuyList)
                local widgetType = isHistoryList and 'MarketCurrentWidget' or 'MarketOfferWidget'
                local w = (buyOfferTable.createChild and buyOfferTable:createChild(widgetType))
                    or g_ui.createWidget(widgetType, buyOfferTable)
                local displayName = (player and player ~= '' and player) or 'anony'
                w:getChildById('name'):setText(displayName)
                w:getChildById('amount'):setText(tostring(amount))
                w:getChildById('piecePrice'):setText(tostring(price))
                w:getChildById('totalPrice'):setText(tostring(price * amount))
                w:getChildById('endAt'):setText(string.gsub(os.date('%c', timestamp), ' ', '  '))
                if w.setFocusable then w:setFocusable(true) end
                w.onMousePress = function(self, mousePos, mouseButton)
                    local parent = self:getParent()
                    if parent and parent.focusChild then parent:focusChild(self, KeyboardFocusReason) end
                    if parent and parent.ensureChildVisible then parent:ensureChildVisible(self) end
                    Market.selectBuyWidget(self)
                    if buyOfferTable and onSelectBuyOffer then onSelectBuyOffer(buyOfferTable, self, nil) end
                end
                w.onClick = function()
                    Market.selectBuyWidget(w)
                    if buyOfferTable and onSelectBuyOffer then onSelectBuyOffer(buyOfferTable, w, nil) end
                end
                w.ref = id
                w.offer = offer
                row = w
                local postBc = buyOfferTable and buyOfferTable.getChildCount and buyOfferTable:getChildCount() or -1
            end
        end
        row.ref = id

        if offer.warn then
            row:setTooltip(tr('This offer is 25%% below the average market price'))
            buyOfferTable:setColumnStyle('OfferTableColumn', true)
        end
    else
        if offer.warn and sellOfferTable and sellOfferTable.setColumnStyle then
            sellOfferTable:setColumnStyle('OfferTableWarningColumn', true)
        end

        local row = nil
        if offer.var == MarketRequest.MyOffers then
            -- Direciona ofertas pessoais de venda para a tabela dedicada
            if sellMyOfferTable and sellMyOfferTable.addRow then
                row = sellMyOfferTable:addRow({{
                    text = itemName
                }, {
                    text = amount
                }, {
                    text = price * amount
                }, {
                    text = price
                }, {
                    text = string.gsub(os.date('%c', timestamp), ' ', '  '),
                    sortvalue = timestamp
                }})
            else
                -- UI sem tabela dedicada: não misturar com listas principais
                return true
            end
        elseif offer.var == MarketRequest.MyHistory and sellMyHistoryTable and sellMyHistoryTable.addRow then
            row = sellMyHistoryTable:addRow({{
                text = itemName
            }, {
                text = price * amount
            }, {
                text = price
            }, {
                text = amount
            }, {
                text = MarketOfferStateString[action],
                sortvalue = timestamp
            }})
        elseif offer.var == MarketRequest.MyOffers or offer.var == MarketRequest.MyHistory then
            -- UI may not include 'My Offers'/'History' tables; skip gracefully
            return true
        else
            if sellOfferTable and sellOfferTable.addRow then
                row = sellOfferTable:addRow({{
                    text = player
                }, {
                    text = amount
                }, {
                    text = price * amount
                }, {
                    text = price
                }, {
                    text = string.gsub(os.date('%c', timestamp), ' ', '  '),
                    sortvalue = timestamp
                }})
            else
                local isHistoryList = (historySellList and sellOfferTable == historySellList)
                local widgetType = isHistoryList and 'MarketCurrentWidget' or 'MarketOfferWidget'
                local w = (sellOfferTable.createChild and sellOfferTable:createChild(widgetType))
                    or g_ui.createWidget(widgetType, sellOfferTable)
                local displayName = (player and player ~= '' and player) or 'anony'
                w:getChildById('name'):setText(displayName)
                w:getChildById('amount'):setText(tostring(amount))
                w:getChildById('piecePrice'):setText(tostring(price))
                w:getChildById('totalPrice'):setText(tostring(price * amount))
                w:getChildById('endAt'):setText(string.gsub(os.date('%c', timestamp), ' ', '  '))
                if w.setFocusable then w:setFocusable(true) end
                w.onMousePress = function(self, mousePos, mouseButton)
                    local parent = self:getParent()
                    if parent and parent.focusChild then parent:focusChild(self, KeyboardFocusReason) end
                    if parent and parent.ensureChildVisible then parent:ensureChildVisible(self) end
                    Market.selectSellWidget(self)
                    if sellOfferTable and onSelectSellOffer then onSelectSellOffer(sellOfferTable, self, nil) end
                end
                w.onClick = function()
                    Market.selectSellWidget(w)
                    if sellOfferTable and onSelectSellOffer then onSelectSellOffer(sellOfferTable, w, nil) end
                end
                w.ref = id
                w.offer = offer
                row = w
                local postSc = sellOfferTable and sellOfferTable.getChildCount and sellOfferTable:getChildCount() or -1
            end
        end
        row.ref = id

        if offer.warn then
            row:setTooltip(tr('This offer is 25%% above the average market price'))
            sellOfferTable:setColumnStyle('OfferTableColumn', true)
        end
    end

    if buyOfferTable and buyOfferTable.toggleSorting then buyOfferTable:toggleSorting(false) end
    if sellOfferTable and sellOfferTable.toggleSorting then sellOfferTable:toggleSorting(false) end
    if buyOfferTable and buyOfferTable.sort then buyOfferTable:sort() end
    if sellOfferTable and sellOfferTable.sort then sellOfferTable:sort() end

    if buyMyOfferTable and buyMyOfferTable.toggleSorting then buyMyOfferTable:toggleSorting(false) end
    if sellMyOfferTable and sellMyOfferTable.toggleSorting then sellMyOfferTable:toggleSorting(false) end
    if buyMyOfferTable and buyMyOfferTable.sort then buyMyOfferTable:sort() end
    if sellMyOfferTable and sellMyOfferTable.sort then sellMyOfferTable:sort() end

    if buyMyHistoryTable and buyMyHistoryTable.toggleSorting then buyMyHistoryTable:toggleSorting(false) end
    if sellMyHistoryTable and sellMyHistoryTable.toggleSorting then sellMyHistoryTable:toggleSorting(false) end
    if buyMyHistoryTable and buyMyHistoryTable.sort then buyMyHistoryTable:sort() end
    if sellMyHistoryTable and sellMyHistoryTable.sort then sellMyHistoryTable:sort() end

    -- Log child count for diagnostics
    local bc = buyOfferTable and buyOfferTable.getChildCount and buyOfferTable:getChildCount() or -1
    local sc = sellOfferTable and sellOfferTable.getChildCount and sellOfferTable:getChildCount() or -1
    return true
end

local function mergeOffer(offer)
    if not offer then
        return false
    end

    local id = offer:getId()
    local offerType = offer:getType()
    local amount = offer:getAmount()
    local replaced = false

    if offerType == MarketAction.Buy then
        if averagePrice > 0 then
            offer.warn = offer:getPrice() <= averagePrice - math.floor(averagePrice / 4)
        end

        for i = 1, #marketOffers[MarketAction.Buy] do
            local o = marketOffers[MarketAction.Buy][i]
            -- replace existing offer
            if o:isEqual(id) then
                marketOffers[MarketAction.Buy][i] = offer
                replaced = true
            end
        end
        if not replaced then
            table.insert(marketOffers[MarketAction.Buy], offer)
        end
    else
        if averagePrice > 0 then
            offer.warn = offer:getPrice() >= averagePrice + math.floor(averagePrice / 4)
        end

        for i = 1, #marketOffers[MarketAction.Sell] do
            local o = marketOffers[MarketAction.Sell][i]
            -- replace existing offer
            if o:isEqual(id) then
                marketOffers[MarketAction.Sell][i] = offer
                replaced = true
            end
        end
        if not replaced then
            table.insert(marketOffers[MarketAction.Sell], offer)
        end
    end
    return true
end

local function updateOffers(offers)
    local size = (type(offers) == 'table') and #offers or -1
    if balanceLabel and balanceLabel.setColor then balanceLabel:setColor('#bbbbbb') end
    if buyOfferTable and buyOfferTable.setVisible then buyOfferTable:setVisible(true) end
    if sellOfferTable and sellOfferTable.setVisible then sellOfferTable:setVisible(true) end
    selectedOffer[MarketAction.Buy] = nil
    selectedOffer[MarketAction.Sell] = nil

    selectedMyOffer[MarketAction.Buy] = nil
    selectedMyOffer[MarketAction.Sell] = nil

    -- clear existing offer data
    local count = (type(offers) == 'table') and #offers or -1
    if type(offers) == 'table' then
        for i = 1, #offers do
            local o = offers[i]
            local item = o and o.getItem and o:getItem() or nil
            local md = item and item.getMarketData and item:getMarketData() or nil
            local name = md and md.name or 'unknown'
            local id = item and item.getId and item:getId() or -1
            local action = (o and o.getType and o:getType() == MarketAction.Buy) and 'BUY' or 'SELL'
            local amount = o and o.getAmount and o:getAmount() or 0
            local price = o and o.getPrice and o:getPrice() or 0
            local total = amount * price
            local ts = o and o.getTimeStamp and o:getTimeStamp() or 0
            local ctr = o and o.getCounter and o:getCounter() or 0
            local state = o and o.getState and o:getState() or 0
        end
    end
    if buyOfferTable and buyOfferTable.clearData then buyOfferTable:clearData() else if buyOfferTable then buyOfferTable:destroyChildren() end end
    if buyOfferTable and buyOfferTable.setSorting then buyOfferTable:setSorting(4, TABLE_SORTING_DESC) end
    if sellOfferTable and sellOfferTable.clearData then sellOfferTable:clearData() else if sellOfferTable then sellOfferTable:destroyChildren() end end
    if sellOfferTable and sellOfferTable.setSorting then sellOfferTable:setSorting(4, TABLE_SORTING_ASC) end
    if sellButton and sellButton.setEnabled then sellButton:setEnabled(false) end
    if buyButton and buyButton.setEnabled then buyButton:setEnabled(false) end

    if buyCancelButton then buyCancelButton:setEnabled(false) end
    if sellCancelButton then sellCancelButton:setEnabled(false) end
    for _, offer in pairs(offers) do
        mergeOffer(offer)
    end
    local buyPath = (buyOfferTable and buyOfferTable.addRow) and 'table' or 'list'
    local sellPath = (sellOfferTable and sellOfferTable.addRow) and 'table' or 'list'

    -- Early fallback: if UI is list-based but doesn't support createChild (e.g., TextList), switch to legacy tables
    local function earlySwitchToLegacy()
        local listUiMissingCreate = function(tbl)
            return tbl and (tbl.addRow == nil) and (tbl.createChild == nil)
        end
        if listUiMissingCreate(buyOfferTable) or listUiMissingCreate(sellOfferTable) then
            local legacyBuy = itemOffersPanel and itemOffersPanel:recursiveGetChildById('buyingTable') or nil
            local legacySell = itemOffersPanel and itemOffersPanel:recursiveGetChildById('sellingTable') or nil
            if legacyBuy and legacySell then
                legacyBuy.onSelectionChange = onSelectBuyOffer
                legacySell.onSelectionChange = onSelectSellOffer
                buyOfferTable = legacyBuy
                sellOfferTable = legacySell
                if buyOfferTable.clearData then buyOfferTable:clearData() end
                if sellOfferTable.clearData then sellOfferTable:clearData() end
                return true
            end
        end
        return false
    end
    earlySwitchToLegacy()
    local preBuyCount = #(marketOffers[MarketAction.Buy])
    local preSellCount = #(marketOffers[MarketAction.Sell])
    for type, offers in pairs(marketOffers) do
        for i = 1, #offers do
            addOffer(offers[i], type)
        end
    end

    -- Fallback: if list-based UI failed to render, switch to legacy tables
    local function switchToLegacy()
        if not itemOffersPanel then return false end
        local legacyBuy = itemOffersPanel:recursiveGetChildById('buyingTable')
        local legacySell = itemOffersPanel:recursiveGetChildById('sellingTable')
        if not legacyBuy or not legacySell then return false end

        -- Rebind selection handlers
        legacyBuy.onSelectionChange = onSelectBuyOffer
        legacySell.onSelectionChange = onSelectSellOffer

        buyOfferTable = legacyBuy
        sellOfferTable = legacySell

        -- Clear legacy tables and repopulate
        if buyOfferTable.clearData then buyOfferTable:clearData() end
        if sellOfferTable.clearData then sellOfferTable:clearData() end

        for t, offs in pairs(marketOffers) do
            for i = 1, #offs do
                addOffer(offs[i], t)
            end
        end
        return true
    end

    local buyChildren = buyOfferTable and buyOfferTable.getChildCount and buyOfferTable:getChildCount() or 0
    local sellChildren = sellOfferTable and sellOfferTable.getChildCount and sellOfferTable:getChildCount() or 0
    local buyCount = #(marketOffers[MarketAction.Buy])
    local sellCount = #(marketOffers[MarketAction.Sell])
    -- If a tiered browse came back empty, try a base browse without tier.
    -- This helps servers that only provide non-tiered offers or use tier strictly.
    if buyCount == 0 and sellCount == 0 and lastItemID and lastItemID ~= 0 and lastItemTier and lastItemTier > 0 then
        -- Evitar múltiplos fallbacks: zere o tier antes de enviar browse base
        lastItemTier = nil
        MarketProtocol.sendMarketBrowse(MarketRequest.BrowseItem, lastItemID)
    end
    if (buyCount > 0 and buyChildren == 0) or (sellCount > 0 and sellChildren == 0) then
        -- Only attempt fallback if current path appears to be list-based (no addRow)
        local isListUI = not (buyOfferTable and buyOfferTable.addRow) and not (sellOfferTable and sellOfferTable.addRow)
        if isListUI then
            switchToLegacy()
        end
    end
    -- Após atualizar a UI e tratar fallbacks, limpe qualquer browse pendente coalescido
    if MarketProtocol and MarketProtocol.clearPendingBrowse then
        MarketProtocol.clearPendingBrowse()
    end
end

-- Keyboard navigation helpers for TextList-based offer widgets
local function focusPrev(list)
    if not list or not list.getChildCount then return end
    local count = list:getChildCount()
    if count == 0 then return end
    local current = list.getFocusedChild and list:getFocusedChild() or nil
    if not current then
        local first = list:getChildByIndex(1)
        if first then
            list:focusChild(first, KeyboardFocusReason)
            if list.ensureChildVisible then list:ensureChildVisible(first) end
        end
        return
    end
    local idx = list:getChildIndex(current)
    local prevIdx = math.max(1, (idx or 1) - 1)
    local prev = list:getChildByIndex(prevIdx)
    if prev then
        list:focusChild(prev, KeyboardFocusReason)
        if list.ensureChildVisible then list:ensureChildVisible(prev) end
    end
end

local function focusNext(list)
    if not list or not list.getChildCount then return end
    local count = list:getChildCount()
    if count == 0 then return end
    local current = list.getFocusedChild and list:getFocusedChild() or nil
    if not current then
        local first = list:getChildByIndex(1)
        if first then
            list:focusChild(first, KeyboardFocusReason)
            if list.ensureChildVisible then list:ensureChildVisible(first) end
        end
        return
    end
    local idx = list:getChildIndex(current)
    local nextIdx = math.min(count, (idx or 1) + 1)
    local nxt = list:getChildByIndex(nextIdx)
    if nxt then
        list:focusChild(nxt, KeyboardFocusReason)
        if list.ensureChildVisible then list:ensureChildVisible(nxt) end
    end
end

-- Navegação de itens da lista via teclado (referenciadas no OTUI)
function focusPrevItemWidget(list)
    return focusPrev(list)
end

function focusNextItemWidget(list)
    return focusNext(list)
end

function focusPrevSellLabel(self)
    focusPrev(self)
end

function focusNextSellLabel(self)
    focusNext(self)
end

function focusPrevBuyLabel(self)
    focusPrev(self)
end

function focusNextBuyLabel(self)
    focusNext(self)
end

local function updateDetails(itemId, descriptions, purchaseStats, saleStats)
    local purchaseOfferStatistic = {}
    local saleOfferStatistic = {}
    if not selectedItem then
        return
    end

    -- Ensure detail/stat tables exist in current UI before proceeding
    if not detailsTable or not buyStatsTable or not sellStatsTable then
        return
    end

    -- update item details
    detailsTable:clearData()
    for k, desc in pairs(descriptions) do
        local columns = {{
            text = getMarketDescriptionName(k) .. ':'
        }, {
            text = desc
        }}
        detailsTable:addRow(columns)
    end

    if not table.empty(saleStats) then
        for i = 1, #saleStats do
            table.insert(saleOfferStatistic, OfferStatistic.new(saleStats[i][1], saleStats[i][2], saleStats[i][3], saleStats[i][4], saleStats[i][5], saleStats[i][6]))
        end
    end
    if not table.empty(purchaseStats) then
        for i = 1, #purchaseStats do
            table.insert(purchaseOfferStatistic, OfferStatistic.new(purchaseStats[i][1], purchaseStats[i][2], purchaseStats[i][3], purchaseStats[i][4], purchaseStats[i][5], purchaseStats[i][6]))
        end
    end
    
    -- update sale item statistics
    sellStatsTable:clearData()
    if table.empty(saleStats) then
        sellStatsTable:addRow({{
            text = 'No information'
        }})
    else
        local offerAmount = 0
        local transactions, totalPrice, highestPrice, lowestPrice = 0, 0, 0, 0
        for _, stat in pairs(saleOfferStatistic) do
            if not stat:isNull() then
                offerAmount = offerAmount + 1
                transactions = transactions + stat:getTransactions()
                totalPrice = totalPrice + stat:getTotalPrice()
                local newHigh = stat:getHighestPrice()
                if newHigh > highestPrice then
                    highestPrice = newHigh
                end
                local newLow = stat:getLowestPrice()
                -- ?? getting '0xffffffff' result from lowest price in 9.60 cipsoft
                if (lowestPrice == 0 or newLow < lowestPrice) and newLow ~= 0xffffffff then
                    lowestPrice = newLow
                end
            end
        end

        if offerAmount >= 5 and transactions >= 10 then
            averagePrice = math.round(totalPrice / transactions)
        else
            averagePrice = 0
        end

        sellStatsTable:addRow({{
            text = 'Total Transations:'
        }, {
            text = transactions
        }})
        sellStatsTable:addRow({{
            text = 'Highest Price:'
        }, {
            text = highestPrice
        }})

        if totalPrice > 0 and transactions > 0 then
            sellStatsTable:addRow({{
                text = 'Average Price:'
            }, {
                text = math.floor(totalPrice / transactions)
            }})
        else
            sellStatsTable:addRow({{
                text = 'Average Price:'
            }, {
                text = 0
            }})
        end

        sellStatsTable:addRow({{
            text = 'Lowest Price:'
        }, {
            text = lowestPrice
        }})
    end

    -- update buy item statistics
    buyStatsTable:clearData()
    if table.empty(purchaseOfferStatistic) then
        buyStatsTable:addRow({{
            text = 'No information'
        }})
    else
        local transactions, totalPrice, highestPrice, lowestPrice = 0, 0, 0, 0
        for _, stat in pairs(purchaseOfferStatistic) do
            if not stat:isNull() then
                transactions = transactions + stat:getTransactions()
                totalPrice = totalPrice + stat:getTotalPrice()
                local newHigh = stat:getHighestPrice()
                if newHigh > highestPrice then
                    highestPrice = newHigh
                end
                local newLow = stat:getLowestPrice()
                -- ?? getting '0xffffffff' result from lowest price in 9.60 cipsoft
                if (lowestPrice == 0 or newLow < lowestPrice) and newLow ~= 0xffffffff then
                    lowestPrice = newLow
                end
            end
        end

        buyStatsTable:addRow({{
            text = 'Total Transations:'
        }, {
            text = transactions
        }})
        buyStatsTable:addRow({{
            text = 'Highest Price:'
        }, {
            text = highestPrice
        }})

        if totalPrice > 0 and transactions > 0 then
            buyStatsTable:addRow({{
                text = 'Average Price:'
            }, {
                text = math.floor(totalPrice / transactions)
            }})
        else
            buyStatsTable:addRow({{
                text = 'Average Price:'
            }, {
                text = 0
            }})
        end

        buyStatsTable:addRow({{
            text = 'Lowest Price:'
        }, {
            text = lowestPrice
        }})
    end
end

local suppressSelection = false
local silentSelection = false
local function updateSelectedItem(widget, opts)
    -- Removidos logs de depuração na seleção de item
    -- Evitar processamento repetido quando o mesmo item já está selecionado
    if selectedItem and selectedItem.ref == widget and selectedItem.item and widget.item
        and selectedItem.item.marketData and widget.item.marketData
        and selectedItem.item.marketData.tradeAs == widget.item.marketData.tradeAs then
        return
    end
    local prevRef = selectedItem and selectedItem.ref or nil
    selectedItem.item = widget.item
    selectedItem.ref = widget

    -- Atualiza visual somente em cliques (não em foco/hover)
    if not (opts and opts.silentVisual) then
        if prevRef and prevRef.getChildById then
            local prevHover = prevRef:getChildById('grayHover')
            if prevHover and prevHover.setBackgroundColor then
                prevHover:setBackgroundColor('#404040')
                if prevHover.setOpacity then prevHover:setOpacity(0.5) end
            end
            local prevName = prevRef:getChildById('name')
            if prevName and prevName.setColor then
                prevName:setColor('#c0c0c0')
            end
        end
        if widget and widget.getChildById then
            local selHover = widget:getChildById('grayHover')
            if selHover and selHover.setBackgroundColor then
                selHover:setBackgroundColor('#6a6a6a')
                if selHover.setOpacity then selHover:setOpacity(0.8) end
            end
            local selName = widget:getChildById('name')
            if selName and selName.setColor then
                selName:setColor('white')
            end
        end
    end

    Market.resetCreateOffer()
    if Market.isItemSelected() then
        -- Debug: confirmar que a seleção foi aplicada
        local dbgName = selectedItem.item and selectedItem.item.marketData and selectedItem.item.marketData.name or 'unknown'
        selectedItem:setItem(selectedItem.item.displayItem)
        -- Exibir ícone de Tier no item selecionado condicionado ao filtro ativo
        do
            local itemId = selectedItem.item and selectedItem.item.marketData and selectedItem.item.marketData.tradeAs or 0
            local cls = 0
            if itemId and itemId > 0 then
                local it = Item.create(itemId)
                if it and it.getClassification then
                    cls = tonumber(it:getClassification()) or 0
                end
            end
            local selectedTier = 0
            if tierFilterCombo and tierFilterCombo.getCurrentOption then
                local opt = tierFilterCombo:getCurrentOption()
                local text = opt and opt.text or ''
                local num = text:match('%d+')
                selectedTier = tonumber(num or 0) or 0
            end
            if ItemsDatabase and ItemsDatabase.setTier then
                -- Mostrar o tier selecionado quando o item é classificável; não comparar classificação com o número do tier
                local showTier = (selectedTier > 0 and cls > 0) and selectedTier or 0
                ItemsDatabase.setTier(selectedItem, showTier)
            end
        end
        local count = Market.getDepotCount(selectedItem.item.marketData.tradeAs)
        if selectedItem.setItemCount then selectedItem:setItemCount(count) end
        if selectedItemCountLabel then selectedItemCountLabel:setText(tostring(count)) end
        if nameLabel then
            nameLabel:setText(selectedItem.item.marketData.name)
        end
        clearOffers()

    Market.enableCreateOffer(true) -- update offer types
        local itemId = selectedItem.item.marketData.tradeAs
        -- Determinar tier apenas quando a feature de classificação estiver ativa e o item for classificado (> 0)
        -- Determinar tier conforme filtro da UI: enviar 0/nil quando UI estiver em "Tier 0/All"
        local itemTier = nil
        if g_game.getFeature and g_game.getFeature(GameThingUpgradeClassification) then
            local selectedTier = 0
            if tierFilterCombo and tierFilterCombo.getCurrentOption then
                local opt = tierFilterCombo:getCurrentOption()
                local text = opt and opt.text or ''
                local num = text:match('%d+')
                selectedTier = tonumber(num or 0) or 0
            end
            -- Enviar o tier selecionado (incluindo 0) para itens classificáveis
            local it = Item.create(itemId)
            local cls = (it and it.getClassification) and tonumber(it:getClassification()) or 0
            if cls and cls > 0 then
                itemTier = selectedTier
            else
                itemTier = nil -- item não-classificado; navegar sem tier
            end
        else
            itemTier = nil -- recurso de classificação desativado
        end
        -- Guardar navegação atual para restauração
        lastItemID = itemId
        lastItemTier = itemTier
        -- Debug do browse: itemId/tier e via de envio

        -- Ensure the Offers panel is active and visible when an item is clicked
        if displaysTabBar and displaysTabBar.getTab and displaysTabBar.selectTab then
            local offersTab = displaysTabBar:getTab(tr('Offers'))
            if offersTab then
                displaysTabBar:selectTab(offersTab)
            end
        else
            local mainMarket = marketWindow and (marketWindow:recursiveGetChildById('MarketMainWindow') or marketWindow:recursiveGetChildById('mainMarket'))
            local detailsMarket = marketWindow and marketWindow:recursiveGetChildById('detailsMarket')
            if detailsMarket and detailsMarket.isVisible and detailsMarket:isVisible() then
                detailsMarket:setVisible(false)
            end
            if mainMarket then
                mainMarket:setVisible(true)
            end
        end
        -- Enviar Browse imediatamente ao clicar no item (incluindo Tier quando aplicável)
        -- Evitar envio em atualizações silenciosas (ex.: focus/hover)
        if not silentSelection and not (opts and opts.silentVisual) then
            -- Limpar buffers para evitar dados residuais ao trocar de item
            MarketOffers2 = {}
            if marketOffers == nil then marketOffers = {} end
            marketOffers[MarketAction.Buy] = {}
            marketOffers[MarketAction.Sell] = {}
            -- Se tivermos um tier selecionado válido, envia com tier; caso contrário, navegação base
            -- Debug: clique no item para ver ofertas
            print(string.format('[Market] itemClick: itemId=%d tier=%s silent=%s opts.silentVisual=%s', tonumber(itemId or 0), tostring(itemTier or 'nil'), tostring(silentSelection or false), tostring((opts and opts.silentVisual) or false)))
            if itemTier ~= nil then
                MarketProtocol.sendMarketBrowse(MarketRequest.BrowseItem, itemId, itemTier)
            else
                MarketProtocol.sendMarketBrowse(MarketRequest.BrowseItem, itemId)
            end
            -- Navegar apenas pelo item selecionado; sem requisições extras
        end
    else
        Market.clearSelectedItem()
    end
end

-- Public wrapper will be defined after local updateBalance implementation

local function updateBalance(balance)
    -- Obter saldo numérico de forma robusta (parâmetro, jogador ou 0)
    local numeric = tonumber(balance)
    if numeric == nil then
        local player = g_game.getLocalPlayer()
        if player and player.getTotalMoney then
            numeric = tonumber(player:getTotalMoney()) or 0
        else
            numeric = 0
        end
    end

    if numeric < 0 then
        numeric = 0
    end
    information.balance = numeric

    -- Atualiza UI com o saldo de ouro do jogador
    if balanceLabel and balanceLabel.setText then
        balanceLabel:setText(convertGold(numeric, true))
        if balanceLabel.resizeToText then balanceLabel:resizeToText() end
    end
end

-- Public wrapper for compatibility with newer UIs/modules
function Market.updateBalance(balance)
    return updateBalance(balance)
end

-- Seleção visual de widgets de oferta (UI baseada em lista)
function Market.selectBuyWidget(widget)
    if not widget then return end
    local parent = widget.getParent and widget:getParent() or nil
    if parent and parent.focusChild then parent:focusChild(widget, KeyboardFocusReason) end
    if parent and parent.ensureChildVisible then parent:ensureChildVisible(widget) end
end

function Market.selectSellWidget(widget)
    if not widget then return end
    local parent = widget.getParent and widget:getParent() or nil
    if parent and parent.focusChild then parent:focusChild(widget, KeyboardFocusReason) end
    if parent and parent.ensureChildVisible then parent:ensureChildVisible(widget) end
end

local function updateFee(price, amount)
    fee = math.ceil(price / 100 * amount)
    if fee < 20 then
        fee = 20
    elseif fee > 1000 then
        fee = 1000
    end
  --[[       feeLabel:setText('Fee: ' .. fee)
        feeLabel:resizeToText() ]]
end

local function destroyAmountWindow()
    if amountWindow then
        amountWindow:destroy()
        amountWindow = nil
    end
end

local function cancelMyOffer(actionType)
    local offer = selectedMyOffer[actionType]
    g_game.cancelMarketOffer(offer:getTimeStamp(), offer:getCounter())
    Market.refreshMyOffers()
end

local function openAmountWindow(callback, actionType, actionText)
    if not Market.isOfferSelected(actionType) then
        return
    end

    amountWindow = g_ui.createWidget('AmountWindow', rootWidget)
    amountWindow:lock()

    local offer = selectedOffer[actionType]
    local item = offer:getItem()

    local maximum = offer:getAmount()
    if actionType == MarketAction.Sell then
        local depot = Market.getDepotCount(item:getId())
        if maximum > depot then
            maximum = depot
        end
    else
        maximum = math.min(maximum, math.floor(information.balance / offer:getPrice()))
    end

    if item:isStackable() then
        maximum = math.min(maximum, MarketMaxAmountStackable)
    else
        maximum = math.min(maximum, MarketMaxAmount)
    end

    local itembox = amountWindow:getChildById('item')
    itembox:setItemId(item:getId())

    local scrollbar = amountWindow:getChildById('amountScrollBar')
    scrollbar:setText(offer:getPrice() .. 'gp')

    scrollbar.onValueChange = function(widget, value)
        widget:setText((value * offer:getPrice()) .. 'gp')
        itembox:setText(value)
    end

    scrollbar:setRange(1, maximum)
    scrollbar:setValue(1)

    local okButton = amountWindow:getChildById('buttonOk')
    if actionText then
        okButton:setText(actionText)
    end

    local okFunc = function()
        local counter = offer:getCounter()
        local timestamp = offer:getTimeStamp()
        callback(scrollbar:getValue(), timestamp, counter)
        destroyAmountWindow()
    end

    local cancelButton = amountWindow:getChildById('buttonCancel')
    local cancelFunc = function()
        destroyAmountWindow()
    end

    amountWindow.onEnter = okFunc
    amountWindow.onEscape = cancelFunc

    okButton.onClick = okFunc
    cancelButton.onClick = cancelFunc
end

local function onSelectSellOffer(table, selectedRow, previousSelectedRow)
    if not selectedRow or not selectedRow.ref then
        return
    end
    updateBalance()
    for _, offer in pairs(marketOffers[MarketAction.Sell]) do
        if offer:isEqual(selectedRow.ref) then
            selectedOffer[MarketAction.Buy] = offer
        end
    end

    local offer = selectedOffer[MarketAction.Buy]
    if offer then
        local price = offer:getPrice()
        if price > information.balance then
            balanceLabel:setColor('#b22222')
            sellButton:setEnabled(false)
        else
            local slice = (information.balance / 2)
            local color
            if (price / slice) * 100 <= 40 then
                color = '#008b00'
            elseif (price / slice) * 100 <= 70 then
                color = '#eec900'
            else
                color = '#ee9a00'
            end
            balanceLabel:setColor(color)
            sellButton:setEnabled(true)
        end

        local main = getMainMarket()
        local scroll = main and main:getChildById('amountSellScrollBar') or nil
        local amountLbl = main and main:getChildById('amountSell') or nil
        local totalLbl = main and main:getChildById('totalValue') or nil
        if scroll then
            local item = offer:getItem()
            local maximum = offer:getAmount()
            local balance = tonumber(information.balance) or 0
            local perPrice = offer:getPrice()
            maximum = math.min(maximum, math.floor(balance / perPrice))
            if item:isStackable() then
                maximum = math.min(maximum, MarketMaxAmountStackable)
            else
                maximum = math.min(maximum, MarketMaxAmount)
            end

            if maximum >= 1 then
                scroll:setRange(1, maximum)
                scroll:setValue(1)
                updateSellCount(scroll, 1)
                sellButton:setEnabled(true)
            else
                scroll:setRange(0, 0)
                if amountLbl then amountLbl:setText('0') end
                if totalLbl then totalLbl:setText('0') end
                sellButton:setEnabled(false)
            end
        end
    end
end

local function onSelectBuyOffer(table, selectedRow, previousSelectedRow)
    if not selectedRow or not selectedRow.ref then
        return
    end
    updateBalance()
    for _, offer in pairs(marketOffers[MarketAction.Buy]) do
        if offer:isEqual(selectedRow.ref) then
            selectedOffer[MarketAction.Sell] = offer
            if Market.getDepotCount(offer:getItem():getId()) > 0 then
                buyButton:setEnabled(true)
            else
                buyButton:setEnabled(false)
            end
        end
    end

    local offer = selectedOffer[MarketAction.Sell]
    if offer then
        local main = getMainMarket()
        local scroll = main and main:getChildById('amountBuyScrollBar') or nil
        local amountLbl = main and main:getChildById('amountBuy') or nil
        local totalLbl = main and main:getChildById('totalSellValue') or nil
        if scroll then
            local item = offer:getItem()
            local maximum = offer:getAmount()
            local depot = Market.getDepotCount(item:getId())
            maximum = math.min(maximum, depot)
            if item:isStackable() then
                maximum = math.min(maximum, MarketMaxAmountStackable)
            else
                maximum = math.min(maximum, MarketMaxAmount)
            end

            if maximum >= 1 then
                scroll:setRange(1, maximum)
                scroll:setValue(1)
                updateBuyCount(scroll, 1)
                buyButton:setEnabled(true)
            else
                scroll:setRange(0, 0)
                if amountLbl then amountLbl:setText('0') end
                if totalLbl then totalLbl:setText('0') end
                buyButton:setEnabled(false)
            end
        end
    end
end

local function onSelectMyBuyOffer(table, selectedRow, previousSelectedRow)
    for _, offer in pairs(marketOffers[MarketAction.Buy]) do
        if offer:isEqual(selectedRow.ref) then
            selectedMyOffer[MarketAction.Buy] = offer
            buyCancelButton:setEnabled(true)
        end
    end
end

local function onSelectMySellOffer(table, selectedRow, previousSelectedRow)
    for _, offer in pairs(marketOffers[MarketAction.Sell]) do
        if offer:isEqual(selectedRow.ref) then
            selectedMyOffer[MarketAction.Sell] = offer
            sellCancelButton:setEnabled(true)
        end
    end
end

local function onChangeCategory(combobox, option)
    local id = getMarketCategoryId(option)
    if id == MarketCategory.MetaWeapons then
        -- enable and load weapons filter/items
        subCategoryList:setEnabled(true)
        slotFilterList:setEnabled(true)
        local subId = getMarketCategoryId(subCategoryList:getCurrentOption().text)
        Market.loadMarketItems(subId)
    else
        subCategoryList:setEnabled(false)
        slotFilterList:setEnabled(false)
        Market.loadMarketItems(id) -- load standard filter
    end
end

local function onChangeSubCategory(combobox, option)
    Market.loadMarketItems(getMarketCategoryId(option))
    slotFilterList:clearOptions()

    local subId = getMarketCategoryId(subCategoryList:getCurrentOption().text)
    local slots = MarketCategoryWeapons[subId].slots
    for _, slot in pairs(slots) do
        if table.haskey(MarketSlotFilters, slot) then
            slotFilterList:addOption(MarketSlotFilters[slot])
        end
    end
    slotFilterList:setEnabled(true)
end

local function onChangeSlotFilter(combobox, option)
    Market.updateCurrentItems()
end

local function onChangeOfferType(combobox, option)
    local item = selectedItem.item
    local maximum = item.thingType:isStackable() and MarketMaxAmountStackable or MarketMaxAmount

    if option == 'Sell' then
        maximum = math.min(maximum, Market.getDepotCount(item.marketData.tradeAs))
        if amountEdit then amountEdit:setMaximum(maximum) end
    else
        if amountEdit then amountEdit:setMaximum(maximum) end
    end
end

local function onTotalPriceChange()
    if not totalPriceEdit or not piecePriceEdit or not amountEdit then return end
    if not Market.isItemSelected() then return end
    local amount = amountEdit:getValue()
    if not amount or amount <= 0 then return end
    local totalPrice = totalPriceEdit:getValue()
    local piecePrice = math.floor(totalPrice / amount)

    piecePriceEdit:setValue(piecePrice, true)
    updateFee(piecePrice, amount)
end

local function onPiecePriceChange()
    if not totalPriceEdit or not piecePriceEdit or not amountEdit then return end
    if not Market.isItemSelected() then return end
    local amount = amountEdit:getValue()
    if not amount or amount <= 0 then return end
    local totalPrice = totalPriceEdit:getValue()
    local piecePrice = piecePriceEdit:getValue()

    totalPriceEdit:setValue(piecePrice * amount, true)
    updateFee(piecePrice, amount)
end

local function onAmountChange()
    if not totalPriceEdit or not piecePriceEdit or not amountEdit then return end
    if not Market.isItemSelected() then return end
    local amount = amountEdit:getValue()
    if not amount or amount <= 0 then return end
    local piecePrice = piecePriceEdit:getValue()
    local totalPrice = piecePrice * amount

    totalPriceEdit:setValue(piecePrice * amount, true)
    updateFee(piecePrice, amount)
end

local function onMarketMessage(messageMode, message)
    Market.displayMessage(message)
end

-- Wrappers para compatibilidade com handlers definidos em market.otui
function onSortMarketFields(widget, value)
    -- Toggle estados conforme o botão clicado
    if widget and widget.getId then
        local id = widget:getId()
        if id == 'vocButton' then
            vocFilterActive = not vocFilterActive
            if vocButton and vocButton.setChecked then vocButton:setChecked(vocFilterActive) end
        elseif id == 'levelButton' then
            levelFilterActive = not levelFilterActive
            if levelButton and levelButton.setChecked then levelButton:setChecked(levelFilterActive) end
        elseif id == 'oneButton' then
            oneFilterActive = not oneFilterActive
            if oneFilterActive then twoFilterActive = false end
            if oneButton and oneButton.setChecked then oneButton:setChecked(oneFilterActive) end
            if twoButton and twoButton.setChecked then twoButton:setChecked(twoFilterActive) end
        elseif id == 'twoButton' then
            twoFilterActive = not twoFilterActive
            if twoFilterActive then oneFilterActive = false end
            if twoButton and twoButton.setChecked then twoButton:setChecked(twoFilterActive) end
            if oneButton and oneButton.setChecked then oneButton:setChecked(oneFilterActive) end
        elseif id == 'classFilter' then
            -- Combo de classe/tier já provoca update em outro handler
        end
    end
    if Market and Market.updateCurrentItems then
        Market.updateCurrentItems()
    end
end

function onSearchItem()
    if Market and Market.updateCurrentItems then
        Market.updateCurrentItems()
    end
end

function onClearSearch()
    if searchEdit and searchEdit.setText then
        searchEdit:setText('')
    end
    if Market and Market.updateCurrentItems then
        Market.updateCurrentItems()
    end
end

-- Button handlers (mirroring classic t_market.lua behavior)
function offersButton()
    if not marketWindow then return end
    local mainMarket = marketWindow:recursiveGetChildById('MarketMainWindow') or marketWindow:recursiveGetChildById('mainMarket')
    local detailsMarket = marketWindow:recursiveGetChildById('detailsMarket')
    local closeButton = marketWindow:recursiveGetChildById('closeButton')
    local marketButton = marketWindow:recursiveGetChildById('marketButton')
    local contentPanel = marketWindow:getChildById('contentPanel')

    -- If "My Offers" overlay is visible, hide it and return to main content
    if myOffersPanel and myOffersPanel.isVisible and myOffersPanel:isVisible() then
        myOffersPanel:setVisible(false)
        if contentPanel then contentPanel:setVisible(true) end
    end
    if marketHistoryPanel and marketHistoryPanel.isVisible and marketHistoryPanel:isVisible() then
        marketHistoryPanel:setVisible(false)
        if mainMarket then mainMarket:setVisible(true) end
    end

    if detailsMarket and detailsMarket:isVisible() then
        detailsMarket:setVisible(false)
    end
    if mainMarket then
        mainMarket:setVisible(true)
    end

    if marketButton then marketButton:setVisible(false) end
    if closeButton then closeButton:setVisible(true) end

    lastKnownTab = 'market offers'
    Market.refreshOffers()

    -- Compat: ao retornar ao mercado, re-browsar último item
    if lastItemID ~= 0 then
        local tierToUse = nil
        if g_game.getFeature and g_game.getFeature(GameThingUpgradeClassification) and lastItemTier ~= nil then
            tierToUse = lastItemTier
        end
        -- Respeitar último tier (inclusive 0) quando disponível; caso contrário, navegação base
        if tierToUse ~= nil then
            MarketProtocol.sendMarketBrowse(MarketRequest.BrowseItem, lastItemID, tierToUse)
        else
            MarketProtocol.sendMarketBrowse(MarketRequest.BrowseItem, lastItemID)
        end
    end
end

function detailsButton()
    if not marketWindow then return end
    local mainMarket = marketWindow:recursiveGetChildById('mainMarket')
    local detailsMarket = marketWindow:recursiveGetChildById('detailsMarket')
    local closeButton = marketWindow:recursiveGetChildById('closeButton')
    local marketButton = marketWindow:recursiveGetChildById('marketButton')
    local contentPanel = marketWindow:getChildById('contentPanel')

    -- Ensure we are in the main content area
    if myOffersPanel and myOffersPanel.isVisible and myOffersPanel:isVisible() then
        myOffersPanel:setVisible(false)
        if contentPanel then contentPanel:setVisible(true) end
    end

    if not detailsMarket or not mainMarket then return end

    if detailsMarket:isVisible() then
        -- Toggle back to offers view
        detailsMarket:setVisible(false)
        mainMarket:setVisible(true)
        if marketButton then marketButton:setVisible(false) end
        if closeButton then closeButton:setVisible(true) end
    else
        -- Show details panel
        mainMarket:setVisible(false)
        detailsMarket:setVisible(true)
        if marketButton then marketButton:setVisible(true) end
        if closeButton then closeButton:setVisible(false) end
    end

    lastKnownTab = 'market offers'
end

local function ensureMyOffersOverlay()
    -- Build a lightweight My Offers overlay when tab bars are not present
    if myOffersPanel and myOffersPanel.destroyed ~= true then return end
    if not marketWindow then return end

    -- Attach overlay inside contentPanel to inherit sizing/anchors
    local contentPanel = marketWindow:getChildById('contentPanel')
    local parentForOverlay = contentPanel or marketWindow
    -- Create the container from existing UI file and attach to parent
    myOffersPanel = g_ui.loadUI('ui/myoffers', parentForOverlay)
    if not myOffersPanel then return end
    myOffersPanel:setVisible(false)

    offersTabBar = myOffersPanel:getChildById('offersTabBar')
    if offersTabBar and offersTabBar.setContentWidget then
        offersTabBar:setContentWidget(myOffersPanel:getChildById('offersTabContent'))
    end

    currentOffersPanel = g_ui.loadUI('ui/myoffers/currentoffers')
    if offersTabBar and currentOffersPanel then
        offersTabBar:addTab(tr('Current Offers'), currentOffersPanel)
    end

    offerHistoryPanel = g_ui.loadUI('ui/myoffers/offerhistory')
    if offersTabBar and offerHistoryPanel then
        offersTabBar:addTab(tr('Offer History'), offerHistoryPanel)
    end

    -- Wire tables and buttons if available
    if currentOffersPanel then
        buyMyOfferTable = currentOffersPanel:recursiveGetChildById('myBuyingTable')
        sellMyOfferTable = currentOffersPanel:recursiveGetChildById('mySellingTable')
        if buyMyOfferTable then buyMyOfferTable.onSelectionChange = onSelectMyBuyOffer end
        if sellMyOfferTable then sellMyOfferTable.onSelectionChange = onSelectMySellOffer end

        buyCancelButton = currentOffersPanel:getChildById('buyCancelButton')
        if buyCancelButton then
            buyCancelButton.onClick = function()
                cancelMyOffer(MarketAction.Buy)
            end
        end

        sellCancelButton = currentOffersPanel:getChildById('sellCancelButton')
        if sellCancelButton then
            sellCancelButton.onClick = function()
                cancelMyOffer(MarketAction.Sell)
            end
        end
    end
end

function myOffersButton(widget)
    if not marketWindow then return end
    local contentPanel = marketWindow:getChildById('contentPanel')
    local mainMarket = marketWindow:recursiveGetChildById('MarketMainWindow') or marketWindow:recursiveGetChildById('mainMarket')
    local detailsMarket = marketWindow:recursiveGetChildById('detailsMarket')
    local closeButton = marketWindow:recursiveGetChildById('closeButton')
    local marketButton = marketWindow:recursiveGetChildById('marketButton')

    -- Compat: acionar requisições de "Minhas Ofertas"/"Histórico" pelo fluxo antigo
    local id = widget and widget.getId and widget:getId() or 'myOffers'
    if g_game.sendMarketAction then
        if id == 'historyButton' then
            g_game.sendMarketAction(MarketRequest.MyHistory)
        else
            g_game.sendMarketAction(MarketRequest.MyOffers)
        end
    end

    -- Prefer tab bar behavior if present
    if mainTabBar then
        -- Switch to My Offers tab
        local myTab = mainTabBar.getTab and mainTabBar:getTab(tr('My Offers')) or nil
        if myTab and mainTabBar.selectTab then mainTabBar:selectTab(myTab) end
        -- Select sub-tab based on button
        if offersTabBar then
            if id == 'historyButton' then
                lastKnownTab, lastOfferTab = 'offer history'
                local histTab = offersTabBar.getTab and offersTabBar:getTab(tr('Offer History')) or nil
                if histTab and offersTabBar.selectTab then offersTabBar:selectTab(histTab) end
                Market.refreshOfferHistory()
            else
                lastKnownTab, lastOfferTab = 'current offers'
                local curTab = offersTabBar.getTab and offersTabBar:getTab(tr('Current Offers')) or nil
                if curTab and offersTabBar.selectTab then offersTabBar:selectTab(curTab) end
                Market.refreshMyOffers()
            end
        else
            Market.refreshMyOffers()
        end
        return
    end

    -- Prefer built-in MarketHistory overlay if present
    initMarketHistoryUI()
    if marketHistoryPanel then
        if mainMarket then mainMarket:setVisible(false) end
        if detailsMarket then detailsMarket:setVisible(false) end
        marketHistoryPanel:setVisible(true)
    else
        -- Fallback overlay for non-tab UI (old myoffers)
        ensureMyOffersOverlay()
        if not myOffersPanel then return end
        if mainMarket then mainMarket:setVisible(false) end
        if detailsMarket then detailsMarket:setVisible(false) end
        myOffersPanel:setVisible(true)
    end

    -- Toggle bottom-right buttons similar to classic
    if closeButton then closeButton:setVisible(false) end
    if marketButton then marketButton:setVisible(true) end

    local id = widget and widget.getId and widget:getId() or 'myOffers'
    if id == 'historyButton' then
        lastKnownTab, lastOfferTab = 'offer history'
        if marketHistoryPanel then
            Market.refreshOfferHistory()
        elseif offersTabBar and offersTabBar.getTab and offersTabBar.selectTab then
            local histTab = offersTabBar:getTab(tr('Offer History'))
            if histTab then offersTabBar:selectTab(histTab) end
        end
    else
        lastKnownTab, lastOfferTab = 'current offers'
        if marketHistoryPanel then
            Market.refreshMyOffers()
        elseif offersTabBar and offersTabBar.getTab and offersTabBar.selectTab then
            local curTab = offersTabBar:getTab(tr('Current Offers'))
            if curTab then offersTabBar:selectTab(curTab) end
        end
    end
end

local function initMarketItems()
    for c = MarketCategory.First, MarketCategory.Last do
        marketItems[c] = {}
    end

    -- save a list of items which are already added
    local itemSet = {}

    -- populate all market items
    local types = g_things.findThingTypeByAttr(ThingAttrMarket, 0)
    for i = 1, #types do
        local itemType = types[i]

        local item = Item.create(itemType:getId())
        if item then
            local marketData = itemType:getMarketData()
            if not table.empty(marketData) and not itemSet[marketData.tradeAs] then
                -- Some items use a different sprite in Market
                item:setId(marketData.showAs)

                -- create new marketItem block
                local marketItem = {
                    displayItem = item,
                    thingType = itemType,
                    marketData = marketData
                }

                -- add new market item
                if not marketItems[marketData.category] then
                    marketItems[marketData.category] = {}
                end

                table.insert(marketItems[marketData.category], marketItem)
                itemSet[marketData.tradeAs] = true
            end
        end
    end
end

local function initInterface()
    -- TODO: clean this up
    -- setup main tabs (fallback gracefully if not present in new UI)
    mainTabBar = marketWindow:getChildById('mainTabBar')
    if mainTabBar then
        mainTabBar:setContentWidget(marketWindow:getChildById('mainTabContent'))

        -- setup 'Market Offer' section tabs
        marketOffersPanel = g_ui.loadUI('ui/marketoffers')
        g_mouse.bindPress(mainTabBar:addTab(tr('Market Offers'), marketOffersPanel), function()
            lastKnownTab = 'market offers'
            if os.time() > refreshTimeout + 1 then
                refreshTimeout = os.time()
                Market.refreshOffers()
            else
                if updateEvent then
                    removeEvent(updateEvent)
                    updateEvent = nil
                end
                updateEvent = scheduleEvent(function()
                    Market.refreshMyOffers()
                    refreshTimeout = os.time()
                end, 500)
            end
        end, MouseLeftButton)

        selectionTabBar = marketOffersPanel:getChildById('leftTabBar')
        selectionTabBar:setContentWidget(marketOffersPanel:getChildById('leftTabContent'))

        browsePanel = g_ui.loadUI('ui/marketoffers/browse')
        selectionTabBar:addTab(tr('Browse'), browsePanel)

        -- Currently not used
        -- "Reserved for more functionality later"
        -- overviewPanel = g_ui.loadUI('ui/marketoffers/overview')
        -- selectionTabBar:addTab(tr('Overview'), overviewPanel)

        displaysTabBar = marketOffersPanel:getChildById('rightTabBar')
        displaysTabBar:setContentWidget(marketOffersPanel:getChildById('rightTabContent'))
    else
        -- New UI without tab bars: use marketWindow directly
        marketOffersPanel = marketWindow
        browsePanel = marketWindow
    end

    if displaysTabBar then
        itemStatsPanel = g_ui.loadUI('ui/marketoffers/itemstats')
        displaysTabBar:addTab(tr('Statistics'), itemStatsPanel)

        itemDetailsPanel = g_ui.loadUI('ui/marketoffers/itemdetails')
        displaysTabBar:addTab(tr('Details'), itemDetailsPanel)

        itemOffersPanel = g_ui.loadUI('ui/marketoffers/itemoffers')
        displaysTabBar:addTab(tr('Offers'), itemOffersPanel)
        displaysTabBar:selectTab(displaysTabBar:getTab(tr('Offers')))
    else
        -- Fallback: obtain offers area directly from new UI
        itemOffersPanel = marketWindow:recursiveGetChildById('mainMarket') or marketOffersPanel
    end

    -- Initialize MarketHistory overlay wiring if present
    initMarketHistoryUI()

    -- Removed 'My Offers' tab setup: personal offers now appear in main Offers

    -- Obtain balance label: try legacy id, then fallback to moneyPanel/gold
    balanceLabel = marketWindow:getChildById('balanceLabel')
    if not balanceLabel then
        local moneyPanel = marketWindow:recursiveGetChildById('moneyPanel')
        if moneyPanel and moneyPanel.getChildById then
            balanceLabel = moneyPanel:getChildById('gold')
        end
    end

    -- Obter label de Tibia Coins (painel de coins)
    coinsLabel = nil
    local coinPanel = marketWindow:recursiveGetChildById('coinPanel')
    if coinPanel and coinPanel.getChildById then
        coinsLabel = coinPanel:getChildById('gold')
    end
    updateCoinsLabel()
    attachStoreCoinsListener()

    local mainMarketButtons = marketWindow and marketWindow:recursiveGetChildById('mainMarket') or nil
    local newBuyButton = mainMarketButtons and mainMarketButtons:recursiveGetChildById('buyAcceptButton') or marketWindow and marketWindow:recursiveGetChildById('buyAcceptButton') or nil
    local newSellButton = mainMarketButtons and mainMarketButtons:recursiveGetChildById('sellAcceptButton') or marketWindow and marketWindow:recursiveGetChildById('sellAcceptButton') or nil

    buyButton = newBuyButton or itemOffersPanel:getChildById('buyButton')
    buyButton.onClick = function()
        openAmountWindow(Market.acceptMarketOffer, MarketAction.Sell, 'Sell')
    end

    sellButton = newSellButton or itemOffersPanel:getChildById('sellButton')
    sellButton.onClick = function()
        openAmountWindow(Market.acceptMarketOffer, MarketAction.Buy, 'Buy')
    end

    local mainMarket = getMainMarket()
    nameLabel = (marketOffersPanel and marketOffersPanel:getChildById('nameLabel'))
        or (mainMarket and mainMarket:recursiveGetChildById('nameLabel'))
        or marketWindow:recursiveGetChildById('nameLabel')
    selectedItem = (marketOffersPanel and marketOffersPanel:getChildById('selectedItem'))
        or (mainMarket and mainMarket:recursiveGetChildById('selectedItem'))
        or marketWindow:recursiveGetChildById('selectedItem')
    selectedItemCountLabel = (marketOffersPanel and marketOffersPanel:getChildById('selectedItemCount'))
        or (mainMarket and mainMarket:recursiveGetChildById('selectedItemCount'))
        or marketWindow:recursiveGetChildById('selectedItemCount')
    if selectedItemCountLabel then selectedItemCountLabel:setText('0') end

    do
        local main = getMainMarket()
        local sellCheck = (main and main:getChildById('createOfferSell')) or (marketOffersPanel and marketOffersPanel:getChildById('createOfferSell')) or nil
        local buyCheck  = (main and main:getChildById('createOfferBuy'))  or (marketOffersPanel and marketOffersPanel:getChildById('createOfferBuy'))  or nil
        local priceCreate = (main and main:getChildById('piecePriceCreate')) or (marketOffersPanel and marketOffersPanel:getChildById('piecePriceCreate')) or nil
        local createBtn   = (main and main:getChildById('createButton')) or (marketOffersPanel and marketOffersPanel:getChildById('createButton')) or nil
        if sellCheck then
            sellCheck.onClick = function(self) changeOfferType(self, true) end
            sellCheck.onCheckChange = function(self, checked) if checked then changeOfferType(self, true) end end
        end
        if buyCheck then
            buyCheck.onClick = function(self) changeOfferType(self, false) end
            buyCheck.onCheckChange = function(self, checked) if checked then changeOfferType(self, false) end end
        end
        if priceCreate then
            priceCreate.onTextChange = function(self) onPiecePriceEdit(self) end
            priceCreate.onEnter = function(self) onPiecePriceEdit(self) end
        end
        if sellCheck and buyCheck then
            sellCheck:setChecked(true)
            buyCheck:setChecked(false)
            currentActionType = 1
        else
        end
        if createBtn then
            createBtn.onClick = function() createMarketOffer() end
        end
    end

    totalPriceEdit = marketOffersPanel:getChildById('totalPriceEdit')
    piecePriceEdit = marketOffersPanel:getChildById('piecePriceEdit')
    amountEdit = marketOffersPanel:getChildById('amountEdit')
    feeLabel = (marketOffersPanel and marketOffersPanel:getChildById('feeLabel'))
        or (marketWindow and marketWindow:recursiveGetChildById('feeLabel')) or nil
    if totalPriceEdit then totalPriceEdit.onValueChange = onTotalPriceChange end
    if piecePriceEdit then piecePriceEdit.onValueChange = onPiecePriceChange end
    if amountEdit then amountEdit.onValueChange = onAmountChange end

    offerTypeList = marketOffersPanel and marketOffersPanel:getChildById('offerTypeComboBox') or nil
    if offerTypeList and offerTypeList.onOptionChange ~= nil then
        offerTypeList.onOptionChange = onChangeOfferType
    end

    anonymous = (marketOffersPanel and marketOffersPanel:getChildById('anonymousCheckBox'))
        or (marketWindow and marketWindow:recursiveGetChildById('anonymousCheckBox')) or nil
    createOfferButton = (marketOffersPanel and marketOffersPanel:getChildById('createOfferButton'))
        or (marketWindow and marketWindow:recursiveGetChildById('createOfferButton')) or nil
    -- Alias to handle accidental lowercase variable usage elsewhere
    if not createofferButton and createOfferButton then
        createofferButton = createOfferButton
    end
    if createOfferButton then
        createOfferButton.onClick = Market.createNewOffer
    end
    Market.enableCreateOffer(false)

    -- setup filters
    filterButtons[MarketFilters.Vocation] = browsePanel:getChildById('filterVocation')
    filterButtons[MarketFilters.Level] = browsePanel:getChildById('filterLevel')
    filterButtons[MarketFilters.Depot] = browsePanel:getChildById('filterDepot')
    filterButtons[MarketFilters.SearchAll] = browsePanel:getChildById('filterSearchAll')

    -- set filter default values
    clearFilters()

    -- hook filters
    for _, filter in pairs(filterButtons) do
        filter.onCheckChange = Market.updateCurrentItems
    end

    -- prefer new UI search widget if available
    searchEdit = (marketWindow and marketWindow:recursiveGetChildById('searchText')) or browsePanel:getChildById('searchEdit')
    if searchEdit and searchEdit.onTextChange ~= nil then
        searchEdit.onTextChange = function()
            Market.updateCurrentItems()
        end
    end
    categoryList = browsePanel and browsePanel:getChildById('categoryComboBox') or nil
    subCategoryList = browsePanel and browsePanel:getChildById('subCategoryComboBox') or nil
    slotFilterList = browsePanel and browsePanel:getChildById('slotComboBox') or nil

    if slotFilterList then
        slotFilterList:addOption(MarketSlotFilters[255])
        slotFilterList:setEnabled(false)
    end

    for i = MarketCategory.First, MarketCategory.Last do
        if i >= MarketCategory.Ammunition and i <= MarketCategory.WandsRods then
            if subCategoryList then subCategoryList:addOption(getMarketCategoryName(i)) end
        else
            if categoryList then categoryList:addOption(getMarketCategoryName(i)) end
        end
    end
    if categoryList then
        categoryList:addOption(getMarketCategoryName(255)) -- meta weapons
        categoryList:setCurrentOption(getMarketCategoryName(MarketCategory.First))
    end
    if subCategoryList then subCategoryList:setEnabled(false) end

    -- New UI category list population and hook (if present)
    local categoryTextList = marketWindow and marketWindow:recursiveGetChildById('category') or nil
    categoryScroll = marketWindow and marketWindow:recursiveGetChildById('categoryScroll') or nil
    if categoryTextList then
    if categoryTextList.destroyChildren then categoryTextList:destroyChildren() end
    local idx = 0

    -- cor base do texto e paleta alternada
    local COLOR_TEXT = '#c0c0c0'
    local COLOR_ROW_1 = '#484848' -- linha ímpar
    local COLOR_ROW_2 = '#414141' -- linha par
    local COLOR_HOVER = '#5a5a5a' -- mouse sobre
    local COLOR_SELECTED = '#6a6a6a' -- item clicado (fixo)

    local selectedLabel = nil -- referência ao item selecionado

    for c = MarketCategory.First, MarketCategory.Last do
        idx = idx + 1
        local lbl = g_ui.createWidget('Label', categoryTextList)
        lbl:setText(getMarketCategoryName(c))
        lbl:setFocusable(true)
        lbl:setHeight(16)
        lbl:setWidth(categoryTextList:getWidth() - 2)
        lbl:setMarginTop(0)
        lbl:setColor(COLOR_TEXT)
        lbl:setPhantom(false)

        -- alternância de fundo
        local baseColor = (idx % 2 == 1) and COLOR_ROW_1 or COLOR_ROW_2
        lbl:setBackgroundColor(baseColor)

        -- evento de hover (mouse passa por cima)
        function lbl:onHoverChange(hovered)
            if hovered then
                if selectedLabel ~= self then
                    self:setBackgroundColor(COLOR_HOVER)
                end
            else
                if selectedLabel ~= self then
                    self:setBackgroundColor(baseColor)
                end
            end
        end

        -- evento de clique (selecionar fixo)
        function lbl:onClick()
            -- garante foco visual e navegação
            local parent = self:getParent()
            if parent and parent.focusChild then parent:focusChild(self, KeyboardFocusReason) end
            if parent and parent.ensureChildVisible then parent:ensureChildVisible(self) end
            -- limpa seleção anterior
            if selectedLabel and selectedLabel ~= self then
                local prevBase = (selectedLabel.index % 2 == 1) and COLOR_ROW_1 or COLOR_ROW_2
                selectedLabel:setBackgroundColor(prevBase)
                selectedLabel:setColor(COLOR_TEXT)
            end
            -- marca o novo
            selectedLabel = self
            self:setBackgroundColor(COLOR_SELECTED)
            self:setColor('white')
            Market.updateCurrentItems()
        end

        lbl.index = idx
    end

    -- atualiza itens quando o foco muda (setas do teclado, foco programático)
    if categoryTextList and categoryTextList.setFocusable then categoryTextList:setFocusable(true) end
    categoryTextList.onChildFocusChange = function(parent, focused, unfocused)
        if unfocused and unfocused.index then
            local prevBase = (unfocused.index % 2 == 1) and COLOR_ROW_1 or COLOR_ROW_2
            unfocused:setBackgroundColor(prevBase)
            unfocused:setColor(COLOR_TEXT)
        end
        if focused then
            selectedLabel = focused
            focused:setBackgroundColor(COLOR_SELECTED)
            focused:setColor('white')
            if parent and parent.ensureChildVisible then parent:ensureChildVisible(focused) end
            -- Atualiza itens SOMENTE quando um novo rótulo de categoria ganha foco
            Market.updateCurrentItems()
        end
        -- Evitar recarregar itens quando a lista de categorias perde foco (focused == nil)
    end

    -- também atualiza lista ao mover a barra
    if categoryScroll and categoryScroll.onValueChange ~= nil then
        categoryScroll.onValueChange = function(self)
            Market.updateCurrentItems()
        end
    end

    -- foco inicial
    if categoryTextList:getChildCount() > 0 then
        local first = categoryTextList:getChildByIndex(1)
        if first then
            categoryTextList:focusChild(first, KeyboardFocusReason)
            categoryTextList:ensureChildVisible(first)
        end
    end
end



    -- hook item filters
    if categoryList then categoryList.onOptionChange = onChangeCategory end
    if subCategoryList then subCategoryList.onOptionChange = onChangeSubCategory end
    if slotFilterList then slotFilterList.onOptionChange = onChangeSlotFilter end

    -- New UI filter controls: vocation, tier, 1H, 2H
    vocButton = marketWindow and marketWindow:recursiveGetChildById('vocButton') or nil
    oneButton = marketWindow and marketWindow:recursiveGetChildById('oneButton') or nil
    twoButton = marketWindow and marketWindow:recursiveGetChildById('twoButton') or nil
    tierFilterCombo = marketWindow and marketWindow:recursiveGetChildById('tierFilter') or nil
    -- Popular combobox de Tier com todas as opções (Tier 0..10)
    if tierFilterCombo and tierFilterCombo.clearOptions and tierFilterCombo.addOption then
        tierFilterCombo:clearOptions()
        for t = 0, 10 do
            tierFilterCombo:addOption('Tier ' .. tostring(t), t)
        end
        if tierFilterCombo.setCurrentIndex then tierFilterCombo:setCurrentIndex(1) end -- seleciona 'Tier 0'
    end
    -- Popular combobox de Classe com valores disponíveis
    classFilterCombo = marketWindow and marketWindow:recursiveGetChildById('classFilter') or nil
    if classFilterCombo and classFilterCombo.clearOptions and classFilterCombo.addOption then
        classFilterCombo:clearOptions()
        classFilterCombo:addOption('All', 0)
        -- Fixed classification options: Class 1 .. Class 4
        for cls = 1, 4 do
            classFilterCombo:addOption('Class ' .. tostring(cls), cls)
        end
        if classFilterCombo.setCurrentIndex then classFilterCombo:setCurrentIndex(1) end -- All
        classFilterCombo.onOptionChange = function(self)
            suppressLegacyAutoBrowse = true
            Market.updateCurrentItems()
            suppressLegacyAutoBrowse = false

            -- Atualiza overlay de tier no item selecionado conforme filtros atuais
            if Market.isItemSelected() and selectedItem and ItemsDatabase and ItemsDatabase.setTier and tierFilterCombo and tierFilterCombo.getCurrentOption then
                local opt = tierFilterCombo:getCurrentOption()
                local text = opt and opt.text or ''
                local num = text:match('%d+')
                local selTier = tonumber(num or 0) or 0
                local itemType = selectedItem.item and selectedItem.item.thingType or nil
                local cls = (itemType and itemType.getClassification) and tonumber(itemType:getClassification()) or 0
                local showTier = (selTier > 0 and cls > 0) and selTier or 0
                ItemsDatabase.setTier(selectedItem, showTier)
            end
        end
    end
    levelButton = marketWindow and marketWindow:recursiveGetChildById('levelButton') or nil
    lockerOnlyButton = marketWindow and marketWindow:recursiveGetChildById('lockerOnly') or nil

    if vocButton then
        vocButton.onClick = function(self) onSortMarketFields(self) end
    end
    if tierFilterCombo then
        tierFilterCombo.onOptionChange = function(self)
            -- Debounce: evita múltiplas atualizações e navegações em sequência
            if tierUpdateEvent then
                removeEvent(tierUpdateEvent)
                tierUpdateEvent = nil
            end
            tierUpdateEvent = scheduleEvent(function()
                -- Atualiza a lista de itens (UI) para refletir o filtro visual
                suppressLegacyAutoBrowse = true
                Market.updateCurrentItems()
                suppressLegacyAutoBrowse = false

                -- Se houver item selecionado, refaz o browse com o tier escolhido
                local selTier = 0
                local opt = tierFilterCombo.getCurrentOption and tierFilterCombo:getCurrentOption() or nil
                local text = opt and opt.text or ''
                local num = text:match('%d+')
                selTier = tonumber(num or 0) or 0

                -- Atualiza overlay do item selecionado, se aplicável, conforme o filtro
                do
                    if Market.isItemSelected() and selectedItem and ItemsDatabase and ItemsDatabase.setTier then
                        local itemType = selectedItem.item and selectedItem.item.thingType or nil
                        local cls = (itemType and itemType.getClassification) and tonumber(itemType:getClassification()) or 0
                        local showTier = (selTier > 0 and cls > 0) and selTier or 0
                        ItemsDatabase.setTier(selectedItem, showTier)
                    end
                end

                if Market.isItemSelected() and selectedItem and selectedItem.item and selectedItem.item.marketData then
                    local itemId = selectedItem.item.marketData.tradeAs
                    if g_game.getFeature and g_game.getFeature(GameThingUpgradeClassification) then
                        local itemType = selectedItem.item and selectedItem.item.thingType or nil
                        local cls = (itemType and itemType.getClassification) and tonumber(itemType:getClassification()) or 0
                        if cls and cls > 0 then
                            lastItemTier = selTier
                            MarketOffers2 = {}
                            marketOffers[MarketAction.Buy] = {}
                            marketOffers[MarketAction.Sell] = {}
                            MarketProtocol.sendMarketBrowse(MarketRequest.BrowseItem, itemId, selTier)
                            return
                        end
                    end
                    -- Item não-classificado: navegação base sem tier
                    lastItemTier = nil
                    MarketOffers2 = {}
                    marketOffers[MarketAction.Buy] = {}
                    marketOffers[MarketAction.Sell] = {}
                    MarketProtocol.sendMarketBrowse(MarketRequest.BrowseItem, itemId)
                end
            end, 200)
        end
    end
    if levelButton then
        levelButton.onClick = function(self) onSortMarketFields(self) end
    end
    if lockerOnlyButton then
        lockerOnlyButton.onCheckChange = function(self)
            Market.updateCurrentItems()
        end
    end
    if oneButton and twoButton then
        oneButton.onClick = function(self) onSortMarketFields(self) end
        twoButton.onClick = function(self) onSortMarketFields(self) end
    end

    -- Sincronizar estado visual inicial dos botões de filtro
    if vocButton and vocButton.setChecked then vocButton:setChecked(vocFilterActive) end
    if levelButton and levelButton.setChecked then levelButton:setChecked(levelFilterActive) end
    if oneButton and oneButton.setChecked then oneButton:setChecked(oneFilterActive) end
    if twoButton and twoButton.setChecked then twoButton:setChecked(twoFilterActive) end

    -- setup tables (support new UI lists if present)
    -- Escopo correto: procure as listas DENTRO do painel de Ofertas (itemOffersPanel).
    -- Várias telas usam ids duplicados (ex.: MarketHistory também tem 'sellOffersList'/'buyOffersList').
    -- Se buscarmos no container principal, podemos pegar a lista errada. Por isso, limite ao itemOffersPanel.
    local mainPanel = getMainMarket()
    local offersScope = itemOffersPanel or mainPanel
    local newSellList = offersScope and offersScope:recursiveGetChildById('sellOffersList') or nil
    local newBuyList = offersScope and offersScope:recursiveGetChildById('buyOffersList') or nil
    -- Logar para diagnosticar possíveis conflitos de ids
    -- Removidos logs de depuração sobre escopo de listas

    if newBuyList and newSellList then
        buyOfferTable = newBuyList
        sellOfferTable = newSellList
        -- Focus-change for list-based UI
        buyOfferTable.onChildFocusChange = function(self, selected, oldFocus)
            onSelectBuyOffer(self, selected, oldFocus)
        end
        sellOfferTable.onChildFocusChange = function(self, selected, oldFocus)
            onSelectSellOffer(self, selected, oldFocus)
        end
    else
        -- fallback to legacy tables
        buyOfferTable = itemOffersPanel:recursiveGetChildById('buyingTable')
        sellOfferTable = itemOffersPanel:recursiveGetChildById('sellingTable')
        buyOfferTable.onSelectionChange = onSelectBuyOffer
        sellOfferTable.onSelectionChange = onSelectSellOffer
    end

    detailsTable = (itemDetailsPanel and itemDetailsPanel:recursiveGetChildById('detailsTable'))
        or (marketWindow and marketWindow:recursiveGetChildById('detailsTable')) or nil
    buyStatsTable = (itemStatsPanel and itemStatsPanel:recursiveGetChildById('buyStatsTable'))
        or (marketWindow and marketWindow:recursiveGetChildById('buyStatsTable')) or nil
    sellStatsTable = (itemStatsPanel and itemStatsPanel:recursiveGetChildById('sellStatsTable'))
        or (marketWindow and marketWindow:recursiveGetChildById('sellStatsTable')) or nil

    -- setup my offers
    if currentOffersPanel then
        buyMyOfferTable = currentOffersPanel:recursiveGetChildById('myBuyingTable')
        sellMyOfferTable = currentOffersPanel:recursiveGetChildById('mySellingTable')
        if buyMyOfferTable then buyMyOfferTable.onSelectionChange = onSelectMyBuyOffer end
        if sellMyOfferTable then sellMyOfferTable.onSelectionChange = onSelectMySellOffer end

        buyCancelButton = currentOffersPanel:getChildById('buyCancelButton')
        if buyCancelButton then
            buyCancelButton.onClick = function()
                cancelMyOffer(MarketAction.Buy)
            end
        end

        sellCancelButton = currentOffersPanel:getChildById('sellCancelButton')
        if sellCancelButton then
            sellCancelButton.onClick = function()
                cancelMyOffer(MarketAction.Sell)
            end
        end
    else
        buyMyOfferTable, sellMyOfferTable = nil, nil
        buyCancelButton, sellCancelButton = nil, nil
    end

    if buyStatsTable and buyStatsTable.setColumnWidth then
        buyStatsTable:setColumnWidth({120, 270})
    end
    if sellStatsTable and sellStatsTable.setColumnWidth then
        sellStatsTable:setColumnWidth({120, 270})
    end
    if detailsTable and detailsTable.setColumnWidth then
        detailsTable:setColumnWidth({80, 330})
    end

    if buyOfferTable and buyOfferTable.setSorting then
        buyOfferTable:setSorting(4, TABLE_SORTING_DESC)
    end
    if sellOfferTable and sellOfferTable.setSorting then
        sellOfferTable:setSorting(4, TABLE_SORTING_ASC)
    end

    if buyMyOfferTable and buyMyOfferTable.setSorting then
        buyMyOfferTable:setSorting(3, TABLE_SORTING_DESC)
    end
    if sellMyOfferTable and sellMyOfferTable.setSorting then
        sellMyOfferTable:setSorting(3, TABLE_SORTING_DESC)
    end

    -- setup my history (guarded for UIs without this panel)
    if offerHistoryPanel then
        buyMyHistoryTable = offerHistoryPanel:recursiveGetChildById('myHistoryBuyingTable')
        sellMyHistoryTable = offerHistoryPanel:recursiveGetChildById('myHistorySellingTable')
        if buyMyHistoryTable and buyMyHistoryTable.setSorting then
            buyMyHistoryTable:setSorting(3, TABLE_SORTING_DESC)
        end
        if sellMyHistoryTable and sellMyHistoryTable.setSorting then
            sellMyHistoryTable:setSorting(3, TABLE_SORTING_DESC)
        end
    else
        buyMyHistoryTable, sellMyHistoryTable = nil, nil
    end
end

function init()
    g_ui.importStyle('market')
    g_ui.importStyle('ui/general/markettabs')
    g_ui.importStyle('ui/general/marketbuttons')
    g_ui.importStyle('ui/general/marketcombobox')
    g_ui.importStyle('ui/general/amountwindow')

    offerExhaust[MarketAction.Sell] = 10
    offerExhaust[MarketAction.Buy] = 20

    registerMessageMode(MessageModes.Market, onMarketMessage)

    protocol.initProtocol()
    connect(g_game, {
        onGameEnd = Market.reset,
        onMarketEnter = Market.onMarketEnter,
        onMarketBrowse = Market.onMarketBrowse,
        onMarketDetail = Market.onMarketDetail,
        onMarketReadOffer = Market.onMarketReadOffer,
        onMarketLeave = Market.onMarketLeave,
        onResourcesBalanceChange = Market.onResourcesBalanceChange
    })
    connect(g_game, {
        onGameEnd = Market.close
    })
    marketWindow = g_ui.createWidget('MarketWindow', rootWidget)
    marketWindow:hide()

    initInterface() -- build interface
end

function terminate()
    Market.close()

    unregisterMessageMode(MessageModes.Market, onMarketMessage)

    protocol.terminateProtocol()
    disconnect(g_game, {
        onGameEnd = Market.reset,
        onMarketEnter = Market.onMarketEnter,
        onMarketBrowse = Market.onMarketBrowse,
        onMarketDetail = Market.onMarketDetail,
        onMarketReadOffer = Market.onMarketReadOffer,
        onMarketLeave = Market.onMarketLeave,
        onResourcesBalanceChange = Market.onResourcesBalanceChange
    })
    disconnect(g_game, {
        onGameEnd = Market.close
    })

    destroyAmountWindow()
    marketWindow:destroy()

    Market = nil
end

function Market.reset()
    if balanceLabel and balanceLabel.setColor then
        balanceLabel:setColor('#bbbbbb')
    end
    -- Prefer new UI category list; otherwise, legacy combo box
    local categoryTextList = marketWindow and marketWindow:recursiveGetChildById('category') or nil
    if categoryTextList and categoryTextList.getFocusedChild then
        -- No direct selection API; just reload items for first category
        -- to ensure UI state is consistent
        -- The actual focus will be managed by updateCurrentItems when needed
        -- so we default to First here.
        -- (If needed, later we can try to focus first child.)
        -- do nothing here, selection handled by update
    elseif categoryList and categoryList.setCurrentOption then
        categoryList:setCurrentOption(getMarketCategoryName(MarketCategory.First))
    end
    if searchEdit and searchEdit.setText then
        searchEdit:setText('')
    end
    clearFilters()
    clearMyOffers()
    if not table.empty(information) then
        Market.updateCurrentItems()
    end
end

function Market.displayMessage(message)
    -- Always show feedback; some UIs may report isHidden incorrectly
    local infoBox = displayInfoBox(tr('Market'), message)
    infoBox:lock()
end

function Market.clearSelectedItem()
    if Market.isItemSelected() then
        Market.resetCreateOffer(true)
        if offerTypeList then
            offerTypeList:clearOptions()
            offerTypeList:setText('Please Select')
            offerTypeList:setEnabled(false)
        end

        clearOffers()
        radioItemSet:selectWidget(nil)
    if nameLabel then nameLabel:setText('No item selected.') end
        selectedItem:setItem(nil)
        if ItemsDatabase and ItemsDatabase.setTier then ItemsDatabase.setTier(selectedItem, 0) end
        if selectedItem.setItemCount then selectedItem:setItemCount(0) end
        selectedItem.item = nil
        selectedItem.ref:setChecked(false)
        selectedItem.ref = nil
        if selectedItemCountLabel then selectedItemCountLabel:setText('0') end

        if detailsTable then detailsTable:clearData() end
        if buyStatsTable then buyStatsTable:clearData() end
        if sellStatsTable then sellStatsTable:clearData() end

        Market.enableCreateOffer(false)
    end
end

function Market.isItemSelected()
    return selectedItem and selectedItem.item
end

function Market.isOfferSelected(type)
    return selectedOffer[type] and not selectedOffer[type]:isNull()
end

function Market.getDepotCount(itemId)
    return information.depotItems[itemId] and information.depotItems[itemId].itemCount or 0
end

function Market.enableCreateOffer(enable)
    if offerTypeList then offerTypeList:setEnabled(enable) end
    if totalPriceEdit then totalPriceEdit:setEnabled(enable) end
    if piecePriceEdit then piecePriceEdit:setEnabled(enable) end
    if amountEdit then amountEdit:setEnabled(enable) end
    if anonymous then anonymous:setEnabled(enable) end
    if createOfferButton then createOfferButton:setEnabled(enable) end

    local prevAmountButton = marketOffersPanel:recursiveGetChildById('prevAmountButton')
    local nextAmountButton = marketOffersPanel:recursiveGetChildById('nextAmountButton')

    if prevAmountButton then prevAmountButton:setEnabled(enable) end
    if nextAmountButton then nextAmountButton:setEnabled(enable) end
end

function Market.close(notify)
    if notify == nil then
        notify = true
    end
    if not marketWindow:isHidden() then
        marketWindow:hide()
        --[[ marketWindow:unlock() ]]
        modules.game_interface.getRootPanel():focus()
        Market.clearSelectedItem()
        Market.reset()
        if notify then
            g_game.leaveMarket()
        end
    end
end

function Market.incrementAmount()
    if not amountEdit then return end
    amountEdit:setValue(amountEdit:getValue() + 1)
end

function Market.decrementAmount()
    if not amountEdit then return end
    amountEdit:setValue(amountEdit:getValue() - 1)
end

function Market.updateCurrentItems()
    local id = MarketCategory.First
    -- prefer new UI category TextList selection
    local categoryTextList = marketWindow and marketWindow:recursiveGetChildById('category') or nil
    if categoryTextList and categoryTextList.getFocusedChild then
        local selected = categoryTextList:getFocusedChild()
        local name = selected and selected.getText and selected:getText()
        if name then
            id = getMarketCategoryId(name) or id
        end
    else
        -- Legacy combo boxes (guarded)
        if categoryList and categoryList.getCurrentOption then
            local opt = categoryList:getCurrentOption()
            local text = opt and opt.text or nil
            if text then
                id = getMarketCategoryId(text) or id
            end
        end
        if id == MarketCategory.MetaWeapons and subCategoryList and subCategoryList.getCurrentOption then
            local sobj = subCategoryList:getCurrentOption()
            local stext = sobj and sobj.text or nil
            if stext then
                id = getMarketCategoryId(stext) or id
            end
        end
    end
    -- Enable 1H/2H toggles only for weapon categories
    if oneButton and twoButton then
        local enable = (id >= MarketCategory.Ammunition and id <= MarketCategory.WandsRods)
        oneButton:setEnabled(enable)
        twoButton:setEnabled(enable)
        if not enable then
            oneButton:setChecked(false)
            twoButton:setChecked(false)
        end
    end
    Market.loadMarketItems(id)
end

function Market.resetCreateOffer(resetFee)
    if piecePriceEdit then piecePriceEdit:setValue(0) end
    if totalPriceEdit then totalPriceEdit:setValue(0) end
    if amountEdit then amountEdit:setValue(1) end
    refreshTypeList()

    if resetFee then
        clearFee()
    else
        updateFee(0, 0)
    end
end

function Market.refreshItemsWidget(selectItem)
    -- Preserve current items scrollbar value to avoid jump-to-top after refresh
    local rootForScroll = marketWindow or getMainMarket()
    -- Try the new UI scrollbar id first, fallback to legacy id
    local vItemsScroll = rootForScroll and (rootForScroll:recursiveGetChildById('itemsPanelListScrollBar') or rootForScroll:recursiveGetChildById('itemListScroll')) or nil
    local prevScrollVal = 0
    if vItemsScroll and vItemsScroll.getValue then
        prevScrollVal = vItemsScroll:getValue()
    end
    -- Prefer a snapshot captured at click time if available
    if lastIntendedScrollVal ~= nil then
        prevScrollVal = lastIntendedScrollVal
    end
    -- Track the currently selected item id so we can keep it visible post-refresh
    local selectedTradeAs = nil
    if selectedItem and selectedItem.item and selectedItem.item.marketData then
        selectedTradeAs = selectedItem.item.marketData.tradeAs
    end
    local selectItem = selectItem or 0
    -- Prefer new UI item list if present
    local newItems = marketWindow and marketWindow:recursiveGetChildById('itemList') or nil
    local useList = newItems ~= nil
    itemsPanel = newItems or browsePanel:recursiveGetChildById('itemsPanel')
    if itemsPanel and itemsPanel.setPhantom then itemsPanel:setPhantom(false) end
    if itemsPanel and itemsPanel.setFocusable then itemsPanel:setFocusable(true) end

    local layout = itemsPanel.getLayout and itemsPanel:getLayout() or nil
    if layout then layout:disableUpdates() end

    Market.clearSelectedItem()
    if itemsPanel.destroyChildren then itemsPanel:destroyChildren() end

    if radioItemSet then
        radioItemSet:destroy()
    end
    radioItemSet = UIRadioGroup.create()

    local toFocus = nil
    local selectedIndex = nil
    for i = 1, #currentItems do
        local item = currentItems[i]
        local w
            if useList then
                w = g_ui.createWidget('MarketItemList', itemsPanel)
                if w.setPhantom then w:setPhantom(false) end
                if w.setFocusable then w:setFocusable(true) end
                w.item = item
                local itemWidget = w:getChildById('item')
                itemWidget:setItem(item.displayItem)
                -- Exibir ícone de Tier condicionado ao filtro selecionado (apenas itens com aquele tier)
                do
                local cls = (item and item.thingType and item.thingType.getClassification) and tonumber(item.thingType:getClassification()) or 0
                local selectedTier = 0
                if tierFilterCombo and tierFilterCombo.getCurrentOption then
                    local opt = tierFilterCombo:getCurrentOption()
                    local text = opt and opt.text or ''
                    local num = text:match('%d+')
                    selectedTier = tonumber(num or 0) or 0
                end
                if ItemsDatabase and ItemsDatabase.setTier then
                    local showTier = (selectedTier > 0 and cls > 0) and selectedTier or 0
                    ItemsDatabase.setTier(itemWidget, showTier)
                end
                end
                if itemWidget.setPhantom then itemWidget:setPhantom(false) end
                local nameLabel = w:getChildById('name')
                if nameLabel then nameLabel:setText(item.marketData.name) end
                if nameLabel and nameLabel.setPhantom then nameLabel:setPhantom(false) end
                -- Clique é tratado via OTUI (@onMousePress -> Market.onItemListPressed)
            else
                w = g_ui.createWidget('MarketItemBox', itemsPanel)
                w.onCheckChange = Market.onItemBoxChecked
                w.item = item
                local itemWidget = w:getChildById('item')
                itemWidget:setItem(item.displayItem)
                -- Exibir ícone de Tier condicionado ao filtro selecionado (apenas itens com aquele tier)
                do
                local cls = (item and item.thingType and item.thingType.getClassification) and tonumber(item.thingType:getClassification()) or 0
                local selectedTier = 0
                if tierFilterCombo and tierFilterCombo.getCurrentOption then
                    local opt = tierFilterCombo:getCurrentOption()
                    local text = opt and opt.text or ''
                    local num = text:match('%d+')
                    selectedTier = tonumber(num or 0) or 0
                end
                if ItemsDatabase and ItemsDatabase.setTier then
                    local showTier = (selectedTier > 0 and cls > 0) and selectedTier or 0
                    ItemsDatabase.setTier(itemWidget, showTier)
                end
                end
            end

        if selectItem > 0 and item.marketData.tradeAs == selectItem then
            toFocus = w
            selectItem = 0
        end
        if selectedTradeAs and item.marketData.tradeAs == selectedTradeAs then
            selectedIndex = i
            -- Restaurar foco no item previamente selecionado quando possível
            if not toFocus then toFocus = w end
        end

        local amount = Market.getDepotCount(item.marketData.tradeAs)
        local itemWidget = w:getChildById('item')
        if itemWidget then
            itemWidget:setText(tostring(amount or 0))
            itemWidget:setTextOffset(topoint('0 10'))
        end
        w:setTooltip('You have ' .. tostring(amount or 0) .. ' in your depot.')

        radioItemSet:addWidget(w)
    end

    -- Selection/focus handling
    if useList then
        -- Wire mouse wheel to the attached scrollbar for smooth scrolling
        local rootForScroll = marketWindow or getMainMarket()
        local vItemsScroll = rootForScroll and (rootForScroll:recursiveGetChildById('itemsPanelListScrollBar') or rootForScroll:recursiveGetChildById('itemListScroll')) or nil
        itemsPanel.onMouseWheel = function(self, mousePos, direction)
            if vItemsScroll and vItemsScroll.onMouseWheel then
                return vItemsScroll:onMouseWheel(mousePos, direction)
            end
            return false
        end
        itemsPanel.onChildFocusChange = function(self, selected, oldFocus)
            if suppressSelection then return end
            if selected then
                local md = selected.item and selected.item.marketData or nil
                local sid = md and md.tradeAs or -1
                local sname = md and md.name or 'unknown'
                -- Atualiza seleção e navega (browse) em mudanças de foco originadas por interação do usuário
                updateSelectedItem(selected)
            end
        end
        if prevScrollVal == 0 and not toFocus and itemsPanel.getFirstChild and itemsPanel.focusChild then
            -- Focar o primeiro item por padrão para evitar UI sem seleção
            local first = itemsPanel:getFirstChild()
            if first then
                suppressSelection = true
                silentSelection = true
                itemsPanel:focusChild(first)
                -- Preservar destaque visual mesmo em seleção programática
                updateSelectedItem(first)
                silentSelection = false
                suppressSelection = false
                -- Removido auto-browse: ofertas devem aparecer apenas ao clicar
            end
        elseif toFocus and itemsPanel.focusChild then
            suppressSelection = true
            silentSelection = true
            itemsPanel:focusChild(toFocus)
            -- Restaurar visual ao recarregar mantendo a seleção anterior
            updateSelectedItem(toFocus)
            silentSelection = false
            suppressSelection = false
            -- Removido auto-browse ao restaurar foco
        end
    else
        -- Garantir seleção/browse automático no layout antigo (MarketItemBox)
        if toFocus then
            -- Seleciona e marca o item focado, disparando navegação
            toFocus:setChecked(true)
            if not suppressLegacyAutoBrowse then
                Market.onItemBoxChecked(toFocus)
            end
        else
            local first
            if itemsPanel.getFirstChild then
                first = itemsPanel:getFirstChild()
            else
                local children = itemsPanel:getChildren()
                if children and #children > 0 then first = children[1] end
            end
            if first then
                first:setChecked(true)
                if not suppressLegacyAutoBrowse then
                    Market.onItemBoxChecked(first)
                end
            else
            end
        end
    end

    if layout then
        layout:enableUpdates()
        layout:update()
        -- Update items scrollbar metrics to match rendered children
        rootForScroll = marketWindow or getMainMarket()
        vItemsScroll = rootForScroll and (rootForScroll:recursiveGetChildById('itemsPanelListScrollBar') or rootForScroll:recursiveGetChildById('itemListScroll')) or nil
        if vItemsScroll then
            local children = itemsPanel and itemsPanel.getChildren and itemsPanel:getChildren() or {}
            local total = children and #children or 0
            local visible = 0
            if itemsPanel and itemsPanel.getHeight then
                visible = math.max(1, math.floor(itemsPanel:getHeight() / 36)) -- MarketItemList row height
            end
            if vItemsScroll.setVirtualChilds then vItemsScroll:setVirtualChilds(total) end
            if vItemsScroll.setVisibleItems then vItemsScroll:setVisibleItems(visible) end
            if vItemsScroll.setRange then vItemsScroll:setRange(0, math.max(0, total - visible)) end
            -- Restore previous scroll position within new range
            local maxVal = math.max(0, total - visible)
            local newVal = math.min(prevScrollVal, maxVal)
            -- If we have a selected index, ensure it remains visible
            if selectedIndex and visible and visible > 0 then
                local targetVal = math.max(0, math.min(maxVal, selectedIndex - visible))
                -- Prefer keeping the selected item fully in view when near the end
                newVal = math.max(newVal, targetVal)
            end
            if vItemsScroll.setValue then vItemsScroll:setValue(newVal) end
            -- Limpa snapshot para próximos cliques
            lastIntendedScrollVal = nil
            lastClickedTradeAs = nil
        end
    end
end

-- Explicit handler wired from OTUI MarketItemList @onMousePress
function Market.onItemListPressed(self, mousePos, button)
    if button ~= MouseLeftButton then return false end
    local name = (self.item and self.item.marketData and self.item.marketData.name) or 'unknown'
    local itemId = (self.item and self.item.marketData and self.item.marketData.tradeAs) or -1
    local parent = self:getParent()
    -- Snapshot do scroll neste caminho também
    local rootForScroll = marketWindow or getMainMarket()
    local vScroll = rootForScroll and (rootForScroll:recursiveGetChildById('itemsPanelListScrollBar') or rootForScroll:recursiveGetChildById('itemListScroll')) or nil
    if vScroll and vScroll.getValue then
        lastIntendedScrollVal = vScroll:getValue()
    end
    lastClickedTradeAs = self.item and self.item.marketData and self.item.marketData.tradeAs or nil
    if parent and parent.focusChild then parent:focusChild(self, KeyboardFocusReason) end
    if parent and parent.ensureChildVisible then parent:ensureChildVisible(self) end
    updateSelectedItem(self)
    -- Removido: chamada de debug inexistente que pode interromper o clique
    return true
end

function Market.refreshOffers()
    if (not lastKnownTab or lastKnownTab == 'market offers') then
        if Market.isItemSelected() and selectedItem.ref then
            Market.onItemBoxChecked(selectedItem.ref)
        else
            -- Fallback: selecionar primeiro item visível e disparar browse
            local first
            if itemsPanel then
                if itemsPanel.getFirstChild then
                    first = itemsPanel:getFirstChild()
                elseif itemsPanel.getChildren then
                    local children = itemsPanel:getChildren()
                    if children and #children > 0 then first = children[1] end
                end
            end
            if first then
                if first.setChecked then first:setChecked(true) end
                Market.onItemBoxChecked(first)
            else
            end
        end
    elseif lastKnownTab == 'current offers' then
        Market.refreshMyOffers()
    elseif lastKnownTab == 'offer history' then
        Market.refreshOfferHistory()
    end
end

function Market.refreshMyOffers()
    clearMyOffers()
        MarketProtocol.sendMarketBrowseMyOffers()
end

function Market.refreshOfferHistory()
    clearMyHistory()
    MarketProtocol.sendMarketBrowseOfferHistory()
end

function Market.loadMarketItems(category)
    clearItems()

-- check search filter (código seguro e corrigido)
local searchFilter = ""

if searchEdit and searchEdit.getText then
    searchFilter = searchEdit:getText() or ""
end

-- garante que searchFilter é string
if type(searchFilter) ~= "string" then
    searchFilter = ""
end

-- aplica filtro de busca
if searchFilter:len() > 2 then
    -- verifica tabela antes de acessar
    if filterButtons
        and MarketFilters
        and MarketFilters.SearchAll
        and filterButtons[MarketFilters.SearchAll]
        and filterButtons[MarketFilters.SearchAll].isChecked
        and filterButtons[MarketFilters.SearchAll]:isChecked() then

        category = MarketCategory and MarketCategory.All or nil
    end
end

    if category == MarketCategory.All then
        -- loop all categories
        for category = MarketCategory.First, MarketCategory.Last do
            for i = 1, #marketItems[category] do
                local item = marketItems[category][i]
                if isItemValid(item, category, searchFilter) then
                    table.insert(currentItems, item)
                end
            end
        end
    else
        if not marketItems[category] then
            return
        end
        -- loop specific category
        if not marketItems[category] then
            return
        end
        for i = 1, #marketItems[category] do
            local item = marketItems[category][i]
            if isItemValid(item, category, searchFilter) then
                table.insert(currentItems, item)
            end
        end
    end

    -- Removida ordenação por nível; comportamento voltou a filtrar

    Market.refreshItemsWidget()
end

function Market.createNewOffer()
    local type = 'Buy'
    if offerTypeList and offerTypeList.getCurrentOption then
        local opt = offerTypeList:getCurrentOption()
        if opt and opt.text then
            type = opt.text
        end
    end
    if type == 'Sell' then
        type = MarketAction.Sell
    else
        type = MarketAction.Buy
    end

    if not Market.isItemSelected() then
        return
    end

    local spriteId = selectedItem.item.marketData.tradeAs

    if not piecePriceEdit or not amountEdit then return end
    local piecePrice = piecePriceEdit:getValue()
    local amount = amountEdit:getValue()
    local anonymous = anonymous:isChecked() and 1 or 0

    -- error checking
    local errorMsg = ''
    if type == MarketAction.Buy then
        if information.balance < ((piecePrice * amount) + fee) then
            errorMsg = errorMsg .. 'Not enough balance to create this offer.\n'
        end
    elseif type == MarketAction.Sell then
        if information.balance < fee then
            errorMsg = errorMsg .. 'Not enough balance to create this offer.\n'
        end
        if Market.getDepotCount(spriteId) < amount then
            errorMsg = errorMsg .. 'Not enough items in your depot to create this offer.\n'
        end
    end

    if piecePriceEdit and piecePrice > piecePriceEdit.maximum then
        errorMsg = errorMsg .. 'Price is too high.\n'
    elseif piecePriceEdit and piecePrice < piecePriceEdit.minimum then
        errorMsg = errorMsg .. 'Price is too low.\n'
    end

    if amountEdit and amount > amountEdit.maximum then
        errorMsg = errorMsg .. 'Amount is too high.\n'
    elseif amountEdit and amount < amountEdit.minimum then
        errorMsg = errorMsg .. 'Amount is too low.\n'
    end

    if amount * piecePrice > MarketMaxPrice then
        errorMsg = errorMsg .. 'Total price is too high.\n'
    end

    if information.totalOffers >= MarketMaxOffers then
        errorMsg = errorMsg .. 'You cannot create more offers.\n'
    end

    local timeCheck = os.time() - lastCreatedOffer
    if timeCheck < offerExhaust[type] then
        local waitTime = math.ceil(offerExhaust[type] - timeCheck)
        errorMsg = errorMsg .. 'You must wait ' .. waitTime .. ' seconds before creating a new offer.\n'
    end

    if errorMsg ~= '' then
        Market.displayMessage(errorMsg)
        return
    end

    -- Determinar tier a enviar
    local itemTier = 0
    if g_game.getFeature and g_game.getFeature(GameThingUpgradeClassification) then
        -- Com recurso de classificação ativo: usar o tier selecionado quando o item for classificável
        local sel = 0
        if tierFilterCombo then
            local opt = tierFilterCombo.getCurrentOption and tierFilterCombo:getCurrentOption() or nil
            local text = opt and opt.text or ''
            local num = text:match('%d+')
            sel = tonumber(num or 0) or 0
        end
        if sel > 0 then
            local it = Item.create(spriteId)
            local cls = (it and it.getClassification) and tonumber(it:getClassification()) or 0
            if cls and cls > 0 then
                itemTier = sel
            else
                itemTier = 0
            end
        else
            itemTier = 0
        end
    else
        -- Recurso de classificação desativado: não enviar tier
        itemTier = 0
    end

    g_game.createMarketOffer(type, spriteId, itemTier, amount, piecePrice, anonymous)
    lastCreatedOffer = os.time()
    Market.resetCreateOffer()
end

function Market.acceptMarketOffer(amount, timestamp, counter)
    if timestamp > 0 and amount > 0 then
        g_game.acceptMarketOffer(timestamp, counter, amount)
        Market.refreshOffers()
    end
end

function Market.onItemBoxChecked(widget)
    if suppressSelection then return end
    if widget:isChecked() then
        updateSelectedItem(widget)
    end
end

-- protocol callback functions

function Market.onMarketEnter(depotItems, offers, balance, vocation)
  -- Compat: assinatura antiga (offerCount, items)
  if type(depotItems) == 'number' and type(offers) == 'table' and balance == nil then
    local offerCount = depotItems
    local items = offers
    offers = offerCount
    balance = -1
    vocation = -1

    -- Formato antigo que você usava: {itemId, tier, count}
    local converted = {}
    for i = 1, #items do
      local itemId = tonumber(items[i][1]) or 0
      local tier   = tonumber(items[i][2]) or 0
      local count  = tonumber(items[i][3]) or 0
      -- normaliza para {itemId, count, itemClass}
      table.insert(converted, { itemId, count, tier })
    end
    depotItems = converted
  end

  if not loaded then
    initMarketItems()
    loaded = true
  end

  -- Saldo
  do
    local player = g_game.getLocalPlayer()
    if balance == -1 then
      if player and player.getTotalMoney then
        updateBalance(player:getTotalMoney())
      else
        updateBalance(0)
      end
    else
      updateBalance(balance)
    end
    -- Atualiza Tibia Coins (transferíveis)
    updateCoinsLabel()
    attachStoreCoinsListener()
  end

  information.totalOffers = tonumber(offers) or 0
  local player = g_game.getLocalPlayer()
  if player then information.player = player end

  if vocation == -1 then
    if player then information.vocation = player:getVocation() end
  else
    information.vocation = vocation
  end

  -- Construção robusta do mapa de itens do depósito
  local depotItemsLua = {}
  local n = (type(depotItems) == 'table') and #depotItems or 0

  -- Depuração removida: evitar logs ruidosos ao entrar no mercado

  for i = 1, n do
    local row = depotItems[i]
    -- Aceita {itemId, count} OU {itemId, count, itemClass}
    local itemId  = tonumber(row[1]) or 0
    local count   = tonumber(row[2])
    local itClass = row[3] ~= nil and tonumber(row[3]) or nil

    -- Corrige count nil/ruim para 0 (não descarta a linha)
    if count == nil then count = 0 end
    if count < 0 then count = 0 end

    -- Se o server não mandou classificação, tenta descobrir localmente (opcional)
    if itClass == nil and g_game.getFeature and g_game.getFeature(GameThingUpgradeClassification) and itemId > 0 then
      local itType = (g_things and g_things.getItemType) and g_things:getItemType(itemId) or nil
      if itType and itType.getClassification then
        local cls = tonumber(itType:getClassification()) or 0
        itClass = (cls > 0) and cls or 0
      end
    end

    -- Não descarte a linha mesmo com count 0: alguns servers enviam 0 para apenas “conhecido no depósito”
    if itemId > 0 then
      if itClass ~= nil then
        depotItemsLua[itemId] = { itemCount = count, itemClass = itClass }
      else
        depotItemsLua[itemId] = { itemCount = count }
      end

      -- Logs detalhados removidos
    end
  end

  information.depotItems = depotItemsLua

  -- Gate visibility of classification-based controls based on server feature
  local hasClassification = (g_game.getFeature and g_game.getFeature(GameThingUpgradeClassification)) and true or false
  if tierFilterCombo and tierFilterCombo.setVisible then tierFilterCombo:setVisible(hasClassification) end
  if classFilterCombo and classFilterCombo.setVisible then classFilterCombo:setVisible(hasClassification) end

  -- Se nada veio, faz um fallback de UI para garantir que a janela não “suma”
  local hasAny = false
  for _ in pairs(depotItemsLua) do hasAny = true; break end
  -- Logs de tamanho removidos

  -- Atualiza a UI
  if Market.isItemSelected() and selectedItem and selectedItem.item and selectedItem.item.marketData then
    local spriteId = selectedItem.item.marketData.tradeAs
    MarketProtocol.silent(true)
    Market.refreshItemsWidget(spriteId)
    MarketProtocol.silent(false)
  else
    Market.refreshItemsWidget()
  end

  if table.empty(currentItems) then
    Market.loadMarketItems(MarketCategory.First)
  end

  if g_game.isOnline() then
    --[[ marketWindow:lock() ]]
    marketWindow:show()
  end
end


function Market.onMarketLeave()
    Market.close(false)
end

-- Compat: aceitar (itemID, tier, details, purchase, sale)
function Market.onMarketDetail(a, b, c, d, e)
    if e ~= nil then
        -- assinatura antiga
        local itemId = a
        local descriptions = c
        local purchaseStats = d
        local saleStats = e
        local tier = b
        updateDetails(itemId, descriptions, purchaseStats, saleStats)
    else
        updateDetails(a, b, c, d)
    end
end

MarketOffers2 = {}
-- Removido: funções de mock. O módulo passa a exibir apenas dados reais.

-- Compat: aceitar (itemID, tier, buyList, sellList)
function Market.onMarketBrowse(a, b, c, d)
    -- Depuração removida
    -- Legacy 4-arg payload: itemId, tier, buyList, sellList
    if type(a) == 'number' and type(b) == 'number' and type(c) == 'table' and type(d) == 'table' then
        local itemId, tier, buyList, sellList = a, b, c, d
        -- Navegação legado: atualizar última seleção e construir ofertas
        -- Compat: espelhar legado, lembrar última navegação
        lastItemID = itemId
        if tier and tier > 0 then
            lastItemTier = tier
        else
            lastItemTier = nil
        end
        local tmpOffers = {}
        for _, data in ipairs(buyList) do
            -- Corrige assinatura: último argumento é 'var'. No legado, marcamos como BrowseItem.
            table.insert(tmpOffers, MarketOffer.new({ data.timestamp, data.counter }, MarketAction.Buy, Item.create(itemId),
                data.amount, data.price, data.holder, MarketOfferState.Active, MarketRequest.BrowseItem, tier))
        end
        for _, data in ipairs(sellList) do
            -- Corrige assinatura: último argumento é 'var'. No legado, marcamos como BrowseItem.
            table.insert(tmpOffers, MarketOffer.new({ data.timestamp, data.counter }, MarketAction.Sell, Item.create(itemId),
                data.amount, data.price, data.holder, MarketOfferState.Active, MarketRequest.BrowseItem, tier))
        end
        -- Atualizar UI com ofertas legadas
        -- Usar apenas dados reais: mesmo vazio, atualiza UI para refletir estado
        updateOffers(tmpOffers)
        return
    end

    -- Aggregated 2-arg payload: intOffers[], nameOffers[]
    if type(a) == 'table' and type(b) == 'table' and c == nil and d == nil then
        local intOffers, nameOffers = a, b
        local tmpOffers = {}
        -- Each intOffer = { action, amount, counter, itemId, price, state, timestamp, var, itemTier }
        for i = 1, #intOffers do
            local io = intOffers[i]
            local action = io[1]
            local amount = io[2]
            local counter = io[3]
            local itemId = io[4]
            local price = io[5]
            local state = io[6]
            local timestamp = io[7]
            local var = io[8]
            local tier = io[9]
            local playerName = nameOffers[i] or ''
            table.insert(tmpOffers, MarketOffer.new({ timestamp, counter }, action, Item.create(itemId), amount, price, playerName, state, var, tier))
        end
        -- Atualizar UI com ofertas agregadas
        -- Usar apenas dados reais: mesmo vazio, atualiza UI para refletir estado
        updateOffers(tmpOffers)
        return
    end

    -- Streaming path: offers appended via onMarketReadOffer, then flushed here (no args)
    local tmpOffers = MarketOffers2
    MarketOffers2 = {}
    -- Flush de ofertas recebidas no caminho streaming
    -- Usar apenas dados reais: mesmo vazio, atualiza UI para refletir estado
    updateOffers(tmpOffers)
end

function Market.onMarketReadOffer(action, amount, counter, itemId, playerName, price, state, timestamp, var, itemTier)
    local offer = MarketOffer.new({timestamp, counter}, action, Item.create(itemId), amount, price, playerName, state, var, itemTier)
    table.insert(MarketOffers2, offer)

    -- Sem cache/local mock: todos os dados vêm do servidor

    -- Renderização imediata (streaming): criar o widget assim que a oferta chegar,
    -- sem esperar o flush de onMarketBrowse. O flush posterior apagará e
    -- repopulará corretamente, evitando duplicatas.
    -- Garantir que estruturas estejam inicializadas.
    if marketOffers == nil then marketOffers = {} end
    if marketOffers[MarketAction.Buy] == nil then marketOffers[MarketAction.Buy] = {} end
    if marketOffers[MarketAction.Sell] == nil then marketOffers[MarketAction.Sell] = {} end

    -- Se as listas já estiverem disponíveis, fazemos merge e criamos o widget.
    if (buyOfferTable or sellOfferTable) then
        mergeOffer(offer)
        -- Renderização imediata só se a tabela suportar addRow/createChild
        local function canRender(tbl)
            return tbl and (tbl.addRow or tbl.createChild)
        end
        local ok = false
        if action == MarketAction.Buy then ok = canRender(buyOfferTable) end
        if action == MarketAction.Sell then ok = canRender(sellOfferTable) end
        if ok then
            addOffer(offer, action)
        end
        -- Atualizar contadores visuais
        -- Atualizar contadores visuais em listas de histórico, se existirem
        local bCount = #(marketOffers[MarketAction.Buy])
        local sCount = #(marketOffers[MarketAction.Sell])
        if buyOffersLabel and buyOffersLabel.setText then
            buyOffersLabel:setText(tr('Buy Offers (%d):'):format(bCount))
        end
        if sellOffersLabel and sellOffersLabel.setText then
            sellOffersLabel:setText(tr('Sell Offers (%d):'):format(sCount))
        end
    end
end

function Market.onResourcesBalanceChange(value, oldBalance, resourceType)
    local player = g_game.getLocalPlayer()
    if not player then return end
    -- Atualizações de ouro (banco + equipado)
    if resourceType == ResourceTypes.BANK_BALANCE or resourceType == ResourceTypes.GOLD_EQUIPPED or resourceType <= 1 then
        if player.getTotalMoney then
            updateBalance(player:getTotalMoney())
        end
    -- Atualizações de Tibia Coins
    elseif resourceType == ResourceTypes.COIN_NORMAL or resourceType == ResourceTypes.COIN_TRANSFERRABLE then
        updateCoinsLabel()
    end
end
