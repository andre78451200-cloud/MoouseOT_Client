if not XPAnalyser then
	XPAnalyser = {
		launchTime = 0,
		session = 0,

		startExp = 0,
		lastExp = 0,
		rawXPGain = 0,
		xpGain = 0,
		xpHour = 0,
		rawXpHour = 0,
		level = 0,
		target = 0,

		-- private
		window = nil,
	}
	XPAnalyser.__index = XPAnalyser
end
local targetMaxMargin = 142

function expForLevel(level)
  return math.floor((50*level*level*level)/3 - 100*level*level + (850*level)/3 - 200)
end

function expToAdvance(currentLevel, currentExp)
  return expForLevel(currentLevel+1) - currentExp
end

function XPAnalyser.create()
	XPAnalyser.window = openedWindows['xpButton']

	XPAnalyser.launchTime = g_clock.millis()
	XPAnalyser.session = 0

	XPAnalyser.startExp = 0
	XPAnalyser.lastExp = 0
	XPAnalyser.rawXPGain = 0
	XPAnalyser.xpGain = 0
	XPAnalyser.xpHour = 0
	XPAnalyser.rawXpHour = 0
	XPAnalyser.level = 0
	XPAnalyser.target = 0
	
	if not XPAnalyser.window then
		return
	end

	-- Hide buttons we don't want
	local toggleFilterButton = XPAnalyser.window:recursiveGetChildById('toggleFilterButton')
	if toggleFilterButton then
		toggleFilterButton:setVisible(false)
	end
	
	local newWindowButton = XPAnalyser.window:recursiveGetChildById('newWindowButton')
	if newWindowButton then
		newWindowButton:setVisible(false)
	end

	-- Position contextMenuButton where toggleFilterButton was (to the left of minimize button)
	local contextMenuButton = XPAnalyser.window:recursiveGetChildById('contextMenuButton')
	local minimizeButton = XPAnalyser.window:recursiveGetChildById('minimizeButton')
	
	if contextMenuButton and minimizeButton then
		contextMenuButton:setVisible(true)
		contextMenuButton:breakAnchors()
		contextMenuButton:addAnchor(AnchorTop, minimizeButton:getId(), AnchorTop)
		contextMenuButton:addAnchor(AnchorRight, minimizeButton:getId(), AnchorLeft)
		contextMenuButton:setMarginRight(7)
		contextMenuButton:setMarginTop(0)
		
		-- Set up contextMenuButton click handler to show our menu
		contextMenuButton.onClick = function(widget, mousePos)
			local pos = mousePos or g_window.getMousePosition()
			return onXPExtra(pos)
		end
	end

	-- Position lockButton to the left of contextMenuButton
	local lockButton = XPAnalyser.window:recursiveGetChildById('lockButton')
	
	if lockButton and contextMenuButton then
		lockButton:setVisible(true)
		lockButton:breakAnchors()
		lockButton:addAnchor(AnchorTop, contextMenuButton:getId(), AnchorTop)
		lockButton:addAnchor(AnchorRight, contextMenuButton:getId(), AnchorLeft)
		lockButton:setMarginRight(2)
		lockButton:setMarginTop(0)
	end
end

function XPAnalyser:reset(allTimeDps, allTimeHps)
	XPAnalyser.launchTime = g_clock.millis()
	XPAnalyser.session = 0

	XPAnalyser.startExp = 0
	XPAnalyser.lastExp = 0
	XPAnalyser.rawXPGain = 0
	XPAnalyser.xpGain = 0
	XPAnalyser.xpHour = 0
	XPAnalyser.rawXpHour = 0
	XPAnalyser.level = 0
	XPAnalyser.target = 0

	XPAnalyser.window.contentsPanel.graphPanel:clear()
	--XPAnalyser.window.contentsPanel.graphPanel:addValue(1)

	XPAnalyser:updateWindow()
	g_game.resetExperienceData()
end

function XPAnalyser:updateWindow(ignoreVisible)
	if not XPAnalyser.window:isVisible() and not ignoreVisible then
		return
	end
	local contentsPanel = XPAnalyser.window.contentsPanel

	local experience = XPAnalyser.xpGain
	contentsPanel.xpGain:setText(formatMoney(experience, ","))

	local experience = XPAnalyser.rawXPGain
	contentsPanel.rawXpGain:setText(formatMoney(experience, ","))

	if XPAnalyser.target == 0 and XPAnalyser.xpHour == 0 then
		XPAnalyser.window.contentsPanel.xpBG.xpArrow:setMarginLeft(targetMaxMargin / 2)
	else
		local target = math.max(1, (XPAnalyser.target or 1))
		local current = XPAnalyser.xpHour
		local percent = (current * 71) / target
		XPAnalyser.window.contentsPanel.xpBG.xpArrow:setMarginLeft(math.min(targetMaxMargin, math.ceil(percent)))
	end

	XPAnalyser:updateTooltip()
