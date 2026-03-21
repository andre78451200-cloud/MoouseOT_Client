if not ImbuementScroll then
  ImbuementScroll = {
    window = nil,
    itemId = 51442,
    confirmWindow = nil,
    availableImbuements = {},
    needItems = {}
  }
end

ImbuementScroll.__index = ImbuementScroll

-- Get path to individual icon file
-- Server sends iconId starting from 1, icons are named 0.png to 81.png
local function getIconPath(imageId)
    imageId = tonumber(imageId) or 1
    return string.format("/images/game/imbuing/icons/%d", imageId)
end

local self = ImbuementScroll

-- Convert group string to type number
local function getTypeFromGroup(group)
    if group == "Basic" then return 0
    elseif group == "Intricate" then return 1
    elseif group == "Powerful" then return 2
    else return tonumber(group) or 0
    end
end

function ImbuementScroll.setup(availableImbuements, needItems)
    self.availableImbuements = availableImbuements or {}
    self.needItems = needItems or {}

    -- Normalize needItems: convert list of Item objects to a map id->count
    if type(self.needItems) == 'table' and #self.needItems > 0 then
        local first = self.needItems[1]
        if type(first) == 'userdata' and first.getId and first.getCount then
            local map = {}
            for _, it in ipairs(self.needItems) do
                map[it:getId()] = it:getCount()
            end
            self.needItems = map
        end
    end

    -- Convert group to type for each imbuement
    for i, imb in ipairs(self.availableImbuements) do
        if imb.type == nil and imb.group then
            imb.type = getTypeFromGroup(imb.group)
        end
    end

    self.window = Imbuement.scrollImbue

    local itemWidget = self.window:recursiveGetChildById("itemScroll")
    if itemWidget then
        itemWidget:setItemId(self.itemId)
        itemWidget:setImageSmooth(true)
        itemWidget:setItemCount(1)
    end

    -- Setup the apply button onClick here once
    local imbuescrollApply = self.window:recursiveGetChildById("imbuescrollApply")
    if imbuescrollApply then
        imbuescrollApply.onClick = function()
            if self.selectedImbuement then
                ImbuementScroll.applySelectedImbuement()
            end
        end
    end

    self.onSelectSlotImbue()
end

function ImbuementScroll:shutdown()
    self.window = nil
    self.confirmWindow = nil
    self.availableImbuements = {}
    self.needItems = {}
end

function ImbuementScroll.onSelectSlotImbue()
    self.selectBaseType('powerfullButton')
    self.window:recursiveGetChildById('imbuementsDetails'):setVisible(false)
end

function ImbuementScroll.selectBaseType(selectedButtonId)
    local qualityAndImbuementContent = self.window:recursiveGetChildById("qualityAndImbuementContent")
    if not qualityAndImbuementContent then
        return
    end

    local intricateButton = qualityAndImbuementContent.intricateButton
    local powerfullButton = qualityAndImbuementContent.powerfullButton

    local baseImbuement = 1
    for _, button in pairs({intricateButton, powerfullButton}) do
        button:setOn(button:getId() == selectedButtonId)
        if button:getId() == selectedButtonId then
            baseImbuement = button.baseImbuement or 1
        end
    end

    local imbuementsList = self.window:recursiveGetChildById("imbuementsList")
    imbuementsList:destroyChildren()

    local imbuementsDetails = self.window:recursiveGetChildById("imbuementsDetails")
    imbuementsDetails:setVisible(false)

    local selected = false
    
    for id, imbuement in ipairs(self.availableImbuements) do
        local imbuementType = imbuement.type
        if imbuementType == nil and imbuement.group then
            if imbuement.group == 'Basic' then imbuementType = 0
            elseif imbuement.group == 'Intricate' then imbuementType = 1
            elseif imbuement.group == 'Powerful' then imbuementType = 2
            end
        end
        if imbuementType == baseImbuement then
            local widget = g_ui.createWidget("SlotImbuing", imbuementsList)
            widget:setId(tostring(id))
            widget.resource:setImageSource(getIconPath(imbuement.imageId))

            if not selected then
                ImbuementScroll.selectImbuementWidget(widget, imbuement)
                selected = true
            end

            widget.onClick = function()
                ImbuementScroll.selectImbuementWidget(widget, imbuement)
            end

        end
    end
end

