--[[
  MTC Bot - Sistema de Tools (Suporte)
  
  Magias de suporte automaticas:
  - Haste (utani hur, utani gran hur, utani tempo hur)
  - Magic Shield (utamo vita)
  - Buff spells (utito tempo, utamo tempo, etc)
]]

MTCTools = MTCTools or {}

-- Configuracao padrao
MTCTools.defaultConfig = {
  enabled = false,
  
  -- Haste (correr mais rapido)
  haste = {
    enabled = false,
    spell = "utani hur"
  },
  
  -- Magic Shield (absorve dano na mana)
  magicShield = {
    enabled = false,
    spell = "utamo vita"
  },
  
  -- Utito Tempo (buff de ataque melee - Knight)
  utitoTempo = {
    enabled = false,
    spell = "utito tempo"
  },
  
  -- Utamo Tempo (buff de defesa - Knight)
  utamoTempo = {
    enabled = false,
    spell = "utamo tempo"
  },
  
  -- Sharpshooter (buff de ataque - Paladin)
  sharpshooter = {
    enabled = false,
    spell = "utito tempo san"
  },
  
  -- Swift Foot (velocidade de ataque - Paladin)
  swiftFoot = {
    enabled = false,
    spell = "utamo tempo san"
  },
  
  -- Protector (buff de defesa geral)
  protector = {
    enabled = false,
    spell = "utamo tempo"
  },
  
  -- Blood Rage (buff de ataque - Knight)
  bloodRage = {
    enabled = false,
    spell = "utito tempo"
  },
  
  -- Charge (Knight)
  charge = {
    enabled = false,
    spell = "utani tempo hur"
  },
  
  -- Strong Haste
  strongHaste = {
    enabled = false,
    spell = "utani gran hur"
  }
}

-- Spells de suporte por tipo
MTCTools.supportSpells = {
  -- Haste spells (velocidade de movimento)
  haste = {
    { words = "utani hur", name = "Haste", mana = 60, level = 14, voc = {1,2,3,4,5,11,12,13,14,15}, duration = 33000 },
    { words = "utani gran hur", name = "Strong Haste", mana = 100, level = 20, voc = {3,4,13,14}, duration = 22000 },
    { words = "utani tempo hur", name = "Charge", mana = 100, level = 25, voc = {1,11}, duration = 5000 },
  },
  
  -- Magic Shield
  magicShield = {
    { words = "utamo vita", name = "Magic Shield", mana = 50, level = 14, voc = {3,4,13,14}, duration = 200000 },
  },
  
  -- Buff de ataque
  attackBuff = {
    { words = "utito tempo", name = "Blood Rage", mana = 290, level = 60, voc = {1,11}, duration = 10000 },
    { words = "utito tempo san", name = "Sharpshooter", mana = 450, level = 60, voc = {2,12}, duration = 10000 },
  },
  
  -- Buff de defesa
  defenseBuff = {
    { words = "utamo tempo", name = "Protector", mana = 200, level = 55, voc = {1,11}, duration = 13000 },
    { words = "utamo tempo san", name = "Swift Foot", mana = 400, level = 55, voc = {2,12}, duration = 10000 },
  },
  
  -- Curas e Remocoes de debuff
  cureSpells = {
    { words = "exana amp res", name = "Remove Curse", mana = 300, level = 100, voc = {3,4,13,14}, duration = 0 },
    { words = "exana pox", name = "Cure Poison", mana = 30, level = 10, voc = {1,2,3,4,5,11,12,13,14,15}, duration = 0 },
    { words = "exana flam", name = "Cure Burning", mana = 30, level = 30, voc = {1,2,3,4,11,12,13,14}, duration = 0 },
    { words = "exana vis", name = "Cure Electrification", mana = 30, level = 22, voc = {1,2,3,4,11,12,13,14}, duration = 0 },
    { words = "exana kor", name = "Cure Bleeding", mana = 30, level = 45, voc = {1,11}, duration = 0 },
  },
  
  -- Cancelamentos
  cancelSpells = {
    { words = "uteta reeq", name = "Cancel Invisibility", mana = 200, level = 26, voc = {1,2,3,4,5,11,12,13,14,15}, duration = 0 },
    { words = "uteta res eq", name = "Cancel Magic Shield", mana = 50, level = 14, voc = {3,4,13,14}, duration = 0 },
  },
  
  -- Familiares
  familiars = {
    { words = "utevo res dru", name = "Summon Grovebeast", mana = 3000, level = 200, voc = {4,14}, duration = 900000 },
    { words = "utevo res sor", name = "Summon Skullfrost", mana = 3000, level = 200, voc = {3,13}, duration = 900000 },
    { words = "utevo res kni", name = "Summon Emberwing", mana = 3000, level = 200, voc = {1,11}, duration = 900000 },
    { words = "utevo res pal", name = "Summon Thundergiant", mana = 3000, level = 200, voc = {2,12}, duration = 900000 },
  },
  
  -- Paladin especiais
  paladinSupport = {
    { words = "utevo grav san", name = "Divine Dazzle", mana = 80, level = 250, voc = {2,12}, duration = 0 },
  },
}

