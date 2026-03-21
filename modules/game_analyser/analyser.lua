analyserMiniWindow = nil
mainButton = nil
Analyser = {}
if not configPopupWindow then
  configPopupWindow = {}
end

openedWindows = {}

-- Função utilitária global: trunca texto ao tamanho máximo
function short_text(text, maxLen)
  if not text then return "" end
  if #text <= maxLen then return text end
  return string.sub(text, 1, maxLen) .. ".."
end

-- Função utilitária global: retorna o nome do item pelo ID
function getItemServerName(itemId)
  if not itemId then return "" end
  local itemType = g_things.getItemType(itemId)
  if not itemType then return "" end
  return itemType:getName() or ""
end

local analyserWindows = {
  huntingButton = 'styles/hunting',
  lootButton = 'styles/loot',
  supplyButton = 'styles/supply',
  impactButton = 'styles/impact',
  damageButton = 'styles/input',
  xpButton = 'styles/xp',
  dropButton = 'styles/droptracker',
  partyButton = 'styles/partyhunt',
  bossButton = 'styles/boss',
  miscButton = 'styles/misc'
}


ANALYZER_HEAL = 0
ANALYZER_DAMAGE_DEALT = 1
ANALYZER_DAMAGE_RECEIVED = 2
-- Utility function to get combat name from effect ID
function getCombatName(effectId)
  if not effectId then
    return "Unknown"
  end
  
  -- Use the clientCombat table from player.lua
  if clientCombat and clientCombat[effectId] then
    return clientCombat[effectId].id or "Unknown"
  end
  
  -- Fallback names if clientCombat is not available
  local combatNames = {
    [0] = "Physical",
    [1] = "Fire", 
    [2] = "Earth",
    [3] = "Energy",
    [4] = "Ice",
    [5] = "Holy",
    [6] = "Death",
    [7] = "Healing",
    [8] = "Drown",
    [9] = "Lifedrain",
    [10] = "Manadrain"
  }
  
  return combatNames[effectId] or "Unknown"
end

