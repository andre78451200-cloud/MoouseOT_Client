-- /*=============================================
-- =            Spells OTUI Windows             =
-- =============================================*/
local function string_empty(str)
    return #str == 0
end

function ActionBarController:onSearchTextChange(event)
    if not ActionBarController._spellList then return end
    for _, child in pairs(ActionBarController._spellList:getChildren()) do
        local name = child:getText():lower()
        if name:find(event.value:lower()) or event.value == '' or #event.value < 3 then
            child:setVisible(true)
        else
            child:setVisible(false)
        end
    end
end

function ActionBarController:onClearSearchText()
    if ActionBarController._searchText then
        ActionBarController._searchText:setText('')
    end
end

function assignSpell(button)
    local dev = true
    local actionbar = button:getParent():getParent()
    if actionbar.locked then
        alert('Action bar is locked')
        return
    end
    -- Fechar janela anterior se existir
    if ActionBarController._spellWindow then
        ActionBarController._spellWindow:destroy()
        ActionBarController._spellWindow = nil
    end
    local radio = UIRadioGroup.create()
    local window = g_ui.displayUI('/game_actionbar/otui/assign_spell')
    window:setText("Assign Spell to Action Button " .. button:getId())
    ActionBarController._spellWindow = window

    local spellList = window:getChildById('spellList')
    local previewWidget = window.previewPanel.preview
    local imageWidget = window.previewPanel.image
    local paramLabel = window:getChildById('paramLabel')
    local paramText = window:getChildById('paramText')
    local devCheck = window:getChildById('devCheck')
    local searchText = window:getChildById('searchText')
    local clearBtn = window:getChildById('clearBtn')

    devCheck:setVisible(dev)
    ActionBarController._spellList = spellList
    ActionBarController._searchText = searchText

    local playerVocation = translateVocation(player:getVocation())
    local playerLevel = player:getLevel()
    local spells = modules.gamelib.SpellInfo['Default']
    local defaultIconsFolder = SpelllistSettings['Default'].iconFile
    local showAllSpells = (playerVocation == 0)

    local function populateSpells(showAll)
        spellList:destroyChildren()
        for spellName, spellData in pairs(spells) do
            if showAll or table.contains(spellData.vocations, playerVocation) then
                local widget = g_ui.createWidget('SpellPreview', spellList)
                local spellId = spellData.clientId
                if not spellId and spellData.icon then
                    if SpellIcons and SpellIcons[spellData.icon] then
                        spellId = SpellIcons[spellData.icon][1]
                    else
                        spellId = tonumber(spellData.icon)
                    end
                end
                local clip = Spells.getImageClip(spellId, 'Default')
                radio:addWidget(widget)
                widget:setId(spellData.id)
                widget:setText(spellName .. "\n" .. spellData.words)
                widget.voc = spellData.vocations
                widget.param = spellData.parameter
                widget.source = defaultIconsFolder
                widget.clip = clip
                widget.image:setImageSource(widget.source)
                widget.image:setImageClip(widget.clip)
                if spellData.level then
                    widget.levelLabel:setVisible(true)
                    widget.levelLabel:setText(string.format("Level: %d", spellData.level))
                    widget.image.gray:setVisible(playerLevel < spellData.level)
                end
                local primaryGroup = Spells.getPrimaryGroup(spellData)
                if primaryGroup ~= -1 then
                    local offSet = (primaryGroup == 2 and 20) or (primaryGroup == 3 and 40) or 0
                    widget.imageGroup:setImageClip(offSet .. " 0 20 20")
                    widget.imageGroup:setVisible(true)
                end
            end
        end
        local widgets = spellList:getChildren()
        table.sort(widgets, function(a, b) return a:getText() < b:getText() end)
        for i, widget in ipairs(widgets) do
            spellList:moveChildToIndex(widget, i)
        end
        return widgets
    end

    local widgets = populateSpells(showAllSpells)

    if button.cache.spellData and not button.cache.isRuneSpell then
        local spellData = button.cache.spellData
        local spellId = spellData.clientId
        if not spellId and spellData.icon then
            if SpellIcons and SpellIcons[spellData.icon] then
                spellId = SpellIcons[spellData.icon][1]
            else
                spellId = tonumber(spellData.icon)
            end
        end
        if not spellId then
            print("Warning Spell ID not found L81 modules/game_actionbar/logics/ActionAssignmentWindows.lua")
            return
        end
        local clip = Spells.getImageClip(spellId, 'Default')
        imageWidget:setImageSource(defaultIconsFolder)
        imageWidget:setImageClip(clip)
        paramLabel:setOn(spellData.parameter)
        paramText:setEnabled(spellData.parameter)
        if spellData.parameter and button.cache.castParam then
            paramText:setText(button.cache.castParam)
            paramText:setCursorPos(#button.cache.castParam)
        end
        for i, k in ipairs(widgets) do
            if k:getId() == tostring(spellData.id) then
                radio:selectWidget(k)
                spellList:ensureChildVisible(k)
                break
            end
        end
    end

    radio.onSelectionChange = function(widget, selected)
        if selected then
            previewWidget:setText(selected:getText())
            imageWidget:setImageSource(selected.source)
            imageWidget:setImageClip(selected.clip)
            paramLabel:setOn(selected.param)
            paramText:setEnabled(selected.param)
            paramText:clearText()
            if selected:getText():lower():find("levitate") then
                paramText:setText("up|down")
            end
        end
    end
    if #widgets > 0 and not button.cache.spellData then
        radio:selectWidget(widgets[1])
    end

    -- Search
    searchText.onTextChange = function(self, text)
        for _, child in pairs(spellList:getChildren()) do
            local name = child:getText():lower()
            if name:find(text:lower()) or text == '' or #text < 3 then
                child:setVisible(true)
            else
                child:setVisible(false)
            end
        end
    end
    clearBtn.onClick = function() searchText:setText('') end

    local function closeWindow()
        if ActionBarController._spellWindow then
            ActionBarController._spellWindow:destroy()
            ActionBarController._spellWindow = nil
        end
    end

    local function okFunc(destroy)
        local selected = radio:getSelectedWidget()
        if not selected then
            closeWindow()
            return
        end

        local barID, buttonID = string.match(button:getId(), "(.*)%.(.*)")
        local param = string.match(selected:getText(), "\n(.*)")
        local paramValue = paramText:getText()
        local check = param .. " " .. paramValue
        if check:find("utevo res ina") then
            param = "utevo res ina"
            paramValue = paramValue:gsub("ina ", "")
        end
        if paramValue:lower():find("up|down") then
            paramValue = ""
        end
        if not string_empty(paramValue) then
            param = param .. ' "' .. paramValue:gsub('"', '') .. '"'
        end
        ApiJson.createOrUpdateText(tonumber(barID), tonumber(buttonID), param, true)
        updateButton(button)

        if destroy then
            closeWindow()
        end
    end

    window:getChildById('buttonOk').onClick = function() okFunc(true) end
    window:getChildById('buttonApply').onClick = function() okFunc(false) end
    window:getChildById('buttonClose').onClick = closeWindow
    window.onEscape = closeWindow

    -- Mostrar todas as spells
    devCheck.onClick = function()
        widgets = populateSpells(true)
    end
end
-- /*=============================================
-- =            SetText html Windows             =
-- =============================================*/
function assignText(button)
    local actionbar = button:getParent():getParent()
    if actionbar.locked then
        alert('Action bar is locked')
        return
    end
    -- Usar OTUI nativo em vez de loadHtml (nosso cliente não tem g_html C++)
    if ActionBarController._textWindow then
        ActionBarController._textWindow:destroy()
        ActionBarController._textWindow = nil
    end
    local window = g_ui.createWidget('MainWindow', rootWidget)
    window:setSize({width = 243, height = 150})
    window:setText("Assign Text to Action Button " .. button:getId())
    window:centerIn('parent')

    local label = g_ui.createWidget('Label', window)
    label:setText("Text:")
    label:addAnchor(AnchorTop, 'parent', AnchorTop)
    label:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    label:setMarginTop(5)

    local textEdit = g_ui.createWidget('TextEdit', window)
    textEdit:setId('textInput')
    textEdit:addAnchor(AnchorTop, 'prev', AnchorBottom)
    textEdit:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    textEdit:addAnchor(AnchorRight, 'parent', AnchorRight)
    textEdit:setMarginTop(5)

    local checkBox = g_ui.createWidget('CheckBox', window)
    checkBox:setId('tickCheck')
    checkBox:setText("Send automatically")
    checkBox:addAnchor(AnchorTop, 'prev', AnchorBottom)
    checkBox:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    checkBox:setMarginTop(8)

    local sep = g_ui.createWidget('HorizontalSeparator', window)
    sep:addAnchor(AnchorTop, 'prev', AnchorBottom)
    sep:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    sep:addAnchor(AnchorRight, 'parent', AnchorRight)
    sep:setMarginTop(8)

    local btnOk = g_ui.createWidget('Button', window)
    btnOk:setText("Ok")
    btnOk:setWidth(45)
    btnOk:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    btnOk:addAnchor(AnchorRight, 'parent', AnchorRight)

    local btnCancel = g_ui.createWidget('Button', window)
    btnCancel:setText("Cancel")
    btnCancel:setWidth(45)
    btnCancel:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    btnCancel:addAnchor(AnchorRight, 'prev', AnchorLeft)
    btnCancel:setMarginRight(5)

    local btnApply = g_ui.createWidget('Button', window)
    btnApply:setText("Apply")
    btnApply:setWidth(45)
    btnApply:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    btnApply:addAnchor(AnchorRight, 'prev', AnchorLeft)
    btnApply:setMarginRight(5)

    ActionBarController._textWindow = window

    -- Preencher dados existentes
    local param = button.cache.param or ''
    textEdit:setText(param)
    textEdit:setCursorPos(#param)
    local hasText = #param > 0
    checkBox:setChecked(hasText and button.cache.sendAutomatic or false)
    btnOk:setEnabled(hasText)
    btnApply:setEnabled(hasText)

    textEdit.onTextChange = function(self, text)
        local hasVal = #text > 0
        btnOk:setEnabled(hasVal)
        btnApply:setEnabled(hasVal)
    end

    local function saveText(closeAfter)
        local autoSay = checkBox:isChecked()
        local text = textEdit:getText()
        local formattedText = Spells.getSpellFormatedName(text)
        local barID, buttonID = string.match(button:getId(), "(.*)%.(.*)") 
        ApiJson.createOrUpdateText(tonumber(barID), tonumber(buttonID), formattedText, autoSay)
        updateButton(button)
        if closeAfter and ActionBarController._textWindow then
            ActionBarController._textWindow:destroy()
            ActionBarController._textWindow = nil
        end
    end
    btnOk.onClick = function() saveText(true) end
    btnApply.onClick = function() saveText(false) end
    local function closeWindow()
        if ActionBarController._textWindow then
            ActionBarController._textWindow:destroy()
            ActionBarController._textWindow = nil
        end
    end
    btnCancel.onClick = closeWindow
    window.onEscape = closeWindow
end
-- /*=============================================
-- =            SetObject html Windows             =
-- =============================================*/
local function canEquipItem(item)
    if item:isContainer() then
        return false
    end
    if not g_game.getFeature(GameEnterGameShowAppearance) then -- old protocol
        return true
    end
    if item:getClothSlot() == 0 and (item:getClassification() > 0 or item:isAmmo()) then
        return true
    end

    if item:getClothSlot() > 0 or (item:getClothSlot() == 0 and item:hasWearout()) then
        return true
    end
    return false
end

function assignItem(button, itemId, itemTier, dragEvent)
    if not isLoaded then
        return true
    end
    local item = button.item:getItem()
    if not button.item then
        updateButton(button)
        return
    end
    local actionbar = button:getParent():getParent()
    if dragEvent and actionbar.locked or actionbar.locked then
        updateButton(button)
        return
    end
    if dragEvent then
        updateButton(button)
        return
    end
    -- Fechar janela anterior se existir
    if ActionBarController._objectWindow then
        ActionBarController._objectWindow:destroy()
        ActionBarController._objectWindow = nil
    end
    local window = g_ui.displayUI('/game_actionbar/otui/assign_object')
    window:setText("Assign Object to Action Button " .. button:getId())
    ActionBarController._objectWindow = window

    local itemWidget = window:getChildById('item')
    local selectButton = window:getChildById('selectObjectBtn')
    local checkbox1 = window:getChildById('UseOnYourself')
    local checkbox2 = window:getChildById('UseOnTarget')
    local checkbox4 = window:getChildById('SelectUseTarget')
    local checkbox5 = window:getChildById('Equip')
    local checkbox6 = window:getChildById('Use')
    local buttonOk = window:getChildById('buttonOk')
    local buttonApply = window:getChildById('buttonApply')
    local buttonClose = window:getChildById('buttonClose')

    local function closeWindow()
        if ActionBarController._objectWindow then
            ActionBarController._objectWindow:destroy()
            ActionBarController._objectWindow = nil
        end
    end

    if selectButton then
        selectButton.onClick = function()
            closeWindow()
            assignItemEvent(button)
        end
    end
    local fromSelect = button.item:getItemId() > 0 and button.item:getItemId() ~= itemId
    itemWidget:setItemId(itemId)
    if not item or item:getId() == 0 then
        item = itemWidget:getItem()
    end
    if item:getClassification() == 0 then
        itemTier = 0
    end
    if itemWidget:getItem() then
        ItemsDatabase.setTier(itemWidget, itemTier, false)
    end
    local checkboxWidgets = {{
        widget = checkbox1,
        useType = "UseOnYourself"
    }, {
        widget = checkbox2,
        useType = "UseOnTarget"
    }, {
        widget = checkbox4,
        useType = "SelectUseTarget"
    }, {
        widget = checkbox5,
        useType = "Equip"
    }, {
        widget = checkbox6,
        useType = "Use"
    }}

    local selectedCheckbox = nil
    for _, cbData in ipairs(checkboxWidgets) do
        if cbData.widget then
            cbData.widget:setEnabled(false)
            cbData.widget:setChecked(false)
        end
    end

    -- UseTypes: UseOnYourself=1, UseOnTarget=2, SelectUseTarget=3
    if item:isMultiUse() then
        for _, cbData in ipairs(checkboxWidgets) do
            local useTypeIndex = UseTypes[cbData.useType]
            if useTypeIndex <= UseTypes["SelectUseTarget"] and cbData.widget then
                cbData.widget:setEnabled(true)

                if not selectedCheckbox and
                    not (item:getClothSlot() > 0 or (item:getClothSlot() == 0 and item:getClassification() > 0)) then
                    if fromSelect or button.cache.actionType == 0 or button.cache.actionType == cbData.useType or
                        button.cache.actionType == UseTypes[cbData.useType] then
                        selectedCheckbox = cbData.widget
                    end
                end
            end
        end
    end

    -- UseTypes: Equip=4
    if canEquipItem(item) then
        checkbox5:setEnabled(true)

        if not selectedCheckbox then
            if fromSelect or button.cache.actionType == 0 or button.cache.actionType == "Equip" or
                button.cache.actionType == UseTypes["Equip"] then
                selectedCheckbox = checkbox5
            end
        end
    end

    -- UseTypes: Use=5 (items usables no-multiuso)
    if (item:isUsable() and not item:isMultiUse()) or item:isContainer() then
        checkbox6:setEnabled(true)

        if not selectedCheckbox then
            if fromSelect or button.cache.actionType == 0 or button.cache.actionType == "Use" or button.cache.actionType ==
                UseTypes["Use"] then
                selectedCheckbox = checkbox6
            end
        end
    end
    buttonOk:setEnabled(item and item:getId() > 100)
    buttonApply:setEnabled(item and item:getId() > 100)
    if not selectedCheckbox then
        for _, cbData in ipairs(checkboxWidgets) do
            if cbData.widget and cbData.widget:isEnabled() then
                selectedCheckbox = cbData.widget
                break
            end
        end
    end
    if selectedCheckbox then
        selectedCheckbox:setChecked(true)
    end
    for _, cbData in ipairs(checkboxWidgets) do
        if cbData.widget then
            cbData.widget.onCheckChange = function(widget, checked)
                if checked then
                    for _, otherCbData in ipairs(checkboxWidgets) do
                        if otherCbData.widget and otherCbData.widget ~= widget and otherCbData.widget:isChecked() then
                            otherCbData.widget:setChecked(false)
                        end
                    end
                end
            end
        end
    end
    local function okFunc(destroy)
        local selected = nil
        for _, cbData in ipairs(checkboxWidgets) do
            if cbData.widget and cbData.widget:isChecked() then
                selected = cbData.useType
                break
            end
        end
        if not selected then
            return
        end
        local barID, buttonID = string.match(button:getId(), "^(%d+)%.(%d+)$")
        if not barID or not buttonID then
            return
        end
        local cache = getButtonCache(button)
        local cachedItem = cachedItemWidget[cache.itemId]
        if cachedItem then
            for index, widget in pairs(cachedItem) do
                if button == widget then
                    table.remove(cachedItem, index)
                    break
                end
            end
        end
        ApiJson.createOrUpdateAction(tonumber(barID), tonumber(buttonID), selected, itemId, itemTier)
        updateButton(button)

        if destroy then
            closeWindow()
        end
    end
    buttonOk.onClick = function()
        okFunc(true)
    end
    buttonApply.onClick = function()
        okFunc(false)
    end
    buttonClose.onClick = function()
        updateButton(button)
        closeWindow()
    end
    window.onEnter = function()
        okFunc(true)
    end
    window.onEscape = function()
        updateButton(button)
        closeWindow()
    end
    if actionbar.locked then
        closeWindow()
    end
end
-- /*=============================================
-- =            Passive html Windows          =
-- =============================================*/

function assignPassive(button)
    local actionbar = button:getParent():getParent()
    if actionbar.locked then
        alert('Action bar is locked')
        return
    end
    -- Fechar janela anterior se existir
    if ActionBarController._passiveWindow then
        ActionBarController._passiveWindow:destroy()
        ActionBarController._passiveWindow = nil
    end
    local radio = UIRadioGroup.create()
    local window = g_ui.displayUI('/game_actionbar/otui/assign_passive')
    window:setText("Assign Passive to Action Button " .. button:getId())
    ActionBarController._passiveWindow = window

    local passiveList = window:getChildById('passiveList')
    local previewWidget = window.previewPanel.preview
    local image = window.previewPanel.image

    for id, passiveData in pairs(PassiveAbilities) do
        local widget = g_ui.createWidget('PassivePreview', passiveList)
        radio:addWidget(widget)
        widget:setId(id)
        widget:setText(passiveData.name)
        widget.image:setImageSource(passiveData.icon)
        widget.source = passiveData.icon
    end
    radio.onSelectionChange = function(widget, selected)
        if selected then
            previewWidget:setText(selected:getText())
            image:setImageSource(selected.source)
            passiveList:ensureChildVisible(widget)
        end
    end
    local passiveChildren = passiveList:getChildren()
    if #passiveChildren > 0 then
        radio:selectWidget(passiveChildren[1])
    end

    local function closeWindow()
        if ActionBarController._passiveWindow then
            ActionBarController._passiveWindow:destroy()
            ActionBarController._passiveWindow = nil
        end
    end

    local function okFunc(destroy)
        local selected = radio:getSelectedWidget()
        if not selected then
            return
        end
        local barID, buttonID = string.match(button:getId(), "(.*)%.(.*)")
        ApiJson.createOrUpdatePassive(tonumber(barID), tonumber(buttonID), tonumber(selected:getId()))
        updateButton(button)
        if destroy then
            closeWindow()
        end
    end

    window:getChildById('buttonOk').onClick = function() okFunc(true) end
    window:getChildById('buttonApply').onClick = function() okFunc(false) end
    window:getChildById('buttonClose').onClick = closeWindow
    window.onEnter = function() okFunc(true) end
    window.onEscape = closeWindow
end

-- /*=============================================
-- =            item Event external          =
-- =============================================*/
function onDropActionButton(self, mousePosition, mouseButton)
    if not g_ui.isMouseGrabbed() then
        return
    end
    g_mouse.popCursor('target')
    self:ungrabMouse()
end

function assignItemEvent(button)
    mouseGrabberWidget:grabMouse()
    g_mouse.pushCursor('target')
    mouseGrabberWidget.onMouseRelease = function(self, mousePosition, mouseButton)
        onAssignItem(self, mousePosition, mouseButton, button)
    end
end

function onAssignItem(self, mousePosition, mouseButton, button)
    mouseGrabberWidget:ungrabMouse()
    g_mouse.popCursor('target')
    mouseGrabberWidget.onMouseRelease = onDropActionButton

    local clickedWidget = gameRootPanel:recursiveGetChildByPos(mousePosition, false)
    if not clickedWidget then
        return true
    end

    local itemId = 0
    local itemTier = 0
    if clickedWidget:getClassName() == 'UIItem' and not clickedWidget:isVirtual() and clickedWidget:getItem() then
        itemId = clickedWidget:getItem():getId()
        itemTier = clickedWidget:getItem():getTier()
    elseif clickedWidget:getClassName() == 'UIGameMap' then
        local tile = clickedWidget:getTile(mousePosition)
        if tile then
            itemId = tile:getTopUseThing():getId()
        end
    end

    local itemType = g_things.getThingType(itemId, ThingCategoryItem)
    if not itemType or not itemType:isPickupable() then
        modules.game_textmessage.displayFailureMessage(tr('Invalid object'))
        return true
    end
    assignItem(button, itemId, itemTier)
end

-- /*=============================================
-- =            Windows hotkeys html             =
-- =============================================*/
-- in modules\game_actionbar\html\hotkeys.html