-- Variaveis de controle
MTCTools.config = nil
MTCTools.lastCastTime = {}    -- Guarda ultimo cast para evitar spam
MTCTools.spellCooldown = 1000  -- Cooldown minimo entre casts (1 segundo)

-- Constantes dos PlayerStates (valores fixos do protocolo)
local STATE_HASTE = 64
local STATE_MANASHIELD = 16
local STATE_NEWMANASHIELD = 67108864  -- Novo Magic Shield (versoes mais novas)
local STATE_PARTYBUFF = 4096
local STATE_PARALYZE = 32

-- Inicializa o modulo
function MTCTools.init()
  MTCTools.config = MTCTools.loadConfig()
end

-- Carrega configuracao salva ou usa padrao
function MTCTools.loadConfig()
  local saved = MTCConfig.get("tools")
  if saved then
    return saved
  end
  return MTCTools.defaultConfig
end

-- Salva configuracao
function MTCTools.saveConfig()
  MTCConfig.set("tools", MTCTools.config)
end

-- Retorna vocacao do player
function MTCTools.getPlayerVocation()
  if not g_game.isOnline() then return 0 end
  local player = g_game.getLocalPlayer()
  if not player then return 0 end
  return player:getVocation() or 0
end

-- Verifica se player tem a vocacao para usar a spell
function MTCTools.canUseSpell(spellInfo)
  local voc = MTCTools.getPlayerVocation()
  if voc == 0 then return true end  -- Se nao conseguir pegar voc, permite
  
  for _, v in ipairs(spellInfo.voc) do
    if v == voc then
      return true
    end
  end
  return false
end

-- Verifica se o player tem um estado/buff ativo usando bit.band
function MTCTools.hasState(state)
  if not g_game.isOnline() then return false end
  local player = g_game.getLocalPlayer()
  if not player then return false end
  
  local states = player:getStates()
  if not states or states == 0 then return false end
  
  -- Usa bit ou bit32
  local bitlib = bit or bit32
  if not bitlib then return false end
  
  return bitlib.band(states, state) > 0
end

-- Verifica se tem Haste ativo
function MTCTools.hasHaste()
  return MTCTools.hasState(STATE_HASTE)
end

-- Verifica se tem Magic Shield ativo (verifica ambos os estados: antigo e novo)
function MTCTools.hasManaShield()
  -- Verifica o estado antigo (16) e o novo (67108864)
  if MTCTools.hasState(STATE_MANASHIELD) then
    return true
  end
  if MTCTools.hasState(STATE_NEWMANASHIELD) then
    return true
  end
  return false
end

-- Verifica se tem PartyBuff ativo (Blood Rage, Protector, Sharpshooter, Swift Foot)
-- Todos esses buffs usam o mesmo icone PartyBuff
function MTCTools.hasPartyBuff()
  -- Verifica o estado PartyBuff (4096)
  if MTCTools.hasState(STATE_PARTYBUFF) then
    return true
  end
  return false
end

-- Verifica se esta paralyzed
function MTCTools.isParalyzed()
  return MTCTools.hasState(STATE_PARALYZE)
end

-- Verifica se passou cooldown desde ultimo cast
function MTCTools.canCast(spellKey)
  local now = g_clock.millis()
  local lastCast = MTCTools.lastCastTime[spellKey] or 0
  return (now - lastCast) >= MTCTools.spellCooldown
end

-- Obtem info da spell pelo words
function MTCTools.getSpellInfo(spellWords)
  for category, spells in pairs(MTCTools.supportSpells) do
    for _, spell in ipairs(spells) do
      if spell.words == spellWords then
        return spell
      end
    end
  end
  return nil
end

