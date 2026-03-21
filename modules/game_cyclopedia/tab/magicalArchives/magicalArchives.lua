local UI = nil
local spellList = nil
local spellInfo = nil
local actualList = nil
local allSpells = {} -- Cache wszystkich czarów do filtrowania

function showMagicalArchives()
    UI = g_ui.loadUI("magicalArchives", contentContainer)
    UI:show()
    controllerCyclopedia.ui.CharmsBase:setVisible(false)
    controllerCyclopedia.ui.GoldBase:setVisible(false)
    controllerCyclopedia.ui.BestiaryTrackerButton:setVisible(false)
    if g_game.getClientVersion() >= 1410 then
        controllerCyclopedia.ui.CharmsBase1410:setVisible(false)
    end
    
    -- Initialize spell archive
    initializeMagicalArchive()
end

function initializeMagicalArchive()
    if not UI then 
        print("UI is nil")
        return 
    end
    
    -- Debug: list all children
    print("UI children:")
    for i, child in ipairs(UI:getChildren()) do
        print("  - " .. child:getId())
        for j, subchild in ipairs(child:getChildren()) do
            print("    - " .. subchild:getId())
            for k, subsubchild in ipairs(subchild:getChildren()) do
                print("      - " .. subsubchild:getId())
            end
        end
    end
    
    -- Get spell list widget
    spellList = UI:recursiveGetChildById('TextListQuestLog')
    spellInfo = UI:recursiveGetChildById('spellAndRune')
    
    print("spellList:", spellList)
    print("spellInfo:", spellInfo)
    
    if not spellList then
        print("Could not find spell list widget")
        return
    end
    
    -- Clear existing items - get the internal TextList and destroy its children
    actualList = spellList:getChildById('questList')
    if not actualList then
        print("Could not find internal questList widget")
        return
    end
    
    actualList:destroyChildren()
    
    -- Clear and rebuild spells cache
    allSpells = {}
    
    -- Add spells from gamelib
    local SpelllistProfile = 'Default'
    if SpelllistSettings[SpelllistProfile] and SpellInfo[SpelllistProfile] then
        for i = 1, #SpelllistSettings[SpelllistProfile].spellOrder do
            local spellName = SpelllistSettings[SpelllistProfile].spellOrder[i]
            local spell = SpellInfo[SpelllistProfile][spellName]
            
            if spell then
                -- Store in cache
                table.insert(allSpells, {name = spellName, data = spell})
            end
        end
    end
    
    -- Display all spells initially
    displaySpells(allSpells)
    
    -- Set up search functionality
    local searchEdit = UI:recursiveGetChildById('SearchEdit')
    if searchEdit then
        print("Search edit found, setting up search handler")
        connect(searchEdit, {
            onTextChange = function(widget, text)
                print("Search text changed:", text)
                onMagicalArchiveSearch(text)
            end
        })
    else
        print("Search edit not found!")
    end
end