function ImbuementScroll.selectImbuementWidget(widget, imbuement)
    -- Save selected imbuement
    self.selectedImbuement = imbuement
    
    if self.lastselectedwidget then
        self.lastselectedwidget:setBorderWidth(1)
        self.lastselectedwidget:setBorderColorTop("#797979")
        self.lastselectedwidget:setBorderColorLeft("#797979")
        self.lastselectedwidget:setBorderColorRight("#2e2e2e")
        self.lastselectedwidget:setBorderColorBottom("#2e2e2e")
    end
    self.lastselectedwidget = widget
    widget:setBorderWidth(1)
    widget:setBorderColor("white")

    self.onSelectImbuement(widget)

    local imbuementsDetails = self.window:recursiveGetChildById("imbuementsDetails")
    if imbuementsDetails then
        imbuementsDetails:setVisible(true)
        imbuementsDetails:setText(imbuement.description or "")
    end

    local requiredItems = self.window:recursiveGetChildById("requiredItems")
    local hasRequiredItems = true
    if requiredItems then
        for i = 1, 4 do
            local itemWidget = requiredItems:getChildById("item"..i)
            if itemWidget then
                local source = imbuement.sources[i]
                if source then
                    local itemId = source.item:getId()
                    local playerCount = self.needItems[itemId] or 0
                    local requiredCount = source.item:getCount()
                    
                    itemWidget.item:setItemId(itemId)
                    itemWidget:setVisible(true)
                    itemWidget.count:setText(playerCount .."/" .. requiredCount)
                    if playerCount >= requiredCount then
                        itemWidget.count:setColor("white")
                    else
                        hasRequiredItems = false
                        itemWidget.count:setColor("#ff4444")
                    end

                    itemWidget.onHoverChange = function(widget, hovered)
                        local itensDetails = self.window:recursiveGetChildById("itensDetails")
                        if hovered then
                            if playerCount >= requiredCount then
                                itensDetails:setText(string.format("The imbuement you have selected requires %s.", source.description))
                            else
                                itensDetails:setText(string.format("The imbuement requires %s. Unfortunately you do not own the needed amount.", source.description))
                            end
                        else
                            if itensDetails then
                                itensDetails:setText("")
                            end
                        end
                    end
                else
                    itemWidget:setVisible(false)
                end
            end
        end
    end

    local costPanel = self.window:recursiveGetChildById("costPanel")
    if costPanel then
        local cost = imbuement.cost or 0
        costPanel.cost:setText(comma_value(cost))
        local balance = (Imbuement.bankGold or 0) + (Imbuement.inventoryGold or 0)

        if balance < cost then
            hasRequiredItems = false
        end

        costPanel.cost:setColor(balance < cost and "#ff4444" or "white")
    end

    local imbuescrollApply = self.window:recursiveGetChildById("imbuescrollApply")
    if imbuescrollApply then
        imbuescrollApply:setEnabled(true)
        if not hasRequiredItems then
           imbuescrollApply:setImageSource("/images/game/imbuing/imbue_empty")
           imbuescrollApply:setImageClip("0 0 128 66")
        else
            imbuescrollApply:setImageSource("/images/game/imbuing/imbue_green")
        end

        imbuescrollApply.onHoverChange = function(widget, hovered, itemName, hasItem)
            local itensDetails = self.window:recursiveGetChildById("itensDetails")
            if hovered then
                itensDetails:setText(tr("Apply the selected imbuement. This will consume the required astral sources and gold."))
            else
                if itensDetails then
                    itensDetails:setText("")
                end
            end
        end

        imbuescrollApply.onClick = function()
            if self.confirmWindow then
                self.confirmWindow:destroy()
                self.confirmWindow = nil
            end

            Imbuement.hide()

            local function confirm()
                g_game.applyImbuement(0, imbuement.id)
                self.confirmWindow:destroy()
                self.confirmWindow = nil

                Imbuement.show()
            end

            local function cancelFunc()
                if self.confirmWindow then
                    self.confirmWindow:destroy()
                    self.confirmWindow = nil
                end

                Imbuement.show()
            end

            self.confirmWindow = displayGeneralBox(tr('Confirm Imbuing'), tr("You are about to imbue your item with \"%s\". This will consume the required astral sources and %s\ngold coins. Do you wish to proceed?", string.capitalize(imbuement.name), comma_value(imbuement.cost)),
            { { text=tr('Yes'), callback=confirm },
                { text=tr('No'), callback=cancelFunc },
            }, confirm, cancelFunc)

            -- g_client.setInputLockWidget(self.confirmWindow) -- deprecated
        end
    end
end

function ImbuementScroll.onSelectImbuement(widget)
    local imbuementId = tonumber(widget:getId())
    local imbuement = self.availableImbuements[imbuementId]
    if not imbuement then
        return
    end


    local imbuementReqPanel = self.window:recursiveGetChildById("imbuementReqPanel")
    if imbuementReqPanel then
        imbuementReqPanel.title:setText(string.format('Imbue Blank Scroll with "%s"', imbuement.name))
    end
    local itensDetails = self.window:recursiveGetChildById("itensDetails")
    if itensDetails then
        itensDetails:setText("")
    end
end
function ImbuementScroll.applySelectedImbuement()
    local imbuement = self.selectedImbuement
    if not imbuement then
        return
    end

    if self.confirmWindow then
        self.confirmWindow:destroy()
        self.confirmWindow = nil
    end

    Imbuement.hide()

    local function confirm()
        g_game.applyImbuement(0, imbuement.id)
        self.confirmWindow:destroy()
        self.confirmWindow = nil
        Imbuement.show()
    end

    local function cancelFunc()
        if self.confirmWindow then
            self.confirmWindow:destroy()
            self.confirmWindow = nil
        end
        Imbuement.show()
    end

    self.confirmWindow = displayGeneralBox(tr('Confirm Imbuing'), tr("You are about to imbue your scroll with \"%s\". This will consume the required astral sources and %s gold coins. Do you wish to proceed?", string.capitalize(imbuement.name), comma_value(imbuement.cost or 0)),
        { { text = tr('Cancel'), callback = cancelFunc },
            { text = tr('Accept'), callback = confirm }
        }, confirm, cancelFunc)
end