-- objects
function init()
  analyserMiniWindow = g_ui.loadUI('analyser', modules.game_interface.getRightPanel())
  
  
  mainButton = modules.game_mainpanel.addToggleButton("analyserButton", tr("Analyser"),
            "/images/options/analyzers", function() toggle() end, false, 17)
			
			
  analyserMiniWindow:disableResize()
  analyserMiniWindow:close()
  analyserMiniWindow:setup()

  configPopupWindow["lootButton"] = g_ui.displayUI('styles/lootTarget')
  configPopupWindow["lootButton"]:hide()

  configPopupWindow["impactButton"] = g_ui.displayUI('styles/dpshpsTarget')
  configPopupWindow["impactButton"]:hide()

  configPopupWindow["xpButton"] = g_ui.displayUI('styles/xpTarget')
  configPopupWindow["xpButton"]:hide()

  configPopupWindow["dropButton"] = g_ui.displayUI('styles/dropTarget')
  configPopupWindow["dropButton"]:hide()

  huntingButton = analyserMiniWindow:recursiveGetChildById("huntingButton")
  lootButton = analyserMiniWindow:recursiveGetChildById("lootButton")
  supplyButton = analyserMiniWindow:recursiveGetChildById("supplyButton")
  impactButton = analyserMiniWindow:recursiveGetChildById("impactButton")
  damageButton = analyserMiniWindow:recursiveGetChildById("damageButton")
  xpButton = analyserMiniWindow:recursiveGetChildById("xpButton")
  dropButton = analyserMiniWindow:recursiveGetChildById("dropButton")
  partyButton = analyserMiniWindow:recursiveGetChildById("partyButton")
  bossButton = analyserMiniWindow:recursiveGetChildById("bossButton")
  miscButton = analyserMiniWindow:recursiveGetChildById("miscButton")

  for id, style in pairs(analyserWindows) do
    openedWindows[id] = g_ui.loadUI(style, modules.game_interface.getRightPanel())
    if openedWindows[id] then
      openedWindows[id]:setup()
      openedWindows[id].closeButton.onClick = function() toggleAnalysers(id) end
      openedWindows[id]:close()
      local scrollbar = openedWindows[id]:getChildById('miniwindowScrollBar')
      scrollbar:mergeStyle({ ['$!on'] = { }})
    end
  end

  HuntingAnalyser:create()
  HuntingAnalyser:updateWindow()

  LootAnalyser:create()
  LootAnalyser:updateWindow()

  SupplyAnalyser:create()
  SupplyAnalyser:updateWindow()

  ImpactAnalyser:create()
  ImpactAnalyser:updateWindow()

  InputAnalyser:create()
  InputAnalyser:updateWindow()

  XPAnalyser:create()
  XPAnalyser:updateWindow()

  DropTrackerAnalyser:create()
  DropTrackerAnalyser:updateWindow()

  PartyHuntAnalyser:create()
  PartyHuntAnalyser:updateWindow()

  BossCooldown:create()
  BossCooldown:updateWindow()

  MiscAnalyzer:create()
  MiscAnalyzer:updateWindow()

  connect(g_game, {
    onGameStart = onlineAnalyser,
    onGameEnd = offlineAnalyser,
    onSupplyTracker = onSupplyTracker,
    onLootStats = onLootStats,
    onImpactTracker = onImpactTracker,
    onKillTracker = onKillTracker,
    onPartyAnalyzer = onPartyAnalyzer,
    onBossCooldown = onBossCooldown,
    onUpdateExperience = onUpdateExperience,
    onCharmActivated = onCharmActivated,
    onImbuementActivated = onImbuementActivated,
    onSpecialSkillActivated = onSpecialSkillActivated,
  })

  connect(LocalPlayer, {
    onExperienceChange = onExperienceChange,
    onLevelChange = onLevelChange,
    onPartyMembersChange = onPartyMembersChange
  })

  connect(Creature, {
      onShieldChange = onShieldChange,
  })

end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function Analyser:getPrice(itemPtr, itemId)
    -- Returns BUY price (what player pays to NPC) - good for supplies
    if not self.priceTable then
	    self.priceTable = {}
	end
	
	if self.priceTable[itemId] then
	    return self.priceTable[itemId]
	end
	
    if not itemPtr then
	    itemPtr = Item.create(itemId, 1)
	end
	
    if not itemId then
	    itemId = itemPtr:getId()
	end
		
	local price = itemPtr:getMeanPrice() or 0
	if price > 0 then
	    self.priceTable[itemId] = price
	    return self.priceTable[itemId]
	end
	
	local internalData = g_things.getThingType(itemId, ThingCategoryItem)
	local npcData = internalData:getNpcSaleData()
	
	
	local data = npcData[1]
	if data then
	    if data.buyPrice and data.buyPrice > 0 then
		    self.priceTable[itemId] = data.buyPrice
		    return self.priceTable[itemId]
		end
	    if data.salePrice and data.salePrice > 0 then
		    self.priceTable[itemId] = data.salePrice
		    return self.priceTable[itemId]
		end
	end
	self.priceTable[itemId] = 0
	return self.priceTable[itemId]
end