function showSpellDetails(spellName, spell)
    if not spellInfo then 
        return 
    end
    
    -- Clear existing info
    spellInfo:destroyChildren()
    
    -- Create detailed spell information
    local detailsWidget = g_ui.createWidget('UIWidget', spellInfo)
    detailsWidget:setId('spellDetails')
    -- Fill parent using anchors
    detailsWidget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    detailsWidget:addAnchor(AnchorTop, 'parent', AnchorTop)
    detailsWidget:addAnchor(AnchorRight, 'parent', AnchorRight)
    detailsWidget:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    
    -- Spell name
    local nameLabel = g_ui.createWidget('Label', detailsWidget)
    nameLabel:setText(spellName)
    nameLabel:setFont('verdana-11px-rounded')
    nameLabel:setTextAlign(AlignTopLeft)
    nameLabel:setPosition({x = 10, y = 10})
    nameLabel:setHeight(20)
    
    -- Spell words
    local wordsLabel = g_ui.createWidget('Label', detailsWidget)
    wordsLabel:setText('Words: ' .. (spell.words or 'Unknown'))
    wordsLabel:setPosition({x = 10, y = 35})
    wordsLabel:setHeight(15)
    
    -- Level requirement
    local levelLabel = g_ui.createWidget('Label', detailsWidget)
    levelLabel:setText('Level: ' .. (spell.level or 0))
    levelLabel:setPosition({x = 10, y = 55})
    levelLabel:setHeight(15)
    
    -- Mana cost
    local manaLabel = g_ui.createWidget('Label', detailsWidget)
    manaLabel:setText('Mana: ' .. (spell.mana or 0))
    manaLabel:setPosition({x = 10, y = 75})
    manaLabel:setHeight(15)
    
    -- Soul points
    local soulLabel = g_ui.createWidget('Label', detailsWidget)
    soulLabel:setText('Soul: ' .. (spell.soul or 0))
    soulLabel:setPosition({x = 10, y = 95})
    soulLabel:setHeight(15)
    
    -- Cooldown
    local cooldownLabel = g_ui.createWidget('Label', detailsWidget)
    cooldownLabel:setText('Cooldown: ' .. ((spell.exhaustion or 0) / 1000) .. 's')
    cooldownLabel:setPosition({x = 10, y = 115})
    cooldownLabel:setHeight(15)
    
    -- Premium
    local premiumLabel = g_ui.createWidget('Label', detailsWidget)
    premiumLabel:setText('Premium: ' .. (spell.premium and 'Yes' or 'No'))
    premiumLabel:setPosition({x = 10, y = 135})
    premiumLabel:setHeight(15)
    
    -- Vocations
    local vocationText = 'Vocations: '
    if spell.vocations then
        local vocNames = {}
        for i, vocId in ipairs(spell.vocations) do
            if VocationNames[vocId] then
                table.insert(vocNames, VocationNames[vocId])
            end
        end
        vocationText = vocationText .. table.concat(vocNames, ', ')
    end
    
    local vocationLabel = g_ui.createWidget('Label', detailsWidget)
    vocationLabel:setText(vocationText)
    vocationLabel:setPosition({x = 10, y = 155})
    vocationLabel:setHeight(15)
end

function displaySpells(spells)
    if not actualList then return end
    
    actualList:destroyChildren()
    
    for _, spellData in ipairs(spells) do
        local spellName = spellData.name
        local spell = spellData.data
        
        local item = g_ui.createWidget('SpellListLabel', actualList)
        item:setText(spellName)
        item:setHeight(20)
        item:setPhantom(false)
        item:setFocusable(true)
        item.spellName = spellName
        item.spellData = spell
        
        -- Set up click handler using connect
        connect(item, {onMousePress = function(widget, mousePos, mouseButton)
            if mouseButton == MouseLeftButton then
                showSpellDetails(spellName, spell)
                -- Focus the item to show selection
                actualList:focusChild(item)
                return true
            end
            return false
        end})
    end
end

-- Funkcja wyszukiwania dla magical archives
function onMagicalArchiveSearch(searchText)
    print("onMagicalArchiveSearch called with:", searchText)
    if not searchText or searchText == "" then
        print("Empty search, displaying all spells")
        displaySpells(allSpells)
        return
    end
    
    local filteredSpells = {}
    local lowerSearchText = searchText:lower()
    
    for _, spellData in ipairs(allSpells) do
        local spellName = spellData.name:lower()
        local spellWords = ""
        if spellData.data.words then
            spellWords = spellData.data.words:lower()
        end
        
        -- Szukaj w nazwie czaru lub słowach magicznych
        if string.find(spellName, lowerSearchText, 1, true) or 
           string.find(spellWords, lowerSearchText, 1, true) then
            table.insert(filteredSpells, spellData)
        end
    end
    
    displaySpells(filteredSpells)
end