end

function XPAnalyser:setupStartExp(value)
	if XPAnalyser.startExp == 0 then
		XPAnalyser.launchTime = g_clock.millis()
		XPAnalyser.startExp = value
		XPAnalyser.lastExp = value
	end
end

function XPAnalyser:setupLevel(level, percent)
	XPAnalyser.level = level
	XPAnalyser.window.contentsPanel.percent:setPercent(math.floor(percent))
	XPAnalyser.window.contentsPanel.nextLevel:setText("-")
end

function XPAnalyser:updateNextLevel(hours, minutes)
	local text = "-"
	if XPAnalyser.xpHour == 0 then
		XPAnalyser.window.contentsPanel.nextLevel:setText(text)
		return
	end

	if hours > 0 then
		text = tr('%dh %dmin', hours, minutes)
	elseif minutes > 0 then
		text = tr('%d minutes', minutes)
	else
		text = tr('1 minute')
	end
	XPAnalyser.window.contentsPanel.nextLevel:setText(text)
end

function XPAnalyser:checkExpHour()
    local player = g_game.getLocalPlayer()
    if not player then return end

    local contentsPanel = XPAnalyser.window.contentsPanel

    -----------------------------------------------------------------
    -- Upewniamy się, że expSpeed istnieje
    if not player.expSpeed then
        player.expSpeed = 0
    end

    -- EXP/H - expSpeed is XP per SECOND, multiply by 3600 to get XP per HOUR
    XPAnalyser.xpHour = math.floor((player.expSpeed or 0) * 3600)

    if XPAnalyser.xpHour == 0 then
        contentsPanel.xpHour:setText("0")
    else
        contentsPanel.xpHour:setText(formatMoney(XPAnalyser.xpHour, ","))
    end

    -----------------------------------------------------------------
    -- NEXT LEVEL
    local currentLevel   = player:getLevel()
    local currentExp     = player:getExperience()
    local nextLevelExp   = modules.game_skills.expForLevel(currentLevel + 1)
    local expLeft        = math.max(0, nextLevelExp - currentExp)
    local hoursLeft, minutesLeft = 0, 0
    local timeToLevelStr = "0h 0m"

    if XPAnalyser.xpHour > 0 and expLeft > 0 then
        local h = expLeft / XPAnalyser.xpHour

        if h < 24 then
            hoursLeft   = math.floor(h)
            minutesLeft = math.floor((h - hoursLeft) * 60)
            timeToLevelStr = string.format("%dh %dm", hoursLeft, minutesLeft)
        elseif h < 24 * 365 then
            local days = math.floor(h / 24)
            local hours = math.floor(h % 24)
            local minutes = math.floor((h - math.floor(h)) * 60)
            timeToLevelStr = string.format("%dd %dh %dm", days, hours, minutes)
        else
            local years = math.floor(h / (24 * 365))
            local days  = math.floor((h % (24 * 365)) / 24)
            local hours = math.floor(h % 24)
            local minutes = math.floor((h - math.floor(h)) * 60)
            timeToLevelStr = string.format("%dy %dd %dh %dm", years, days, hours, minutes)
        end
    end

    -- Aktualizacja labelki w UI
    if contentsPanel.nextLevel then
        contentsPanel.nextLevel:setText(timeToLevelStr)
    end

    -----------------------------------------------------------------
    -- RAW EXP/H
    local displayExp = XPAnalyser.rawXPGain or 0
    if displayExp > 0 then
        local elapsed = g_clock.seconds() - (XPAnalyser.startTime or g_clock.seconds())
        if elapsed > 0 then
            XPAnalyser.rawXpHour = (displayExp / elapsed) * 3600
        else
            XPAnalyser.rawXpHour = 0
        end
        contentsPanel.rawXpHour:setText(formatMoney(math.floor(XPAnalyser.rawXpHour), ","))
    else
        XPAnalyser.rawXpHour = 0
        contentsPanel.rawXpHour:setText("0")
    end

    -----------------------------------------------------------------
    -- PERCENT BAR
    if player then
        contentsPanel.percent:setPercent(math.floor(player:getLevelPercent()))
    else
        contentsPanel.percent:setPercent(0)
    end

    XPAnalyser:updateTooltip()

    -----------------------------------------------------------------
    -- DEBUG
    -- print("[XP DEBUG] Lvl:", currentLevel,
          -- "ExpNow:", currentExp,
          -- "NextLevelExp:", nextLevelExp,
          -- "ExpLeft:", expLeft,
          -- "Exp/h:", XPAnalyser.xpHour,
          -- "TimeToLevel:", timeToLevelStr)