function Analyser:getSalePrice(itemPtr, itemId)
    -- Returns SALE price (what NPC pays to player) - good for loot valuation
    if not self.salePriceTable then
	    self.salePriceTable = {}
	end
	
	-- Handle coins specially - they have intrinsic value
	if itemId == 3031 then -- gold coin
	    self.salePriceTable[itemId] = 1
	    return 1
	elseif itemId == 3035 then -- platinum coin
	    self.salePriceTable[itemId] = 100
	    return 100
	elseif itemId == 3043 then -- crystal coin
	    self.salePriceTable[itemId] = 10000
	    return 10000
	end
	
	if self.salePriceTable[itemId] then
	    return self.salePriceTable[itemId]
	end
	
    if not itemPtr then
	    itemPtr = Item.create(itemId, 1)
	end
	
    if not itemId then
	    itemId = itemPtr:getId()
	end
		
	local price = itemPtr:getMeanSalePrice() or 0
	if price > 0 then
	    self.salePriceTable[itemId] = price
	    return self.salePriceTable[itemId]
	end
	
	-- Fallback to buy price if no sale price
	price = itemPtr:getMeanPrice() or 0
	if price > 0 then
	    self.salePriceTable[itemId] = price
	    return self.salePriceTable[itemId]
	end
	
	local internalData = g_things.getThingType(itemId, ThingCategoryItem)
	local npcData = internalData:getNpcSaleData()
	
	local data = npcData[1]
	if data then
	    if data.salePrice and data.salePrice > 0 then
		    self.salePriceTable[itemId] = data.salePrice
		    return self.salePriceTable[itemId]
		end
	    if data.buyPrice and data.buyPrice > 0 then
		    self.salePriceTable[itemId] = data.buyPrice
		    return self.salePriceTable[itemId]
		end
	end
	self.salePriceTable[itemId] = 0
	return self.salePriceTable[itemId]
end
	

function terminate()
  -- Salvar configurações antes de destruir
  if g_game.isOnline() then
    HuntingAnalyser:saveConfigJson()
    ImpactAnalyser:saveConfigJson()
    InputAnalyser:saveConfigJson()
    XPAnalyser:saveConfigJson()
    DropTrackerAnalyser:saveConfigJson()
    saveGainAndWastConfigJson()
  end

  if analyserMiniWindow then
    analyserMiniWindow:destroy()
    analyserMiniWindow = nil
  end

  for _, w in pairs(openedWindows) do
    w:destroy()
  end
  openedWindows = {}

  for _, w in pairs(configPopupWindow) do
    w:destroy()
  end
  configPopupWindow = {}

  disconnect(g_game, {
    onGameStart = onlineAnalyser,
    onGameEnd = offlineAnalyser,
    onSupplyTracker = onSupplyTracker,
    onLootStats = onLootStats,
    onImpactTracker = onImpactTracker,
    onKillTracker = onKillTracker,
    onPartyAnalyzer = onPartyAnalyzer,
    onBossCooldown = onBossCooldown,
    onUpdateExperience = onUpdateExperience,
    onCharmActivated = onCharmActivated,
    onImbuementActivated = onImbuementActivated,
    onSpecialSkillActivated = onSpecialSkillActivated,
  })
  disconnect(LocalPlayer, {
    onExperienceChange = onExperienceChange,
    onLevelChange = onLevelChange,
    onPartyMembersChange = onPartyMembersChange
  })

  disconnect(Creature, {
      onShieldChange = onShieldChange,
  })

end

function startNewSession(login)
  -- Reset player expSpeed tracking to reset XP/h calculation
  local player = g_game.getLocalPlayer()
  if player then
    player.lastExps = nil
    player.expSpeed = 0
  end

  -- Hunting
  HuntingAnalyser:reset()
  if login then
    HuntingAnalyser:loadConfigJson()
  end
  HuntingAnalyser:updateWindow(true)

  -- Loot
  LootAnalyser:reset()
  LootAnalyser:updateWindow(true, true)

  -- Supply
  SupplyAnalyser:reset()
  SupplyAnalyser:updateWindow(true, true)

  ImpactAnalyser:reset()
  if login then
    ImpactAnalyser:loadConfigJson()
  end
  ImpactAnalyser:updateWindow(true)

  InputAnalyser:reset()
  if login then
    InputAnalyser:loadConfigJson()
  end
  InputAnalyser:updateWindow(true)

  XPAnalyser:reset()
  if login then
    XPAnalyser:loadConfigJson()
  end
  XPAnalyser:updateWindow(true)

  DropTrackerAnalyser:reset(login)
  if login then
    DropTrackerAnalyser:loadConfigJson()
  end
  DropTrackerAnalyser:updateWindow(true)

  MiscAnalyzer:reset()
  MiscAnalyzer:resetSessionData()
  MiscAnalyzer:updateWindow(true)

  PartyHuntAnalyser:reset()
  PartyHuntAnalyser:updateWindow(true, true)
  PartyHuntAnalyser:startEvent()

  ControllerAnalyser:startEvent()
