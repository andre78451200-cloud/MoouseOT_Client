local function getUsedHotkeyButton(key)
    for _, actionbar in pairs(activeActionBars) do
        for _, button in pairs(actionbar.tabBar:getChildren()) do
            local hotkey = button.cache.hotkey
            if hotkey and hotkey:lower() == key:lower() then
                return button
            end
        end
    end
    return nil
end

local function isHotkeyUsedInternal(key, chatType, checkSecondary)
    if not key or not ApiJson.hasCurrentHotkeySet() then
        return false
    end

    for _, data in ipairs(ApiJson.getHotkeyEntries(chatType)) do
        if data["actionsetting"] and data["keysequence"] then
            local keyMatch = data["keysequence"]:lower() == key:lower()
            if checkSecondary then
                if data["secondary"] and keyMatch then
                    return true
                end
            elseif not data["secondary"] and keyMatch then
                return true
            end
        end
    end
    return false
end

local function isHotkeyUsed(key, secondary)
    if not secondary then
        secondary = false
    end

    local chatMode = modules.game_console.isChatEnabled() and 'chatOn' or 'chatOff'
    return isHotkeyUsedInternal(key, chatMode, secondary)
end

local function manageKeyPress(window, keyCode, keyboardModifiers, keyText)
    local keyCombo = determineKeyComboDesc(keyCode, keyboardModifiers, keyText)
    local resetCombo = {"Shift", "Ctrl", "Alt"}
    if table.contains(resetCombo, keyCombo) then
        window.display:setText('')
        window.display.combo = ''
        window.warning:setVisible(false)
        window.buttonOk:setEnabled(true)
        return true
    end

    local shortCut = (keyCombo == "HalfQuote" and "'" or keyCombo)
    window.display:setText(shortCut)
    window.display.combo = keyCombo
    window.warning:setVisible(false)
    window.buttonOk:setEnabled(true)
    if isHotkeyUsed(keyCombo) then
        window.warning:setVisible(true)
        window.warning:setText("This hotkey is already in use and will be overwritten.")
    end

    if table.contains(blockedKeys, keyCombo) then
        window.warning:setVisible(true)
        window.warning:setText("This hotkey is already in use and cannot be overwritten.")
        window.buttonOk:setEnabled(false)
    end
    return true
end

-- check game_hotkeys
local function isHotkeyUsedByGameHotkeys(keyCombo)
    if not keyCombo or keyCombo == "" then
        return false
    end

    if modules.game_hotkeys and modules.game_hotkeys.isHotkeyUsedByManager then
        return modules.game_hotkeys.isHotkeyUsedByManager(keyCombo)
    end

    return false
end

local function removeHotkeyFromGameHotkeys(keyCombo)
    if not keyCombo or keyCombo == "" then
        return false
    end

    if modules.game_hotkeys and modules.game_hotkeys.removeHotkeyByCombo then
        return modules.game_hotkeys.removeHotkeyByCombo(keyCombo)
    end

    return false
end

-- check keybind
local function isHotkeyUsedByKeybinds(keyCombo)
    if not keyCombo or keyCombo == "" then
        return false
    end

    if Keybind and Keybind.isKeyComboUsed then
        if Keybind.isKeyComboUsed(keyCombo, nil, nil, CHAT_MODE.ON) then
            return true
        end
        if Keybind.isKeyComboUsed(keyCombo, nil, nil, CHAT_MODE.OFF) then
            return true
        end
    end

    return false
end

function removeHotkeyFromActionBar(keyCombo)
    if not keyCombo or keyCombo == "" then
        return false
    end
    local button = getUsedHotkeyButton(keyCombo)
    if button then
        ApiJson.removeHotkey(button:getId())
        unbindHotkey(keyCombo)
        updateButton(button)
        return true
    end
    return false
