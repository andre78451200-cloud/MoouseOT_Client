--[[
  MTC Bot - Sistema de Configuracao
  Salva e carrega configuracoes do bot usando arquivo JSON
  Configuracoes sao salvas POR PERSONAGEM (cada char tem suas configs)
]]

MTCConfig = MTCConfig or {}

-- Storage interno
MTCConfig.data = {}
MTCConfig.allData = {}  -- Dados de todos os personagens
MTCConfig.filePath = "/mtcbot_settings.json"
MTCConfig.currentCharName = nil

-- Obtem o nome do personagem atual
function MTCConfig.getCharName()
  if g_game.isOnline() then
    local player = g_game.getLocalPlayer()
    if player then
      return player:getName()
    end
  end
  return "default"
end

-- Inicializa o sistema de config
function MTCConfig.init()
  MTCConfig.loadAll()
  MTCConfig.loadForCurrentChar()
end

-- Carrega configs para o personagem atual
function MTCConfig.loadForCurrentChar()
  local charName = MTCConfig.getCharName()
  MTCConfig.currentCharName = charName
  
  if MTCConfig.allData[charName] then
    MTCConfig.data = MTCConfig.allData[charName]
    print("[MTCConfig] Configuracoes carregadas para: " .. charName)
  else
    MTCConfig.data = {}
    print("[MTCConfig] Novo personagem detectado: " .. charName)
  end
end

-- Obtem um valor da configuracao
function MTCConfig.get(key)
  return MTCConfig.data[key]
end

-- Define um valor na configuracao
function MTCConfig.set(key, value)
  MTCConfig.data[key] = value
  MTCConfig.save()
end

-- Salva todas as configuracoes em arquivo JSON
function MTCConfig.save()
  local status, result = pcall(function()
    local charName = MTCConfig.getCharName()
    MTCConfig.allData[charName] = MTCConfig.data
    local jsonStr = json.encode(MTCConfig.allData, 2)
    g_resources.writeFileContents(MTCConfig.filePath, jsonStr)
  end)
  if not status then
    print("[MTCConfig] Erro ao salvar: " .. tostring(result))
  end
end

-- Carrega dados de todos os personagens
function MTCConfig.loadAll()
  local status, result = pcall(function()
    if g_resources.fileExists(MTCConfig.filePath) then
      local content = g_resources.readFileContents(MTCConfig.filePath)
      if content and content ~= "" then
        MTCConfig.allData = json.decode(content)
      end
    end
  end)
  if not status then
    print("[MTCConfig] Erro ao carregar: " .. tostring(result))
    MTCConfig.allData = {}
  end
end

-- Reseta configuracoes do personagem atual
function MTCConfig.reset()
  MTCConfig.data = {}
  MTCConfig.save()
end

-- Reseta configuracoes de TODOS os personagens
function MTCConfig.resetAll()
  MTCConfig.allData = {}
  MTCConfig.data = {}
  MTCConfig.save()
end

-- Obtem lista de personagens com config salva
function MTCConfig.getSavedCharacters()
  local chars = {}
  for name, _ in pairs(MTCConfig.allData) do
    table.insert(chars, name)
  end
  return chars
end

-- Verifica se trocou de personagem e recarrega configs
function MTCConfig.checkCharacterChange()
  local currentChar = MTCConfig.getCharName()
  if currentChar ~= MTCConfig.currentCharName then
    print("[MTCConfig] Personagem trocado! Recarregando configs...")
    MTCConfig.loadForCurrentChar()
    return true
  end
  return false
end

return MTCConfig