-- Casta spell de Haste (verifica se nao tem haste ativo)
function MTCTools.castHaste(spellKey, spellWords)
  if not g_game.isOnline() then return false end
  
  local player = g_game.getLocalPlayer()
  if not player then return false end
  
  -- Se ja tem haste, nao precisa castar
  if MTCTools.hasHaste() then
    return false
  end
  
  -- Verifica cooldown para evitar spam
  if not MTCTools.canCast(spellKey) then
    return false
  end
  
  local spellInfo = MTCTools.getSpellInfo(spellWords)
  if not spellInfo then return false end
  
  -- Verifica mana
  local mana = player:getMana()
  if mana < spellInfo.mana then return false end
  
  -- Verifica vocacao
  if not MTCTools.canUseSpell(spellInfo) then return false end
  
  -- Casta
  g_game.talk(spellWords)
  MTCTools.lastCastTime[spellKey] = g_clock.millis()
  
  return true
end

-- Casta Magic Shield (verifica se nao tem shield ativo)
function MTCTools.castManaShield(spellKey, spellWords)
  if not g_game.isOnline() then return false end
  
  local player = g_game.getLocalPlayer()
  if not player then return false end
  
  -- Se ja tem magic shield, nao precisa castar
  if MTCTools.hasManaShield() then
    return false
  end
  
  -- Verifica cooldown para evitar spam
  if not MTCTools.canCast(spellKey) then
    return false
  end
  
  local spellInfo = MTCTools.getSpellInfo(spellWords)
  if not spellInfo then return false end
  
  -- Verifica mana
  local mana = player:getMana()
  if mana < spellInfo.mana then return false end
  
  -- Verifica vocacao
  if not MTCTools.canUseSpell(spellInfo) then return false end
  
  -- Casta
  g_game.talk(spellWords)
  MTCTools.lastCastTime[spellKey] = g_clock.millis()
  
  return true
end

-- Casta spell de Buff (verifica se nao tem party buff ativo)
function MTCTools.castBuff(spellKey, spellWords)
  if not g_game.isOnline() then return false end
  
  local player = g_game.getLocalPlayer()
  if not player then return false end
  
  -- Se ja tem party buff, nao precisa castar
  if MTCTools.hasPartyBuff() then
    return false
  end
  
  -- Verifica cooldown para evitar spam
  if not MTCTools.canCast(spellKey) then
    return false
  end
  
  local spellInfo = MTCTools.getSpellInfo(spellWords)
  if not spellInfo then return false end
  
  -- Verifica mana
  local mana = player:getMana()
  if mana < spellInfo.mana then return false end
  
  -- Verifica vocacao
  if not MTCTools.canUseSpell(spellInfo) then return false end
  
  -- Casta
  g_game.talk(spellWords)
  MTCTools.lastCastTime[spellKey] = g_clock.millis()
  
  return true
end

-- Funcao principal de execucao
function MTCTools.execute()
  if not g_game.isOnline() then return end
  if not MTCTools.config or not MTCTools.config.enabled then return end
  
  local player = g_game.getLocalPlayer()
  if not player then return end
  
  -- ========== HASTE SPELLS (verificam hasHaste) ==========
  
  -- Haste (utani hur)
  if MTCTools.config.haste and MTCTools.config.haste.enabled then
    MTCTools.castHaste("haste", MTCTools.config.haste.spell)
  end
  
  -- Strong Haste (utani gran hur)
  if MTCTools.config.strongHaste and MTCTools.config.strongHaste.enabled then
    MTCTools.castHaste("strongHaste", MTCTools.config.strongHaste.spell)
  end
  
  -- Charge (utani tempo hur)
  if MTCTools.config.charge and MTCTools.config.charge.enabled then
    MTCTools.castHaste("charge", MTCTools.config.charge.spell)
  end
  
  -- ========== MAGIC SHIELD (verifica hasManaShield) ==========
  
  -- Magic Shield (utamo vita)
  if MTCTools.config.magicShield and MTCTools.config.magicShield.enabled then
    MTCTools.castManaShield("magicShield", MTCTools.config.magicShield.spell)
  end
  
  -- ========== BUFF SPELLS (verificam hasPartyBuff) ==========
  
  -- Utito Tempo / Blood Rage
  if MTCTools.config.utitoTempo and MTCTools.config.utitoTempo.enabled then
    MTCTools.castBuff("utitoTempo", MTCTools.config.utitoTempo.spell)
  end
  
  -- Utamo Tempo / Protector
  if MTCTools.config.utamoTempo and MTCTools.config.utamoTempo.enabled then
    MTCTools.castBuff("utamoTempo", MTCTools.config.utamoTempo.spell)
  end
  
  -- Sharpshooter
  if MTCTools.config.sharpshooter and MTCTools.config.sharpshooter.enabled then
    MTCTools.castBuff("sharpshooter", MTCTools.config.sharpshooter.spell)
  end
  
  -- Swift Foot
  if MTCTools.config.swiftFoot and MTCTools.config.swiftFoot.enabled then
    MTCTools.castBuff("swiftFoot", MTCTools.config.swiftFoot.spell)
  end