end
-- /*=============================================
-- =            Windows hotkeys OTUI             =
-- =============================================*/
function assignHotkey(button)
    -- Fechar janela anterior se existir
    if ActionBarController._hotkeyWindow then
        ActionBarController._hotkeyWindow:destroy()
        ActionBarController._hotkeyWindow = nil
    end
    local actionbar = button:getParent():getParent()
    if actionbar.locked then
        alert('Action bar is locked')
        return
    end
    local window = g_ui.displayUI('/game_actionbar/otui/assign_hotkey')
    ActionBarController._hotkeyWindow = window

    window.hotkeyBlock = modules.game_hotkeys.createHotkeyBlock("actionbar_assign_hotkey")
    window.onDestroy = function()
        if window.hotkeyBlock then
            window.hotkeyBlock:release()
            window.hotkeyBlock = nil
        end
    end

    local barN = button:getParent():getParent().n
    local barDesc
    if barN < 4 then
        barDesc = "Bottom"
    elseif barN < 7 then
        barDesc = "Left"
    else
        barDesc = "Right"
    end

    barDesc = barDesc .. " Action Bar: Action Button " .. button:getId()
    window:setText('Edit Hotkey for "' .. barDesc .. '"')

    local chatMode = window:getChildById('chatMode')
    local display = window:getChildById('display')
    local desc = window:getChildById('desc')
    local warning = window:getChildById('warning')
    local buttonOk = window:getChildById('buttonOk')
    local buttonClear = window:getChildById('buttonClear')
    local buttonClose = window:getChildById('buttonClose')

    desc:setText('Click "Ok" to assign the hotkey. Click "Clear" to remove the hotkey from "' .. barDesc .. '".')

    local currentHotkey = button.cache.hotkey or ""
    if currentHotkey ~= "" then
        display:setText(currentHotkey)
    else
        display:setText("")
    end
    display.combo = currentHotkey

    local chatOn = modules.game_console.isChatEnabled()
    if chatOn then
        chatMode:setText('Mode: "Chat On"')
    else
        chatMode:setText('Mode: "Chat Off"')
    end

    local function closeWindow()
        if ActionBarController._hotkeyWindow then
            ActionBarController._hotkeyWindow:destroy()
            ActionBarController._hotkeyWindow = nil
        end
    end

    window:grabKeyboard()
    window.onKeyDown = function(self, keyCode, keyboardModifiers, keyText)
        local keyCombo = determineKeyComboDesc(keyCode, keyboardModifiers, keyText)
        local resetCombo = {"Shift", "Ctrl", "Alt"}
        if table.contains(resetCombo, keyCombo) then
            display:setText('')
            display.combo = ''
            warning:setVisible(false)
            buttonOk:setEnabled(true)
            return true
        end

        local shortCut = (keyCombo == "HalfQuote" and "'" or keyCombo)
        display:setText(shortCut)
        display.combo = keyCombo
        warning:setVisible(false)
        buttonOk:setEnabled(true)
        if isHotkeyUsed(keyCombo) then
            warning:setVisible(true)
            warning:setText("This hotkey is already in use in Action Bar and will be overwritten.")
        end

        -- check game_hotkeys
        if isHotkeyUsedByGameHotkeys(keyCombo) then
            warning:setVisible(true)
            warning:setText("This hotkey is already in use in Hotkeys Manager and will be overwritten.")
        end

        -- check keybinds
        if isHotkeyUsedByKeybinds(keyCombo) then
            warning:setVisible(true)
            warning:setText("This hotkey is already in use in Keybinds and will be overwritten.")
            buttonOk:disable()
            return true
        end
        if table.contains(blockedKeys, keyCombo) then
            warning:setVisible(true)
            warning:setText("This hotkey is already in use and cannot be overwritten.")
            buttonOk:setEnabled(false)
        end
        return true
    end

    local okFunc = function()
        local lastHotkey = button.cache.hotkey or ""
        local hotkey = display.combo or ""

        if hotkey == "" then
            if lastHotkey ~= "" then
                ApiJson.removeHotkey(button:getId())
                unbindHotkey(lastHotkey)
                updateButton(button)
            end

            closeWindow()
            return true
        end

        ApiJson.clearHotkey(hotkey)
       if isHotkeyUsedByGameHotkeys(hotkey) then
            removeHotkeyFromGameHotkeys(hotkey)
        end
        local usedButton = getUsedHotkeyButton(hotkey)
        if usedButton then
            ApiJson.removeHotkey(usedButton:getId())
            unbindHotkey(hotkey)
            updateButton(usedButton)
        else
            unbindHotkey(hotkey)
        end

        if lastHotkey ~= "" and lastHotkey ~= hotkey then
            ApiJson.removeHotkey(button:getId())
            unbindHotkey(lastHotkey)
        end

        ApiJson.updateActionBarHotkey("TriggerActionButton_" .. button:getId(), hotkey)
        updateButton(button)

        closeWindow()
    end

    local clearFunc = function()
        local assignedHotkey = button.cache.hotkey or ""
        ApiJson.removeHotkey(button:getId())
        if assignedHotkey ~= '' then
            unbindHotkey(assignedHotkey)
        end

        updateButton(button)
        display:setText('')
        display.combo = ''
        closeWindow()
    end

    buttonOk.onClick = okFunc
    buttonClear.onClick = clearFunc
    buttonClose.onClick = closeWindow

    window.onEnter = okFunc
    window.onEscape = closeWindow
end

function unbindHotkey(hotkey)
    if not gameRootPanel or not hotkey or hotkey == '' then
        return
    end

    g_keyboard.unbindKeyPress(hotkey, nil, gameRootPanel)
    g_keyboard.unbindKeyDown(hotkey, nil, gameRootPanel)
    g_keyboard.unbindKeyUp(hotkey, nil, gameRootPanel)
end