end

-- updaters
function XPAnalyser:addRawXPGain(value) XPAnalyser.rawXPGain = XPAnalyser.rawXPGain + value; XPAnalyser:updateWindow() end
function XPAnalyser:addXpGain(value) XPAnalyser.xpGain = XPAnalyser.xpGain + value; XPAnalyser:updateWindow() end

function XPAnalyser:updateTooltip()
	local player = g_game.getLocalPlayer()
	if not player then
		return
	end
	local text = "Raw XP Gain: " .. formatMoney(XPAnalyser.rawXPGain, ",")
	text = text .. "\nXP Gain: " .. formatMoney(XPAnalyser.xpGain, ",")
	text = text .. "\nCurrent Raw XP Per Hour: " .. formatMoney(XPAnalyser.rawXpHour, ",")
	text = text .. "\nCurrent XP Per Hour: " .. formatMoney(XPAnalyser.xpHour, ",")
	text = text .. "\nTarget XP Per Hour: " .. formatMoney(XPAnalyser.target, ",")
	text = text .. "\n" .. formatMoney(expToAdvance(player:getLevel(), player:getExperience()), ",") .. " XP until next level."
	text = text .. "\nYou have " .. 100 - player:getLevelPercent() .. " percent to go."

	XPAnalyser.window:setTooltip(text)
end

function onXPExtra(mousePosition)
  if cancelNextRelease then
    cancelNextRelease = false
    return false
  end

  local rawXpVisible = XPAnalyser.window.contentsPanel.rawXpLabel:isVisible()
  local gaugeVisible = XPAnalyser.window.contentsPanel.xpBG:isVisible()
  local graphVisible = XPAnalyser.window.contentsPanel.xpGraphBG:isVisible()

	local menu = g_ui.createWidget('PopupMenu')
	menu:setGameMenu(true)
	menu:addOption(tr('Reset Data'), function() XPAnalyser:reset(); return end)
	menu:addSeparator()
	menu:addCheckBox(tr('Show Raw XP'), rawXpVisible, function() XPAnalyser:setRawXPVisible(not rawXpVisible) end)
	menu:addSeparator()
	menu:addOption(tr('Set XP Per Hour Target'), function() XPAnalyser:openTargetConfig() return end)
	menu:addCheckBox(tr('XP Per Hour Gauge'), gaugeVisible, function() XPAnalyser:setGaugeVisible(not gaugeVisible) end)
	menu:addCheckBox(tr('XP Per Hour Graph'), graphVisible, function() XPAnalyser:setGraphVisible(not graphVisible) end)
	menu:display(mousePosition)
  return true
end

function XPAnalyser:checkAnchos()
	if XPAnalyser.window.contentsPanel.rawXpLabel:isVisible() then
		XPAnalyser.window.contentsPanel.xpLabel:setMarginTop(2)
		XPAnalyser.window.contentsPanel.xpLabel:addAnchor(AnchorTop, 'rawXpLabel', AnchorBottom)
		XPAnalyser.window.contentsPanel.xpGain:addAnchor(AnchorTop, 'rawXpGain', AnchorBottom)
	else
		XPAnalyser.window.contentsPanel.xpLabel:setMarginTop(0)
		XPAnalyser.window.contentsPanel.xpLabel:addAnchor(AnchorTop, 'topParent', AnchorBottom)
		XPAnalyser.window.contentsPanel.xpGain:addAnchor(AnchorTop, 'topParent', AnchorBottom)
	end

	if XPAnalyser.window.contentsPanel.rawXpHourLabel:isVisible() then
		XPAnalyser.window.contentsPanel.xpHourLabel:setMarginTop(2)
		XPAnalyser.window.contentsPanel.xpHour:setMarginTop(2)
		XPAnalyser.window.contentsPanel.xpHourLabel:addAnchor(AnchorTop, 'rawXpHourLabel', AnchorBottom)
		XPAnalyser.window.contentsPanel.xpHour:addAnchor(AnchorTop, 'xpHourLabel', AnchorTop)
	else
		XPAnalyser.window.contentsPanel.xpHourLabel:setMarginTop(2)
		XPAnalyser.window.contentsPanel.xpHour:setMarginTop(2)
		XPAnalyser.window.contentsPanel.xpHourLabel:addAnchor(AnchorTop, 'xpLabel', AnchorBottom)
		XPAnalyser.window.contentsPanel.xpHour:addAnchor(AnchorTop, 'xpHourLabel', AnchorTop)
	end

	if XPAnalyser.window.contentsPanel.xpBG:isVisible() then
		XPAnalyser.window.contentsPanel.xpGraphBG:addAnchor(AnchorTop, 'separatorGauge', AnchorBottom)
	else
		XPAnalyser.window.contentsPanel.xpGraphBG:addAnchor(AnchorTop, 'separatorPercent', AnchorBottom)
	end