end

-- Retorna lista de spells de haste disponiveis para a vocacao
function MTCTools.getAvailableHasteSpells()
  local voc = MTCTools.getPlayerVocation()
  local available = {}
  
  for _, spell in ipairs(MTCTools.supportSpells.haste) do
    if voc == 0 then
      table.insert(available, spell)
    else
      for _, v in ipairs(spell.voc) do
        if v == voc then
          table.insert(available, spell)
          break
        end
      end
    end
  end
  
  return available
end

-- Cria a interface de configuracao
function MTCTools.createUI(parent)
  parent:destroyChildren()
  
  -- ========== SECAO HASTE ==========
  local hasteLabel = g_ui.createWidget('Label', parent)
  hasteLabel:setText('Velocidade (Haste)')
  hasteLabel:setColor('#ffaa00')
  hasteLabel:setHeight(18)
  hasteLabel:setMarginTop(5)
  
  -- Haste normal
  MTCTools.createSpellRow(parent, "haste", "Haste", "utani hur")
  
  -- Strong Haste
  MTCTools.createSpellRow(parent, "strongHaste", "Strong Haste", "utani gran hur")
  
  -- Charge (Knight)
  MTCTools.createSpellRow(parent, "charge", "Charge", "utani tempo hur")
  
  -- Separador
  local sep1 = g_ui.createWidget('HorizontalSeparator', parent)
  sep1:setMarginTop(10)
  sep1:setMarginBottom(8)
  
  -- ========== SECAO MAGIC SHIELD ==========
  local shieldLabel = g_ui.createWidget('Label', parent)
  shieldLabel:setText('Magic Shield')
  shieldLabel:setColor('#ffaa00')
  shieldLabel:setHeight(18)
  
  -- Utamo Vita
  MTCTools.createSpellRow(parent, "magicShield", "Magic Shield", "utamo vita")
  
  -- Separador
  local sep2 = g_ui.createWidget('HorizontalSeparator', parent)
  sep2:setMarginTop(10)
  sep2:setMarginBottom(8)
  
  -- ========== SECAO BUFF KNIGHT ==========
  local knightLabel = g_ui.createWidget('Label', parent)
  knightLabel:setText('Buff Knight')
  knightLabel:setColor('#ffaa00')
  knightLabel:setHeight(18)
  
  -- Blood Rage (utito tempo)
  MTCTools.createSpellRow(parent, "utitoTempo", "Blood Rage", "utito tempo")
  
  -- Protector (utamo tempo)
  MTCTools.createSpellRow(parent, "utamoTempo", "Protector", "utamo tempo")
  
  -- Separador
  local sep3 = g_ui.createWidget('HorizontalSeparator', parent)
  sep3:setMarginTop(10)
  sep3:setMarginBottom(8)
  
  -- ========== SECAO BUFF PALADIN ==========
  local paladinLabel = g_ui.createWidget('Label', parent)
  paladinLabel:setText('Buff Paladin')
  paladinLabel:setColor('#ffaa00')
  paladinLabel:setHeight(18)
  
  -- Sharpshooter
  MTCTools.createSpellRow(parent, "sharpshooter", "Sharpshooter", "utito tempo san")
  
  -- Swift Foot
  MTCTools.createSpellRow(parent, "swiftFoot", "Swift Foot", "utamo tempo san")
end

-- Cria uma linha de configuracao de spell
function MTCTools.createSpellRow(parent, configKey, displayName, defaultSpell)
  local config = MTCTools.config[configKey] or { enabled = false, spell = defaultSpell }
  
  local row = g_ui.createWidget('Panel', parent)
  row:setHeight(24)
  row:setMarginTop(3)
  
  -- Checkbox ON/OFF com as words da spell
  local checkBox = g_ui.createWidget('CheckBox', row)
  checkBox:setText(' ' .. (config.spell or defaultSpell))
  checkBox:setChecked(config.enabled)
  checkBox:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  checkBox:addAnchor(AnchorRight, 'parent', AnchorRight)
  checkBox:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
  
  checkBox.onCheckChange = function(widget, checked)
    if not MTCTools.config[configKey] then
      MTCTools.config[configKey] = { enabled = false, spell = defaultSpell }
    end
    MTCTools.config[configKey].enabled = checked
    MTCTools.saveConfig()
  end
end

return MTCTools