end

function onlineAnalyser()
  local benchmark = g_clock.millis()
  startNewSession(true)

  -- Carregar configuração de janelas salvas
  if analyserMiniWindow then
    analyserMiniWindow:setupOnStart()
    if mainButton then
      mainButton:setOn(analyserMiniWindow:isVisible())
    end
  end
  
  -- Carregar configuração de cada janela de analyser
  for id, widget in pairs(openedWindows) do
    if widget then
      widget:setupOnStart()
      local buttonWidget = analyserMiniWindow:recursiveGetChildById(id)
      if buttonWidget then
        buttonWidget:setOn(widget:isVisible())
      end
    end
  end

  loadGainAndWastConfigJson()
  --consoleln("Analyser loaded in " .. (g_clock.millis() - benchmark) / 1000 .. " seconds")
end

function offlineAnalyser()
  HuntingAnalyser:saveConfigJson()
  ImpactAnalyser:saveConfigJson()
  InputAnalyser:saveConfigJson()
  XPAnalyser:saveConfigJson()
  DropTrackerAnalyser:saveConfigJson()
  saveGainAndWastConfigJson()
  BossCooldown.cooldown = {}
end

function toggle()
  if analyserMiniWindow:isVisible() then
    analyserMiniWindow:close()
    analyserMiniWindow.isOpen = false
  else
    analyserMiniWindow:open()
	analyserMiniWindow.isOpen = true
    -- if modules.game_interface.addToPanels(analyserMiniWindow) then
      -- analyserMiniWindow:getParent():moveChildToIndex(analyserMiniWindow, #analyserMiniWindow:getParent():getChildren())
      -- analyserMiniWindow.isOpen = true
    -- end
  end
end

function hide()
  analyserMiniWindow:close()
  analyserMiniWindow.isOpen = false
end

function onOpen()
  analyserMiniWindow:setHeight(224)
  analyserMiniWindow.isOpen = true
end

function show()
  analyserMiniWindow:open()
  analyserMiniWindow.isOpen = true
end

function toggleAnalysers(buttonId)
  local buttonWidget = analyserMiniWindow:recursiveGetChildById(buttonId)
  local widget = openedWindows[buttonId]
  if not widget then
    return
  end

  if widget:isVisible() then
    widget:close()
    widget.isOpen = false
    buttonWidget:setOn(false)
    if buttonId == 'bossButton' then
      toggleBossCDFocus(false)
    end
  else
    widget.isOpen = true
    widget:open()

    if buttonId == 'impactButton' then
      ImpactAnalyser:checkAnchos()
    elseif buttonId == 'damageButton' then
      InputAnalyser:checkAnchos()
    elseif buttonId == 'xpButton' then
      XPAnalyser:checkAnchos()
    elseif buttonId == 'bossButton' then
      toggleBossCDFocus(false)
      widget:focus()
    elseif buttonId == 'xpAnalyser' then
      XPAnalyser:checkAnchos()
    end

    --if modules.game_interface.addToPanels(widget) then
      --widget:getParent():moveChildToIndex(widget, #widget:getParent():getChildren())
      --buttonWidget:setOn(true)
    --end
	buttonWidget:setOn(true)
  end
end

function checkExpSpeed()
    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    local currentExp = player:getExperience()
    local currentTime = g_clock.seconds()
    if player.lastExps ~= nil then
        player.expSpeed = (currentExp - player.lastExps[1][1]) / (currentTime - player.lastExps[1][2])
        onLevelChange(player, player:getLevel(), player:getLevelPercent())
    else
        player.lastExps = {}
    end
    table.insert(player.lastExps, {currentExp, currentTime})
    if #player.lastExps > 30 then
        table.remove(player.lastExps, 1)
    end
end

function onExperienceChange(localPlayer, value)
  -- This function is called when the player's total experience changes
  -- We should track the experience progression here
  
  -- Calculate XP gain BEFORE setting up start exp
  local previousExp = HuntingAnalyser.lastExp
  
  -- Setup start experience if this is the first time
  HuntingAnalyser:setupStartExp(value)
  XPAnalyser:setupStartExp(value)
  
  -- Calculate XP gain from experience change using the previous value
  -- Only calculate gain if we have a previous value and current value is higher
  if previousExp and previousExp > 0 and value > previousExp then
    local gain = value - previousExp
    HuntingAnalyser:addRawXPGain(gain)
    HuntingAnalyser:addXpGain(gain)
    XPAnalyser:addRawXPGain(gain)
    XPAnalyser:addXpGain(gain)
  end
  
  -- Update the last experience for next comparison
  XPAnalyser.lastExp = value
  HuntingAnalyser.lastExp = value
  
  checkExpSpeed()
end

function onUpdateExperience(rawExp, exp)
  -- This function receives TOTAL experience, not gain
  -- We don't use it for tracking - onExperienceChange handles that
  checkExpSpeed()
end

function onLootStats(item, name)
  HuntingAnalyser:addLootedItems(item, name)
  LootAnalyser:addLootedItems(item, name)
end

function onSupplyTracker(itemId)
   HuntingAnalyser:addSuppliesItems(itemId)
   SupplyAnalyser:addSuppliesItems(itemId)
end

function onImpactTracker(analyzerType, amount, effect, target)
  if analyzerType == ANALYZER_HEAL then
    HuntingAnalyser:addHealing(amount)
    ImpactAnalyser:addHealing(amount)
  elseif analyzerType == ANALYZER_DAMAGE_DEALT then
    HuntingAnalyser:addDealDamage(amount)
    ImpactAnalyser:addDealDamage(amount, effect)
  elseif analyzerType == ANALYZER_DAMAGE_RECEIVED then
    InputAnalyser:addInputDamage(amount, effect, target)
  end
end

function onKillTracker(monsterName, monsterOutfit, dropItems)
  HuntingAnalyser:addMonsterKilled(monsterName)
  DropTrackerAnalyser:checkMonsterKilled(monsterName, monsterOutfit, dropItems)
end


-- Loot and Wast file
function loadGainAndWastConfigJson()
  local config = {
    gainGaugeTarget = 0,
    gainGaugeVisible = true,
    gainGraphVisible = true,
    wasteGaugeTarget = 0,
    wasteGaugeVisible = true,
    wasteGraphVisible = true,
  }

  if not LoadedPlayer then return end
  if not LoadedPlayer:isLoaded() then return end

  local file = "/characterdata/" .. LoadedPlayer:getId() .. "/gainandwaste.json"
  if g_resources.fileExists(file) then
    local status, result = pcall(function()
      return json.decode(g_resources.readFileContents(file))
    end)

    if not status then
      return g_logger.error("Error while reading characterdata file. Details: " .. result)
    end

    config = result
  end

  LootAnalyser:setLootPerHourGauge(config.gainGaugeVisible)
  LootAnalyser:setLootPerHourGraph(config.gainGraphVisible)
  LootAnalyser:setTarget(config.gainGaugeTarget)

  SupplyAnalyser:setSupplyPerHourGauge(config.wasteGaugeVisible)
  SupplyAnalyser:setSupplyPerHourGraph(config.wasteGraphVisible)
  SupplyAnalyser:setTarget(config.wasteGaugeTarget)
end

function saveGainAndWastConfigJson()
  if  LoadedPlayer and not LoadedPlayer:isLoaded() then return end
  local config = {
    gainGaugeTarget = LootAnalyser:getTarget(),
    gainGaugeVisible = LootAnalyser:gaugeIsVisible(),
    gainGraphVisible = LootAnalyser:graphIsVisible(),
    wasteGaugeTarget = SupplyAnalyser:getTarget(),
    wasteGaugeVisible = SupplyAnalyser:gaugeIsVisible(),
    wasteGraphVisible = SupplyAnalyser:graphIsVisible(),
  }

  local file = "/characterdata/" .. LoadedPlayer:getId() .. "/gainandwaste.json"
  local status, result = pcall(function() return json.encode(config, 2) end)
  if not status then
    return g_logger.error("Error while saving profile Analyzer data. Data won't be saved. Details: " .. result)
  end

  if result:len() > 100 * 1024 * 1024 then
    return g_logger.error("Something went wrong, file is above 100MB, won't be saved")
  end
  g_resources.writeFileContents(file, result)
end

function checkNumber(self, text)
  local number = tonumber(text)
  if (not number or number < 0) and #text > 1 then
    self:setText('0', false)
  end
end

function onLevelChange(localPlayer, value, percent)
  XPAnalyser:setupLevel(value, percent)
end

function managerDropTracker(itemId, checked)
  DropTrackerAnalyser:managerDropItem(itemId, checked)
end

function isInDropTracker(itemId)
  return DropTrackerAnalyser:isInDropTracker(itemId)
end

function onPartyAnalyzer(startTime, leaderID, lootType, membersData, membersName)
  PartyHuntAnalyser:onPartyAnalyzer(startTime, leaderID, lootType, membersData, membersName)
end

function onBossCooldown(cooldown)
  BossCooldown:setupCooldown(cooldown)
end

function onCloseMiniWindow(self)
  self.isOpen = false
end

function onPlayerLoad()

end

function onPlayerUnload()

end

function moveAnalyser(panel, height, minimzed)
  analyserMiniWindow:setParent(panel)
  analyserMiniWindow:open()

  if minimzed then
    analyserMiniWindow:setHeight(height)
    analyserMiniWindow:minimize()
  else
    -- Hardcoded height
    if height < 247 then
      height = 247
    end

    analyserMiniWindow:maximize()
    analyserMiniWindow:setHeight(height)
  end

  return analyserMiniWindow
end

function moveChildAnalyser(type, panel, height, minimzed)
  local window = {
    ['bossCooldowns'] = 'bossButton',
    ['damageInputAnalyser'] = 'damageButton',
    ['lootTracker'] = 'dropButton',
    ['huntingSessionAnalyser'] = 'huntingButton',
    ['impactAnalyser'] = 'impactButton',
    ['lootAnalyser'] = 'lootButton',
    ['partyHuntAnalyser'] = 'partyButton',
    ['wasteAnalyser'] = 'supplyButton',
    ['xpAnalyser'] = 'xpButton',
    ['miscAnalyzer'] = 'miscButton'
  }

  local widget = openedWindows[window[type]]
  if widget then
    widget:setParent(panel)
    widget:open()

    if minimzed then
      widget:setHeight(height)
      widget:minimize()
    else
      widget:maximize()
      widget:setHeight(height)
    end

    if type == 'xpAnalyser' then
      XPAnalyser:checkAnchos()
    end

    -- check
    local buttonWidget = analyserMiniWindow:recursiveGetChildById(window[type])
    if buttonWidget then
      buttonWidget:setOn(true)
    end
  end

  return widget
end

function onCharmActivated(charmId)
  MiscAnalyzer:onCharmActivated(charmId)
end

function onImbuementActivated(imbuementId, amount)
  MiscAnalyzer:onImbuementActivated(imbuementId, amount)
end

function onSpecialSkillActivated(skillId)
  MiscAnalyzer:onSpecialSkillActivated(skillId)
end
