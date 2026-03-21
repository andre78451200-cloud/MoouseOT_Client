if not UIMiniWindow then
    dofile 'uiminiwindow'
end

-- @docclass
UIMessageBox = extends(UIMiniWindow, 'UIMessageBox')

-- messagebox cannot be created from otui files
function UIMessageBox.create(title, okCallback, cancelCallback)
    local calendar = UIMessageBox.internalCreate()
    return calendar
end

function UIMessageBox.display(title, message, buttons, onEnterCallback, onEscapeCallback)
    local staticSizes = {
        width = {
            max = 916,
            min = 116
        },
        height = {
            min = 56,
            max = 616
        }
    }
    local currentSizes = {
        width = 0,
        height = 0
    }

    local messageBox = g_ui.createWidget('MessageBoxWindow', rootWidget)
    messageBox.title = messageBox:getChildById('title')
    messageBox.title:setText(title)

    messageBox.content = messageBox:getChildById('content')
    messageBox.content:setText(message)
    messageBox.content:resizeToText()
    messageBox.content:resize(messageBox.content:getWidth(), messageBox.content:getHeight())
    currentSizes.width = currentSizes.width + messageBox.content:getWidth() + 32
    currentSizes.height = currentSizes.height + messageBox.content:getHeight() + 20

    messageBox.holder = messageBox:getChildById('holder')

    currentSizes.height = currentSizes.height + 22
    
    -- Calcula largura total dos botões para centralizar
    local totalButtonsWidth = 0
    local buttonWidths = {}
    for i = 1, #buttons do
        local btnWidth = math.max(90, 14 + (string.len(buttons[i].text) * 9))
        buttonWidths[i] = btnWidth
        totalButtonsWidth = totalButtonsWidth + btnWidth
        if i > 1 then
            totalButtonsWidth = totalButtonsWidth + 10 -- margin entre botões
        end
    end
    
    for i = 1, #buttons do
        local button = messageBox:addButton(buttons[i].text, buttons[i].callback)
        button:addAnchor(AnchorTop, 'parent', AnchorTop)
        if i == 1 then
            -- Primeiro botão: centraliza usando HorizontalCenter com offset negativo
            button:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
            button:setMarginLeft(-totalButtonsWidth/2 + buttonWidths[1]/2)
            currentSizes.height = currentSizes.height + button:getHeight() + 22
        else
            button:addAnchor(AnchorLeft, 'prev', AnchorRight)
            button:setMarginLeft(10)
        end
    end

    messageBox:setWidth(math.min(staticSizes.width.max, math.max(staticSizes.width.min, currentSizes.width)))
    messageBox:setHeight(math.min(staticSizes.height.max, math.max(staticSizes.height.min, currentSizes.height)))

    if onEnterCallback then
        connect(messageBox, {
            onEnter = onEnterCallback
        })
    end
    if onEscapeCallback then
        connect(messageBox, {
            onEscape = onEscapeCallback
        })
    end

    return messageBox
end

function displayInfoBox(title, message)
    local messageBox
    local defaultCallback = function()
        messageBox:ok()
    end
    messageBox = UIMessageBox.display(title, message, {{
        text = 'Ok',
        callback = defaultCallback
    }}, defaultCallback, defaultCallback)
    return messageBox
end

function displayErrorBox(title, message)
    local messageBox
    local defaultCallback = function()
        messageBox:ok()
    end
    messageBox = UIMessageBox.display(title, message, {{
        text = 'Ok',
        callback = defaultCallback
    }}, defaultCallback, defaultCallback)
    return messageBox
end

function displayCancelBox(title, message)
    local messageBox
    local defaultCallback = function()
        messageBox:cancel()
    end
    messageBox = UIMessageBox.display(title, message, {{
        text = 'Cancel',
        callback = defaultCallback
    }}, defaultCallback, defaultCallback)
    return messageBox
end

function displayGeneralBox(title, message, buttons, onEnterCallback, onEscapeCallback)
    return UIMessageBox.display(title, message, buttons, onEnterCallback, onEscapeCallback)
end

