-- @docfuncs @{
function print(...)
    local msg = ''
    local args = { ... }
    local appendSpace = #args > 1
    for i, v in ipairs(args) do
        msg = msg .. tostring(v)
        if appendSpace and i < #args then
            msg = msg .. '    '
        end
    end
    g_logger.log(LogInfo, msg)
end

function pinfo(msg)
    g_logger.log(LogInfo, msg)
end

function perror(msg)
    g_logger.log(LogError, msg)
end

function pwarning(msg)
    g_logger.log(LogWarning, msg)
end

function pdebug(msg)
    g_logger.log(LogDebug, msg)
end

function fatal(msg)
    g_logger.log(LogFatal, msg)
end

function exit()
    g_app.exit()
end

function quit()
    g_app.quit()
end

function connect(object, arg1, arg2, arg3)
    if not object then
        return
    end

    local signalsAndSlots
    local pushFront
    if type(arg1) == 'string' then
        signalsAndSlots = {
            [arg1] = arg2
        }
        pushFront = arg3
    else
        signalsAndSlots = arg1
        pushFront = arg2
    end

    for signal, slot in pairs(signalsAndSlots) do
        if not object[signal] then
            local mt = getmetatable(object)
            if mt and type(object) == 'userdata' then
                object[signal] = function(...)
                    return signalcall(mt[signal], ...)
                end
            end
        end

        if not object[signal] then
            object[signal] = slot
        elseif type(object[signal]) == 'function' then
            object[signal] = { object[signal] }
        end

        if type(slot) ~= 'function' then
            perror(debug.traceback('unable to connect a non function value'))
        end

        if type(object[signal]) == 'table' then
            if pushFront then
                table.insert(object[signal], 1, slot)
            else
                table.insert(object[signal], #object[signal] + 1, slot)
            end
        end
    end
end

function disconnect(object, arg1, arg2)
    local signalsAndSlots
    if type(arg1) == 'string' then
        if arg2 == nil then
            object[arg1] = nil
            return
        end
        signalsAndSlots = {
            [arg1] = arg2
        }
    elseif type(arg1) == 'table' then
        signalsAndSlots = arg1
    else
        perror(debug.traceback('unable to disconnect'))
    end

    for signal, slot in pairs(signalsAndSlots) do
        if not object[signal] then
        elseif type(object[signal]) == 'function' then
            if object[signal] == slot then
                object[signal] = nil
            end
        elseif type(object[signal]) == 'table' then
            for k, func in pairs(object[signal]) do
                if func == slot then
                    table.remove(object[signal], k)

                    if #object[signal] == 1 then
                        object[signal] = object[signal][1]
                    end
                    break
                end
            end
        end
    end
end

function newclass(name)
    if not name then
        perror(debug.traceback('new class has no name.'))
    end

    local class = {}
    function class.internalCreate()
        local instance = {}
        for k, v in pairs(class) do
            instance[k] = v
        end
        return instance
    end

    class.create = class.internalCreate
    class.__class = name
    class.getClassName = function()
        return name
    end
    return class
end

function extends(base, name)
    if not name then
        perror(debug.traceback('extended class has no name.'))
    end

    local derived = {}
    function derived.internalCreate()
        local instance = base.create()
        for k, v in pairs(derived) do
            instance[k] = v
        end
        return instance
    end

    derived.create = derived.internalCreate
    derived.__class = name
    derived.getClassName = function()
        return name
    end
    return derived
end

function runinsandbox(func, ...)
    if type(func) == 'string' then
        func, err = loadfile(resolvepath(func, 2))
        if not func then
            error(err)
        end
    end
    local env = {}
    local oldenv = getfenv(0)
    setmetatable(env, {
        __index = oldenv
    })
    setfenv(0, env)
    func(...)
    setfenv(0, oldenv)
    return env
end

function loadasmodule(name, file)
    file = file or resolvepath(name, 2)
    if package.loaded[name] then
        return package.loaded[name]
    end
    local env = runinsandbox(file)
    package.loaded[name] = env
    return env
end

local function module_loader(modname)
    local module = g_modules.getModule(modname)
    if not module then
        return '\n\tno module \'' .. modname .. '\''
    end
    return function()
        if not module:load() then
            error('unable to load required module ' .. modname)
        end
        return module:getSandbox()
    end
end
table.insert(package.loaders, 1, module_loader)

function import(table)
    assert(type(table) == 'table')
    local env = getfenv(2)
    for k, v in pairs(table) do
        env[k] = v
    end
end

function export(what, key)
    if key ~= nil then
        _G[key] = what
    else
        for k, v in pairs(what) do
            _G[k] = v
        end
    end
end

function unexport(key)
    if type(key) == 'table' then
        for _k, v in pairs(key) do
            _G[v] = nil
        end
    else
        _G[key] = nil
    end
end

function getfsrcpath(depth)
    depth = depth or 2
    local info = debug.getinfo(1 + depth, 'Sn')
    local path
    if info.short_src then
        path = info.short_src:match('(.*)/.*')
    end
    if not path then
        path = '/'
    elseif path:sub(0, 1) ~= '/' then
        path = '/' .. path
    end
    return path
end

function resolvepath(filePath, depth)
    if not filePath then
        return nil
    end
    depth = depth or 1
    if filePath then
        if filePath:sub(0, 1) ~= '/' then
            local basepath = getfsrcpath(depth + 1)
            if basepath:sub(#basepath) ~= '/' then
                basepath = basepath .. '/'
            end
            return basepath .. filePath
        else
            return filePath
        end
    else
        local basepath = getfsrcpath(depth + 1)
        if basepath:sub(#basepath) ~= '/' then
            basepath = basepath .. '/'
        end
        return basepath
    end
end

function toboolean(v)
    if type(v) == 'string' then
        v = v:trim():lower()
        if v == '1' or v == 'true' then
            return true
        end
    elseif type(v) == 'number' then
        if v == 1 then
            return true
        end
    elseif type(v) == 'boolean' then
        return v
    end
    return false
end

function fromboolean(boolean)
    if boolean then
        return 'true'
    else
        return 'false'
    end
end

function booleantonumber(boolean)
    if boolean then
        return 1
    else
        return 0
    end
end

function numbertoboolean(number)
    if number ~= 0 then
        return true
    else
        return false
    end
end

function protectedcall(func, ...)
    local status, ret = pcall(func, ...)
    if status then
        return ret
    end

    perror(ret)
    return false
end

function signalcall(param, ...)
    if type(param) == 'function' then
        local status, ret = pcall(param, ...)
        if status then
            return ret
        else
            perror(ret)
        end
    elseif type(param) == 'table' then
        for k, v in pairs(param) do
            local status, ret = pcall(v, ...)
            if status then
                if ret then
                    return true
                end
            else
                perror(ret)
            end
        end
    elseif param ~= nil then
        error('attempt to call a non function value')
    end
    return false
end

function tr(s, ...)
    return string.format(s, ...)
end

function getOppositeAnchor(anchor)
    if anchor == AnchorLeft then
        return AnchorRight
    elseif anchor == AnchorRight then
        return AnchorLeft
    elseif anchor == AnchorTop then
        return AnchorBottom
    elseif anchor == AnchorBottom then
        return AnchorTop
    elseif anchor == AnchorVerticalCenter then
        return AnchorHorizontalCenter
    elseif anchor == AnchorHorizontalCenter then
        return AnchorVerticalCenter
    end
    return anchor
end

function makesingleton(obj)
    local singleton = {}
    if obj.getClassName then
        for key, value in pairs(_G[obj:getClassName()]) do
            if type(value) == 'function' then
                singleton[key] = function(...)
                    return value(obj, ...)
                end
            end
        end
    end
    return singleton
end

-- TFS compliant Lua debugging:
-- https://github.com/otland/forgottenserver/blob/b23850046a2aec05636761c49d296c755865288a/data/lib/debugging/dump.lua

-- recursive dump function
function dumpLevel(input, level)
    local indent = ''

    for i = 1, level do
        indent = indent .. '    '
    end

    if type(input) == 'table' then
        local str = '{ \n'
        local lines = {}

        for k, v in pairs(input) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end

            if type(v) == 'string' then
                v = '"' .. v .. '"'
            end

            table.insert(lines, indent .. '    [' .. k .. '] = ' .. dumpLevel(v, level + 1))
        end
        return str .. table.concat(lines, ',\n') .. '\n' .. indent .. '}'
    end

    return tostring(input)
end

-- Return a string representation of input for debugging purposes
function dump(input)
    return dumpLevel(input, 0)
end

-- Call the dump function and print it to console
function pdump(input)
    local dump_str = dump(input)
    print(dump_str)
    return dump_str
end

-- Call the dump function with a title and print it beautifully to the console
function tdump(title, input)
    local title_fill = ''
    for i = 1, title:len() do
        title_fill = title_fill .. '='
    end

    local header_str = '\n====' .. title_fill .. '====\n'
    header_str = header_str .. '=== ' .. title .. ' ===\n'
    header_str = header_str .. '====' .. title_fill .. '====\n'

    local dump_str = dump(input)
    local footer_str = '\n====' .. title_fill .. '====\n'

    print(header_str .. dump_str .. footer_str)

    return dump_str
end

-- @}

io.content = function(path)
    return g_resources.readFileContents('/' .. path)
end

function format_number(n)
    local formatted = tostring(n)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then
            break
        end
    end
    return formatted
end


-- @docfuncs @{

function print(...)
  local msg = ""
  local args = {...}
  local appendSpace = #args > 1
  for i,v in ipairs(args) do
    msg = msg .. tostring(v)
    if appendSpace and i < #args then
      msg = msg .. '    '
    end
  end
  g_logger.log(LogInfo, msg)
end

function pinfo(msg)
  g_logger.log(LogInfo, msg)
end

function perror(msg)
  g_logger.log(LogError, msg)
end

function pwarning(msg)
  g_logger.log(LogWarning, msg)
end

pwarn = pwarning

function pdebug(msg)
  g_logger.log(LogDebug, msg)
end

function fatal(msg)
  g_logger.log(LogFatal, msg)
end

function exit()
  g_app.exit()
end

function quit()
  g_app.exit()
end

function connect(object, arg1, arg2, arg3)
  local signalsAndSlots
  local pushFront
  if type(arg1) == 'string' then
    signalsAndSlots = { [arg1] = arg2 }
    pushFront = arg3
  else
    signalsAndSlots = arg1
    pushFront = arg2
  end

  if not signalsAndSlots then
    signalsAndSlots = {}
  end

  for signal,slot in pairs(signalsAndSlots) do
    if not object[signal] then
      local mt = getmetatable(object)
      if mt and type(object) == 'userdata' then
        object[signal] = function(...)
          return signalcall(mt[signal], ...)
        end
      end
    end

    if not object[signal] then
      object[signal] = slot
    elseif type(object[signal]) == 'function' then
      object[signal] = { object[signal] }
    end

    if type(slot) ~= 'function' then
      perror(debug.traceback('unable to connect a non function value'))
    end

    if type(object[signal]) == 'table' then
      if pushFront then
        table.insert(object[signal], 1, slot)
      else
        table.insert(object[signal], #object[signal]+1, slot)
      end
    end
  end
end

function disconnect(object, arg1, arg2)
  if arg1 == nil then return true end
  local signalsAndSlots
  if type(arg1) == 'string' then
    if arg2 == nil then
      object[arg1] = nil
      return
    end
    signalsAndSlots = { [arg1] = arg2 }
  elseif type(arg1) == 'table' then
    signalsAndSlots = arg1
  else
	perror(debug.traceback('unable to disconnect'))
  end

  for signal,slot in pairs(signalsAndSlots) do
    if not object[signal] then
    elseif type(object[signal]) == 'function' then
      if object[signal] == slot then
        object[signal] = nil
      end
    elseif type(object[signal]) == 'table' then
      for k,func in pairs(object[signal]) do
        if func == slot then
          table.remove(object[signal], k)

          if #object[signal] == 1 then
            object[signal] = object[signal][1]
          end
          break
        end
      end
    end
  end
end

function newclass(name)
  if not name then
    perror(debug.traceback('new class has no name.'))
  end

  local class = {}
  function class.internalCreate()
    local instance = {}
    for k,v in pairs(class) do
      instance[k] = v
    end
    return instance
  end
  class.create = class.internalCreate
  class.__class = name
  class.getClassName = function() return name end
  return class
end

function extends(base, name)
  if not name then
    perror(debug.traceback('extended class has no name.'))
  end

  local derived = {}
  function derived.internalCreate()
    local instance = base.create()
    for k,v in pairs(derived) do
      instance[k] = v
    end
    return instance
  end
  derived.create = derived.internalCreate
  derived.__class = name
  derived.getClassName = function() return name end
  return derived
end

function runinsandbox(func, ...)
  if type(func) == 'string' then
    func, err = loadfile(resolvepath(func, 2))
    if not func then
      error(err)
    end
  end
  local env = { }
  local oldenv = getfenv(0)
  setmetatable(env, { __index = oldenv } )
  setfenv(0, env)
  func(...)
  setfenv(0, oldenv)
  return env
end

local function module_loader(modname)
  local module = g_modules.getModule(modname)
  if not module then
    return '\n\tno module \'' .. modname .. '\''
  end
  return function()
    if not module:load() then
      error('unable to load required module ' .. modname)
    end
    return module:getSandbox()
  end
end
table.insert(package.loaders, 1, module_loader)

function import(table)
  assert(type(table) == 'table')
  local env = getfenv(2)
  for k,v in pairs(table) do
    env[k] = v
  end
end

function export(what, key)
  if key ~= nil then
    _G[key] = what
  else
    for k,v in pairs(what) do
      _G[k] = v
    end
  end
end

function unexport(key)
  if type(key) == 'table' then
    for _k,v in pairs(key) do
      _G[v] = nil
    end
  else
    _G[key] = nil
  end
end

function getfsrcpath(depth)
  depth = depth or 2
  local info = debug.getinfo(1+depth, "Sn")
  local path
  if info.short_src then
    path = info.short_src:match("(.*)/.*")
  end
  if not path then
    path = '/'
  elseif path:sub(0, 1) ~= '/' then
    path = '/' .. path
  end
  return path
end

function resolvepath(filePath, depth)
  if not filePath then return nil end
  depth = depth or 1
  if filePath then
    if filePath:sub(0, 1) ~= '/' then
      local basepath = getfsrcpath(depth+1)
      if basepath:sub(#basepath) ~= '/' then basepath = basepath .. '/' end
      return  basepath .. filePath
    else
      return filePath
    end
  else
    local basepath = getfsrcpath(depth+1)
    if basepath:sub(#basepath) ~= '/' then basepath = basepath .. '/' end
    return basepath
  end
end

function toboolean(v)
  if type(v) == 'string' then
    v = v:trim():lower()
    if v == '1' or v == 'true' then
      return true
    end
  elseif type(v) == 'number' then
    if v == 1 then
      return true
    end
  elseif type(v) == 'boolean' then
    return v
  end
  return false
end

function fromboolean(boolean)
  if boolean then
    return 'true'
  else
    return 'false'
  end
end

function booleantonumber(boolean)
  if boolean then
    return 1
  else
    return 0
  end
end

function numbertoboolean(number)
  if number ~= 0 then
    return true
  else
    return false
  end
end

function protectedcall(func, ...)
  local status, ret = pcall(func, ...)
  if status then
    return ret
  end

  local desc = "lua"
  local info = debug.getinfo(2, "Sl")
  if info then
    desc = info.short_src .. ":" .. info.currentline
  end

  g_logger.error(debug.traceback("(protectedcall Lua Error): ") .. "\n" .. ret .. "\nOrigin: " .. desc)
  return false
end

function signalcall(param, ...)
  local desc = "lua"
  local info = debug.getinfo(2, "Sl")
  if info then
    desc = info.short_src .. ":" .. info.currentline
  end

  if type(param) == 'function' then
    local status, ret = pcall(param, ...)
    if status then
      return ret
    else
      g_logger.error(debug.traceback("(function signalcall Lua Error): ") .. "\n" .. ret .. "\nOrigin: " .. desc)
    end
  elseif type(param) == 'table' then
    for k,v in pairs(param) do
      local status, ret = pcall(v, ...)
      if status then
        if ret then return true end
      else
        g_logger.error(debug.traceback("(table signalcall Lua Error): ") .. "\n" .. ret .. "\nOrigin: " .. desc)
      end
    end
  elseif param ~= nil then
    error('attempt to call a non function value')
  end
  return false
end

function tr(s, ...)
  return string.format(s, ...)
end

function getOppositeAnchor(anchor)
  if anchor == AnchorLeft then
    return AnchorRight
  elseif anchor == AnchorRight then
    return AnchorLeft
  elseif anchor == AnchorTop then
    return AnchorBottom
  elseif anchor == AnchorBottom then
    return AnchorTop
  elseif anchor == AnchorVerticalCenter then
    return AnchorHorizontalCenter
  elseif anchor == AnchorHorizontalCenter then
    return AnchorVerticalCenter
  end
  return anchor
end

function makesingleton(obj)
  local singleton = {}
  if obj.getClassName then
    for key,value in pairs(_G[obj:getClassName()]) do
      if type(value) == 'function' then
        singleton[key] = function(...) return value(obj, ...) end
      end
    end
  end
  return singleton
end

function comma_value(amount)
  local formatted = amount
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if (k==0) then
      break
    end
  end
  return formatted
end

function countTableElements(t)
  local count = 0
  for _ in pairs(t) do
      count = count + 1
  end
  return count
end

-- Converte dicion�rio para array de valores
function getValues(t)
  if type(t) ~= "table" then return {} end  -- Evita erro caso t seja nil
  local values = {}
  for _, v in pairs(t) do
      table.insert(values, v)
  end
  return values
end

function convertGold(amount, shortValue)
  local formatType = 0
  if shortValue and amount > 9999999999 then
	  formatType = 1
    amount = math.floor(amount / 1000)
  end

  local formatted = amount
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if (k==0) then
      break
    end
  end

  if formatType == 1 then
    formatted = formatted .. " k"
  end

  return formatted
end

function convertLongGold(amount, shortValue, normalized)
  local hasBillion = false
  local hasTrillion = false

  local fomarType = 0
  if normalized and amount >= 1000000 then
    amount = math.floor(amount / 1000000)
    fomarType = 1
  elseif normalized and amount >= 10000 then
    amount = math.floor(amount / 1000)
    fomarType = 2
  elseif shortValue and amount > 10000000 then
	  fomarType = 1
    amount = math.floor(amount / 1000000)
  elseif shortValue and amount > 1000000 then
	  fomarType = 2
    amount = math.floor(amount / 1000)
  elseif amount > 999999999 then
    fomarType = 1
    amount = math.floor(amount / 1000000)
  elseif amount > 99999999 then
    fomarType = 2
    amount = math.floor(amount / 1000)
  end

  local formatted = amount
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if (k==0) then
      break
    end
  end

  if fomarType == 1 then
    formatted = formatted .. " kk"
  elseif fomarType == 2 then
    formatted = formatted .. " k"
  end

  return formatted
end

function getTotalMoney()
	return g_game.getLocalPlayer():getResourceValue(ResourceBank) + g_game.getLocalPlayer():getResourceValue(ResourceInventary)
end

function openPlataform(self)
  local selfId = self:getId()
  if selfId == 'clickSitePassword' then
    g_platform.openUrl(Services.recoveryPassword)
  elseif selfId == 'clickSiteCreateAccount' then
    g_platform.openUrl(Services.createAccount)
  elseif selfId == 'logo' then
    g_platform.openUrl(Services.website)
  elseif selfId == 'getCoins' then
    g_platform.openUrl(Services.Coins)
  end
end

function numberToStr(value)
  if value < 1000 then
      return tostring(value)
  end

  local formatted = string.format("%.1f", value / 1000)
  return formatted:gsub("%.?0+$", "") .. "k"
end

function aggresiveNumberToStr(value)
  if value < 10000 then
      return tostring(value)
  elseif value < 100000 then
      local formatted = string.format("%.0f", value / 1000)
      return formatted .. "k"
  elseif value < 1000000 then
      local formatted = string.format("%.0f", value / 1000)
      return formatted .. "k"
  else
    local millions = value / 1000000
      local truncated = math.floor(millions * 10) / 10
      local formatted = string.format("%.1f", truncated)
      if formatted:sub(-2) == ".0" then
          return formatted:sub(1, -3) .. "kk"
      else
          return formatted .. "kk"
      end
  end
end

-- Global typing animation system
TypingAnimation = {
    instances = {}
}

function TypingAnimation:create(id)
    if self.instances[id] then
        self:destroy(id)
    end
    
    self.instances[id] = {
        event = nil,
        targetLabel = nil,
        fullText = "",
        currentIndex = 0,
        speed = 50,
        parsedText = {}
    }
    
    return self.instances[id]
end

function TypingAnimation:destroy(id)
    local instance = self.instances[id]
    if not instance then return end
    
    if instance.event then
        removeEvent(instance.event)
    end
    
    self.instances[id] = nil
end

function TypingAnimation:start(id, label, text, speed)
    local instance = self:create(id)
    
    instance.targetLabel = label
    instance.fullText = text
    instance.currentIndex = 0
    instance.speed = speed or 50
    instance.parsedText = self:parseColorText(text)
    
    label:setText("")
    
    instance.event = cycleEvent(function()
        self:processAnimation(id)
    end, instance.speed)
end

function TypingAnimation:stop(id)
    self:destroy(id)
end

function TypingAnimation:hasEvent(id)
    return self.instances[id]
end

function TypingAnimation:parseColorText(text)
    local parsed = {}
    local i = 1
    local currentColor = nil
    local colorStack = {}
    
    while i <= string.len(text) do
        local colorStart = string.find(text, "%[color=#[%w]+%]", i)
        if colorStart == i then
            local colorEnd = string.find(text, "%]", colorStart)
            local colorTag = string.sub(text, colorStart, colorEnd)
            currentColor = string.match(colorTag, "#[%w]+")
            table.insert(colorStack, currentColor)
            i = colorEnd + 1
        elseif string.sub(text, i, i + 7) == "[/color]" then
            table.remove(colorStack)
            currentColor = colorStack[#colorStack]
            i = i + 8
        else
            local char = string.sub(text, i, i)
            table.insert(parsed, {
                char = char,
                color = currentColor
            })
            i = i + 1
        end
    end
    
    return parsed
end

function TypingAnimation:buildColoredText(parsedText, maxIndex)
    local result = ""
    local currentColor = nil
    local colorOpen = false
    
    for i = 1, math.min(maxIndex, #parsedText) do
        local charData = parsedText[i]
        if charData.color ~= currentColor then
            if colorOpen then
                result = result .. "[/color]"
                colorOpen = false
            end
            if charData.color then
                result = result .. "[color=" .. charData.color .. "]"
                colorOpen = true
                currentColor = charData.color
            else
                currentColor = nil
            end
        end
        result = result .. charData.char
    end

    if colorOpen then
        result = result .. "[/color]"
    end
    
    return result
end

function TypingAnimation:processAnimation(id)
    local instance = self.instances[id]
    if not instance or not instance.targetLabel or instance.currentIndex >= #instance.parsedText then
        self:destroy(id)
        return
    end
    
    instance.currentIndex = instance.currentIndex + 1
    local currentText = self:buildColoredText(instance.parsedText, instance.currentIndex)

    if instance.targetLabel.setColorText then
        instance.targetLabel:setColorText(currentText)
    else
        instance.targetLabel:setText(currentText)
    end
end

-- @}