end

function XPAnalyser:setRawXPVisible(value)
	XPAnalyser.window.contentsPanel.rawXpLabel:setVisible(value)
	XPAnalyser.window.contentsPanel.rawXpGain:setVisible(value)
	XPAnalyser.window.contentsPanel.rawXpHourLabel:setVisible(value)
	XPAnalyser.window.contentsPanel.rawXpHour:setVisible(value)

	XPAnalyser.rawXpVisible = value
	XPAnalyser:checkAnchos()
end

function XPAnalyser:setGaugeVisible(value)
	XPAnalyser.window.contentsPanel.xpBG:setVisible(value)
	XPAnalyser.window.contentsPanel.separatorGauge:setVisible(value)

	XPAnalyser.gaugeVisible = value
	XPAnalyser:checkAnchos()
end

function XPAnalyser:setGraphVisible(value)
	XPAnalyser.window.contentsPanel.xpGraphBG:setVisible(value)
	XPAnalyser.window.contentsPanel.graphPanel:setVisible(value)
	XPAnalyser.window.contentsPanel.graphHorizontal:setVisible(value)

	XPAnalyser.graphVisible = value
	XPAnalyser:checkAnchos()
end

function XPAnalyser:openTargetConfig()
	local window = configPopupWindow["xpButton"]
	window:show()
	window:setText('Set XP Per Hour Target')
	window.contentPanel.text:setImageSource('/images/game/analyzer/labels/xp')

	window.onEnter = function()
		local value = window.contentPanel.xpTarget:getText()
		XPAnalyser.target = tonumber(value)
		window:hide()
	end
	window.contentPanel.xpTarget:setText(tonumber(XPAnalyser.target) or '0')

	window.contentPanel.ok.onClick = function()
		local value = window.contentPanel.xpTarget:getText()
		XPAnalyser.target = tonumber(value)
		window:hide()
	end
	window.contentPanel.cancel.onClick = function()
		window:hide()
	end
end

function XPAnalyser:gaugeIsVisible()
	return XPAnalyser.gaugeVisible
end
function XPAnalyser:graphIsVisible()
	return XPAnalyser.graphVisible
end
function XPAnalyser:rawXPIsVisible()
	return XPAnalyser.rawXpVisible
end
function XPAnalyser:getTarget()
	return XPAnalyser.target
end

function XPAnalyser:loadConfigJson()
	local config = {
		desiredExperienceGaugeVisible = true,
		desiredXPGraphVisible = true,
		experienceGaugeTargetValue = 0,
		showBaseXp = false,
	}

	local player = g_game.getLocalPlayer()
	local file = "/characterdata/" .. player:getId() .. "/xpanalyser.json"
	if g_resources.fileExists(file) then
		local status, result = pcall(function()
			return json.decode(g_resources.readFileContents(file))
		end)

		if not status then
			return g_logger.error("Error while reading characterdata file. Details: " .. result)
		end

		config = result
	end

	XPAnalyser:setRawXPVisible(config.showBaseXp)
	XPAnalyser:setGaugeVisible(config.desiredExperienceGaugeVisible)
	XPAnalyser:setGraphVisible(config.desiredXPGraphVisible)
	XPAnalyser.target = config.experienceGaugeTargetValue
	XPAnalyser:checkAnchos()
end

function XPAnalyser:saveConfigJson()
	local config = {
		desiredExperienceGaugeVisible = XPAnalyser:gaugeIsVisible(),
		desiredXPGraphVisible = XPAnalyser:graphIsVisible(),
		experienceGaugeTargetValue = XPAnalyser:getTarget(),
		showBaseXp = XPAnalyser:rawXPIsVisible(),
	}

	if  LoadedPlayer and not LoadedPlayer:isLoaded() then return end
	local file = "/characterdata/" .. LoadedPlayer:getId() .. "/xpanalyser.json"
	local status, result = pcall(function() return json.encode(config, 2) end)
	if not status then
		return g_logger.error("Error while saving profile XP Analyzer data. Data won't be saved. Details: " .. result)
	end

	if result:len() > 100 * 1024 * 1024 then
		return g_logger.error("Something went wrong, file is above 100MB, won't be saved")
	end
	g_resources.writeFileContents(file, result)
end