function displayGeneralSHOPBox(title, message,description, buttons, onEnterCallback, onEscapeCallback)
    return UIMessageBox.displaySHOP(title, message,description, buttons, onEnterCallback, onEscapeCallback)
end

function UIMessageBox:addButton(text, callback)
    local holder = self:getChildById('holder')
    
    -- Determine button type based on text
    local lowerText = text:lower()
    
    -- Check for positive/confirm buttons (green)
    local isPositive = lowerText == 'yes' or lowerText == 'sim' or lowerText == 'accept' or 
                       lowerText == 'aceitar' or lowerText == 'ok' or lowerText == 'confirm' or 
                       lowerText == 'confirmar'
    
    -- Check for negative/cancel buttons (red) - use string.find for UTF-8 compatibility
    local isNegative = lowerText == 'no' or lowerText == 'nao' or lowerText == 'cancel' or 
                       lowerText == 'cancelar' or lowerText == 'close' or lowerText == 'fechar' or
                       (string.find(lowerText, 'n') == 1 and string.find(lowerText, 'o') ~= nil and #lowerText <= 5)
    
    -- Create button with appropriate style
    local buttonStyle = 'QtButton'
    if isPositive then
        buttonStyle = 'ConfirmButton'
    elseif isNegative then
        buttonStyle = 'CancelButton'
    end
    
    local button = g_ui.createWidget(buttonStyle, holder)
    button:setWidth(math.max(90, 14 + (string.len(text) * 9)))
    button:setHeight(28)
    button:setText(text)
    
    connect(button, {
        onClick = callback
    })
    return button
end

function UIMessageBox:ok()
    signalcall(self.onOk, self)
    self.onOk = nil
    self:destroy()
end

function UIMessageBox:cancel()
    signalcall(self.onCancel, self)
    self.onCancel = nil
    self:destroy()
end

function UIMessageBox.displaySHOP(title, message, description, buttons, onEnterCallback, onEscapeCallback)
    local staticSizes = {
        width = {
            max = 390,
            min = 390
        },
        height = {
            min = 200,
            max = 200
        }
    }
    local currentSizes = {
        width = 0,
        height = 0
    }

    local messageBox = g_ui.createWidget('MessageBoxShopWindow', rootWidget)
    messageBox.title = messageBox:getChildById('title')
    messageBox.title:setText(title)
    messageBox.title:setTextAutoResize(true)

    messageBox.content = messageBox:getChildById('content')
    messageBox.content:setText(message)
    messageBox.content:setTextAutoResize(true)
    messageBox.content:setTextWrap(true)
    messageBox.content:setTextAlign(AlignCenter)

    messageBox.additionalLabel:setText(description)
    messageBox.additionalLabel:setTextWrap(true)
    messageBox.additionalLabel:setTextAlign(AlignCenter)

    local contentWidth = messageBox.content:getTextSize().width + messageBox.content:getPaddingLeft() + messageBox.content:getPaddingRight()
    local contentHeight = messageBox.content:getHeight() + messageBox.content:getPaddingTop() + messageBox.content:getPaddingBottom()

    currentSizes.width = contentWidth + 32
    currentSizes.height = contentHeight + 20

    messageBox.holder = messageBox:getChildById('holder')

    currentSizes.height = currentSizes.height + 22
    for i = 1, #buttons do
        local button = messageBox:addButton(buttons[i].text, buttons[i].callback)
        button:addAnchor(AnchorTop, 'parent', AnchorTop)
        if i == 1 then
            button:addAnchor(AnchorRight, 'parent', AnchorRight)
            currentSizes.height = currentSizes.height + button:getHeight() + 22
            button:setImageSource('/images/options/blue_large')
            button:setImageClip("0 0 108 20")
        else
            button:addAnchor(AnchorRight, 'prev', AnchorLeft)

            button:setMarginRight(10)
        end
    end

    messageBox:setWidth(currentSizes.width)
    messageBox:setHeight(math.min(staticSizes.height.max, math.max(staticSizes.height.min, currentSizes.height)))

    if onEnterCallback then
        connect(messageBox, {
            onEnter = onEnterCallback
        })
    end
    if onEscapeCallback then
        connect(messageBox, {
            onEscape = onEscapeCallback
        })
    end

    return messageBox
end
